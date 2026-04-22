import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _todayQuiz;
  bool _loading = true;

  final List<Color> _gradientColors = [
    const Color(0xFFFBBF24),
    const Color(0xFFF97316),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile   = await AuthService.getProfile();
    final todayQuiz = await AuthService.getTodayQuiz();
    if (mounted) setState(() { _profile = profile; _todayQuiz = todayQuiz; _loading = false; });
  }

  String get _displayName =>
      _profile?['display_name'] ?? AuthService.currentUser?.email ?? 'Người dùng';

  String get _email => AuthService.currentUser?.email ?? '';

  String get _avatarLetter =>
      _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!AuthService.isLoggedIn) {
      return _buildNotLoggedIn(context);
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _gradientColors[0]))
          : CustomScrollView(
        slivers: [
          _buildHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildQuizCard(colorScheme),
                  const SizedBox(height: 16),
                  _buildInfoCard(colorScheme),
                  const SizedBox(height: 16),
                  _buildActionsCard(context, colorScheme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header với avatar ─────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(top: 60, bottom: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Avatar
            GestureDetector(
              onTap: () => _showEditProfile(context),
              child: Stack(
                children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.25),
                      border: Border.all(color: Colors.white.withOpacity(0.6), width: 3),
                    ),
                    child: _profile?['avatar_url'] != null
                        ? ClipOval(
                      child: Image.network(
                        _profile!['avatar_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarLetter(),
                      ),
                    )
                        : _buildAvatarLetter(),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit_rounded, size: 13, color: _gradientColors[1]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _displayName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              _email,
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarLetter() {
    return Center(
      child: Text(
        _avatarLetter,
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }

  // ── Quiz hôm nay ──────────────────────────────────────────
  Widget _buildQuizCard(ColorScheme cs) {
    final score    = _todayQuiz?['score']   ?? 0;
    final total    = _todayQuiz?['total']   ?? 0;
    final done     = _todayQuiz?['completed'] ?? false;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradientColors[0].withOpacity(0.12), _gradientColors[1].withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gradientColors[0].withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _gradientColors),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('🧠', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quiz hôm nay', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(height: 3),
                Text(
                  done
                      ? 'Hoàn thành · $score/$total câu đúng 🎉'
                      : total > 0
                      ? 'Đang làm · $score/$total câu'
                      : 'Chưa bắt đầu',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (done)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF22c55e).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$score/$total',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF22c55e)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Thông tin tài khoản ───────────────────────────────────
  Widget _buildInfoCard(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.person_outline_rounded, 'Tên hiển thị', _displayName, cs),
          Divider(height: 1, color: cs.outlineVariant),
          _buildInfoRow(Icons.email_outlined, 'Email', _email, cs),
          if (_profile?['bio'] != null && _profile!['bio'].toString().isNotEmpty) ...[
            Divider(height: 1, color: cs.outlineVariant),
            _buildInfoRow(Icons.notes_rounded, 'Bio', _profile!['bio'], cs),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
          const Spacer(),
          Flexible(
            child: Text(value, style: TextStyle(fontSize: 14, color: cs.onSurface, fontWeight: FontWeight.w600), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────
  Widget _buildActionsCard(BuildContext context, ColorScheme cs) {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.edit_rounded,
          label: 'Chỉnh sửa thông tin',
          color: _gradientColors[0],
          cs: cs,
          onTap: () => _showEditProfile(context),
        ),
        const SizedBox(height: 10),
        _buildActionTile(
          icon: Icons.logout_rounded,
          label: 'Đăng xuất',
          color: cs.error,
          cs: cs,
          onTap: () => _confirmLogout(context),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required ColorScheme cs,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  // ── Màn hình chưa đăng nhập ───────────────────────────────
  Widget _buildNotLoggedIn(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔐', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('Chưa đăng nhập', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface)),
              const SizedBox(height: 8),
              Text('Đăng nhập để lưu tiến độ quiz và gửi báo cáo thông tin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant, height: 1.6),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: _gradientColors),
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [BoxShadow(color: _gradientColors[0].withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 8))],
                  ),
                  child: const Text('Đăng nhập ngay', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────
  void _showEditProfile(BuildContext context) {
    final nameCtrl = TextEditingController(text: _displayName);
    final bioCtrl  = TextEditingController(text: _profile?['bio'] ?? '');
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(color: cs.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Chỉnh sửa thông tin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface)),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Tên hiển thị',
                  filled: true, fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Bio (tùy chọn)',
                  filled: true, fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  await AuthService.updateProfile(
                    displayName: nameCtrl.text.trim(),
                    bio: bioCtrl.text.trim(),
                  );
                  if (context.mounted) Navigator.pop(context);
                  _load();
                },
                child: Container(
                  width: double.infinity, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: _gradientColors),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(child: Text('Lưu', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cs.surface,
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          TextButton(
            onPressed: () async {
              await AuthService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                      (_) => false,
                );
              }
            },
            child: Text('Đăng xuất', style: TextStyle(color: cs.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}