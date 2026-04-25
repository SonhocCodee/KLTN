import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  // User data
  String? _avatarUrl;
  String _displayName = '';
  bool _isLoadingProfile = true;
  bool _isSavingName = false;
  bool _isUploadingAvatar = false;

  // Stats
  int _streakDays = 0;
  int _totalFacts = 0;
  int _totalSpecies = 0;
  DateTime? _lastPlayed;

  // Reports — gộp 3 bảng
  List<Map<String, dynamic>> _allReports = [];
  bool _isLoadingReports = true;

  // Phân loại nguồn
  static const _srcQuiz = 'quiz';
  static const _srcAnimal = 'animal';
  static const _srcFeedback = 'feedback';

  final _nameController = TextEditingController();
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfile();
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Load user_profiles (primary key là 'id' = user_id)
      final profileRes = await _supabase
          .from('user_profiles')
          .select('display_name, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      // Load user_stats
      final statsRes = await _supabase
          .from('user_stats')
          .select('streak_days, total_facts, total_species, last_played')
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _displayName = profileRes?['display_name'] ?? 'Người dùng';
          _avatarUrl = profileRes?['avatar_url'];
          _nameController.text = _displayName;

          if (statsRes != null) {
            _streakDays = statsRes['streak_days'] ?? 0;
            _totalFacts = statsRes['total_facts'] ?? 0;
            _totalSpecies = statsRes['total_species'] ?? 0;
            final lp = statsRes['last_played'];
            _lastPlayed = lp != null ? DateTime.tryParse(lp) : null;
          }
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
        _showSnack('Lỗi tải hồ sơ: $e');
      }
    }
  }

  Future<void> _loadReports() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Fetch song song 3 bảng
      final results = await Future.wait([
        _supabase
            .from('quiz_reports')
            .select('id, report_type, note, status, admin_note, created_at')
            .eq('user_id', userId)
            .order('created_at', ascending: false),
        _supabase
            .from('animal_reports')
            .select('id, note, status, admin_note, created_at, suggested_name_vietnamese')
            .eq('reporter_user_id', userId)
            .order('created_at', ascending: false),
        _supabase
            .from('app_feedbacks')
            .select('id, type, description, status, admin_note, created_at')
            .eq('user_id', userId)
            .order('created_at', ascending: false),
      ]);

      final quizReports = (results[0] as List).map((r) => {
        ...Map<String, dynamic>.from(r),
        '_source': _srcQuiz,
        '_title': _reportTypeLabel(r['report_type'] ?? ''),
        '_subtitle': r['note'] ?? '',
      }).toList();

      final animalReports = (results[1] as List).map((r) => {
        ...Map<String, dynamic>.from(r),
        '_source': _srcAnimal,
        '_title': 'Báo cáo loài: ${r['suggested_name_vietnamese'] ?? ''}',
        '_subtitle': r['note'] ?? '',
      }).toList();

      final feedbackReports = (results[2] as List).map((r) => {
        ...Map<String, dynamic>.from(r),
        '_source': _srcFeedback,
        'report_type': r['type'] ?? '',
        '_title': _feedbackTypeLabel(r['type'] ?? ''),
        '_subtitle': r['description'] ?? '',
      }).toList();

      // Gộp và sort theo created_at mới nhất
      final all = [
        ...quizReports,
        ...animalReports,
        ...feedbackReports,
      ]..sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
        final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _allReports = all;
          _isLoadingReports = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReports = false);
        _showSnack('Lỗi tải báo cáo: $e');
      }
    }
  }

  String _feedbackTypeLabel(String type) {
    switch (type) {
      case 'bug':
        return 'Báo lỗi ứng dụng';
      case 'feature':
        return 'Đề xuất tính năng';
      case 'content':
        return 'Góp ý nội dung';
      default:
        return type.isNotEmpty ? type : 'Phản hồi';
    }
  }

  Future<void> _saveDisplayName() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == _displayName) {
      setState(() => _isEditingName = false);
      return;
    }

    setState(() => _isSavingName = true);
    try {
      await _supabase.from('user_profiles').upsert({
        'id': userId,
        'display_name': newName,
        'updated_at': DateTime.now().toIso8601String(),
      });
      setState(() {
        _displayName = newName;
        _isEditingName = false;
      });
      _showSnack('Đã cập nhật tên hiển thị!');
    } catch (e) {
      _showSnack('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final file = File(picked.path);
      final ext = picked.path.split('.').last;
      final filePath = 'avatars/$userId.$ext';

      await _supabase.storage.from('user-avatars').upload(
        filePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl =
      _supabase.storage.from('user-avatars').getPublicUrl(filePath);

      // Thêm cache-buster để force reload ảnh mới
      final urlWithCache = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      await _supabase.from('user_profiles').upsert({
        'id': userId,
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      setState(() => _avatarUrl = urlWithCache);
      _showSnack('Đã cập nhật ảnh đại diện!');
    } catch (e) {
      _showSnack('Lỗi tải ảnh: $e');
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  List<Map<String, dynamic>> get _pendingReports =>
      _allReports.where((r) => r['status'] == 'pending').toList();
  List<Map<String, dynamic>> get _approvedReports =>
      _allReports.where((r) => r['status'] == 'approved').toList();
  List<Map<String, dynamic>> get _rejectedReports =>
      _allReports.where((r) => r['status'] == 'rejected').toList();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          _buildSliverAppBar(colorScheme),
          SliverToBoxAdapter(
            child: _buildStatsSection(colorScheme),
          ),
          SliverToBoxAdapter(
            child: _buildFavoritesPlaceholder(colorScheme),
          ),
          SliverToBoxAdapter(
            child: _buildReportsSection(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primaryContainer,
                colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Avatar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: _pickAndUploadAvatar,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary,
                            width: 3,
                          ),
                          color: colorScheme.surfaceContainerHighest,
                        ),
                        child: ClipOval(
                          child: _isUploadingAvatar
                              ? const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                              : _avatarUrl != null
                              ? Image.network(
                            _avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _defaultAvatar(colorScheme),
                          )
                              : _defaultAvatar(colorScheme),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: colorScheme.surface, width: 2),
                      ),
                      child: Icon(Icons.camera_alt,
                          size: 14, color: colorScheme.onPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Tên hiển thị
                _isEditingName
                    ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isSavingName
                          ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))
                          : IconButton(
                        onPressed: _saveDisplayName,
                        icon: Icon(Icons.check,
                            color: colorScheme.primary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        onPressed: () => setState(() {
                          _isEditingName = false;
                          _nameController.text = _displayName;
                        }),
                        icon: Icon(Icons.close,
                            color: colorScheme.error),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                )
                    : GestureDetector(
                  onTap: () =>
                      setState(() => _isEditingName = true),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _displayName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit,
                          size: 16,
                          color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _supabase.auth.currentUser?.email ?? '',
                  style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(ColorScheme colorScheme) {
    final initials = _displayName.isNotEmpty
        ? _displayName[0].toUpperCase()
        : '?';
    return Container(
      color: colorScheme.primaryContainer,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer),
        ),
      ),
    );
  }

  Widget _buildStatsSection(ColorScheme colorScheme) {
    final lastPlayedStr = _lastPlayed != null
        ? DateFormat('dd/MM/yyyy').format(_lastPlayed!)
        : '—';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 8),
            child: Text('Thống kê',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface)),
          ),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.local_fire_department,
                  iconColor: Colors.orange,
                  label: 'Chuỗi ngày',
                  value: '$_streakDays ngày',
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  icon: Icons.lightbulb_outline,
                  iconColor: Colors.amber,
                  label: 'Fact khám phá',
                  value: '$_totalFacts',
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.pets,
                  iconColor: colorScheme.primary,
                  label: 'Loài đã biết',
                  value: '$_totalSpecies',
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  icon: Icons.calendar_today_outlined,
                  iconColor: Colors.teal,
                  label: 'Chơi gần nhất',
                  value: lastPlayedStr,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: colorScheme.onSurface)),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesPlaceholder(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Loài yêu thích',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: colorScheme.outlineVariant, width: 1),
            ),
            child: Column(
              children: [
                Icon(Icons.favorite_border,
                    size: 36, color: colorScheme.outlineVariant),
                const SizedBox(height: 8),
                Text(
                  'Tính năng đang phát triển',
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsSection(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Báo cáo của tôi',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 10),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            dividerColor: colorScheme.outlineVariant,
            tabs: [
              Tab(text: 'Tất cả (${_allReports.length})'),
              Tab(text: 'Chờ duyệt (${_pendingReports.length})'),
              Tab(text: 'Đã duyệt (${_approvedReports.length})'),
              Tab(text: 'Từ chối (${_rejectedReports.length})'),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: _isLoadingReports
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                _buildReportList(_allReports, colorScheme),
                _buildReportList(_pendingReports, colorScheme),
                _buildReportList(_approvedReports, colorScheme),
                _buildReportList(_rejectedReports, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList(
      List<Map<String, dynamic>> reports, ColorScheme colorScheme) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 40, color: colorScheme.outlineVariant),
            const SizedBox(height: 8),
            Text('Không có báo cáo nào',
                style: TextStyle(
                    color: colorScheme.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final r = reports[index];
        return _reportCard(r, colorScheme);
      },
    );
  }

  Widget _reportCard(Map<String, dynamic> r, ColorScheme colorScheme) {
    final status = r['status'] as String? ?? 'pending';
    final title = r['_title'] as String? ?? '';
    final subtitle = r['_subtitle'] as String? ?? '';
    final source = r['_source'] as String? ?? '';
    final adminNote = r['admin_note'] as String? ?? '';
    final createdAt = r['created_at'] != null
        ? DateFormat('dd/MM/yyyy HH:mm')
        .format(DateTime.parse(r['created_at']))
        : '';

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        statusLabel = 'Đã duyệt';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        statusLabel = 'Từ chối';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusLabel = 'Chờ duyệt';
    }

    // Badge nguồn
    String sourceLabel;
    Color sourceColor;
    IconData sourceIcon;
    switch (source) {
      case _srcAnimal:
        sourceLabel = 'Loài';
        sourceColor = Colors.teal;
        sourceIcon = Icons.pets;
        break;
      case _srcFeedback:
        sourceLabel = 'App';
        sourceColor = Colors.purple;
        sourceIcon = Icons.feedback_outlined;
        break;
      default:
        sourceLabel = 'Quiz';
        sourceColor = Colors.blue;
        sourceIcon = Icons.quiz_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: status == 'rejected'
            ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(statusIcon, color: statusColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Badge nguồn
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: sourceColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(sourceIcon, size: 11, color: sourceColor),
                          const SizedBox(width: 3),
                          Text(sourceLabel,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: sourceColor,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Badge trạng thái
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                // Ghi chú của user
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],
                // Lý do từ chối từ admin
                if (status == 'rejected' && adminNote.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.red.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: Colors.red.shade400),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lý do từ chối',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.red.shade400)),
                              const SizedBox(height: 2),
                              Text(adminNote,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurface)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(createdAt,
                    style: TextStyle(
                        fontSize: 12, color: colorScheme.outlineVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _reportTypeLabel(String type) {
    switch (type) {
      case 'wrong_answer':
        return 'Đáp án sai';
      case 'wrong_question':
        return 'Câu hỏi sai';
      case 'wrong_image':
        return 'Ảnh không đúng';
      case 'duplicate':
        return 'Trùng lặp';
      default:
        return type.isNotEmpty ? type : 'Báo cáo khác';
    }
  }
}