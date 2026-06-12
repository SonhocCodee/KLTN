import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_env.dart';
import '../Animal_detail/Animal detail screen.dart';
import '../home/animal_category_model.dart';

class AnimalAiChatScreen extends StatefulWidget {
  const AnimalAiChatScreen({super.key});

  @override
  State<AnimalAiChatScreen> createState() => _AnimalAiChatScreenState();
}

class _AnimalAiChatScreenState extends State<AnimalAiChatScreen> {
  late final GroqAnimalChatService _chatService;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();

  List<AnimalChatSession> _sessions = [];
  String? _currentSessionId;
  bool _isLoadingSessions = true;
  bool _isSending = false;
  bool _isOnline = false;
  bool _isSyncing = false;
  File? _pendingImage;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _networkWatchTimer;

  AnimalChatSession? get _currentSession {
    for (final s in _sessions) {
      if (s.id == _currentSessionId) return s;
    }
    return _sessions.isEmpty ? null : _sessions.first;
  }

  List<AnimalChatMessage> get _messages =>
      _currentSession?.messages ?? const [];

  @override
  void initState() {
    super.initState();
    _chatService = GroqAnimalChatService();
    _initConnectivity();
    _loadSessions();
  }

  @override
  void dispose() {
    _networkWatchTimer?.cancel();
    _connectivitySub?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Connectivity

  Future<void> _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      await _handleConnectivity(results);
    } catch (_) {
      if (mounted) setState(() => _isOnline = false);
    }

    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (results) => unawaited(_handleConnectivity(results)),
    );

    _networkWatchTimer?.cancel();
    _networkWatchTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_refreshOnlineStatus());
    });
  }

  bool _hasNetworkInterface(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );
  }

  Future<bool> _refreshOnlineStatus({bool syncWhenBack = true}) async {
    bool online = false;
    try {
      final results = await Connectivity().checkConnectivity();
      final hasNetworkInterface = _hasNetworkInterface(results);
      online =
          hasNetworkInterface &&
          await NetworkHealth.hasInternet(timeout: const Duration(seconds: 2));
    } catch (_) {
      online = false;
    }

    if (!mounted) return online;
    final wasOnline = _isOnline;
    if (online != wasOnline) {
      setState(() => _isOnline = online);
      if (online && syncWhenBack) _triggerSync();
    }
    return online;
  }

  Future<void> _handleConnectivity(List<ConnectivityResult> results) async {
    final hasNetworkInterface = _hasNetworkInterface(results);
    final online =
        hasNetworkInterface &&
        await NetworkHealth.hasInternet(timeout: const Duration(seconds: 2));

    if (!mounted) return;
    final wasOnline = _isOnline;
    if (online != wasOnline) {
      setState(() => _isOnline = online);
    }

    if (online && !wasOnline) _triggerSync();
  }

  Future<void> _triggerSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final online = await NetworkHealth.hasInternet(
        timeout: const Duration(seconds: 2),
      );
      if (!online) {
        if (mounted) setState(() => _isOnline = false);
        return;
      }
      await AnimalLocalCache.instance.syncIfNeeded();
    } catch (_) {
      // Sync fail thì vẫn dùng cache cũ, không crash app.
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // Sessions

  Future<void> _loadSessions() async {
    // Khởi tạo cache song song với load sessions
    unawaited(
      AnimalLocalCache.instance.init().then((_) {
        if (_isOnline) _triggerSync();
      }),
    );

    final sessions = await AnimalChatStorage.loadSessions();
    if (!mounted) return;

    if (sessions.isEmpty) {
      final session = AnimalChatSession.createWelcome();
      setState(() {
        _sessions = [session];
        _currentSessionId = session.id;
        _isLoadingSessions = false;
      });
      await AnimalChatStorage.saveSessions(_sessions);
    } else {
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      setState(() {
        _sessions = sessions;
        _currentSessionId = sessions.first.id;
        _isLoadingSessions = false;
      });
    }
    _scrollToBottom(jump: true);
  }

  Future<void> _persist() async => AnimalChatStorage.saveSessions(_sessions);

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final target = _scrollCtrl.position.maxScrollExtent + 260;
      if (jump) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      } else {
        _scrollCtrl.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _updateCurrentSession(
    AnimalChatSession Function(AnimalChatSession s) updater,
  ) {
    final id = _currentSessionId;
    if (id == null) return;
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx < 0) return;
    _sessions[idx] = updater(_sessions[idx]);
    _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> _newChat() async {
    final session = AnimalChatSession.createWelcome();
    setState(() {
      _sessions.insert(0, session);
      _currentSessionId = session.id;
      _pendingImage = null;
      _inputCtrl.clear();
    });
    await _persist();
    _scrollToBottom(jump: true);
  }

  Future<void> _deleteCurrentChat() async {
    final current = _currentSession;
    if (current == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá đoạn chat?'),
        content: Text('Bạn muốn xoá "${current.title}" khỏi lịch sử chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _sessions.removeWhere((s) => s.id == current.id);
      if (_sessions.isEmpty) {
        final s = AnimalChatSession.createWelcome();
        _sessions.add(s);
        _currentSessionId = s.id;
      } else {
        _currentSessionId = _sessions.first.id;
      }
      _pendingImage = null;
      _inputCtrl.clear();
    });
    await _persist();
  }

  Future<void> _clearAllChats() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá toàn bộ lịch sử?'),
        content: const Text('Tất cả đoạn chat đã lưu sẽ bị xoá khỏi máy.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá hết'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final s = AnimalChatSession.createWelcome();
    setState(() {
      _sessions = [s];
      _currentSessionId = s.id;
      _pendingImage = null;
      _inputCtrl.clear();
    });
    await AnimalChatStorage.clear();
    await _persist();
  }

  Future<void> _pickImage(ImageSource source) async {
    final x = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (x == null) return;
    setState(() => _pendingImage = File(x.path));
  }

  Future<void> _showImagePickerSheet() async {
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: cs.primary),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: cs.primary),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Send

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    final session = _currentSession;
    if ((text.isEmpty && _pendingImage == null) ||
        _isSending ||
        session == null)
      return;

    final userText = text.isEmpty
        ? 'Hãy nhận diện và mô tả con vật trong ảnh này.'
        : text;
    final imageFile = _pendingImage;

    // Trước mỗi lần gửi, kiểm tra lại Internet thật sự để tránh bị kẹt
    // ở offline mode sau khi mạng đã quay lại.
    final effectiveOnline = await _refreshOnlineStatus(syncWhenBack: true);
    if (!mounted) return;

    setState(() {
      _inputCtrl.clear();
      _pendingImage = null;
      _isSending = true;
      _updateCurrentSession((s) {
        final messages = [
          ...s.messages,
          AnimalChatMessage.user(userText, imagePath: imageFile?.path),
          AnimalChatMessage.assistant(
            effectiveOnline
                ? 'Đang xử lý...'
                : '🔍 Đang tìm trong dữ liệu offline...',
            isLoading: true,
          ),
        ];
        return s.copyWith(
          title: s.isDefaultTitle ? _makeTitle(userText) : s.title,
          messages: messages,
          updatedAt: DateTime.now(),
        );
      });
    });
    _scrollToBottom();

    try {
      final result = await _chatService.ask(
        question: userText,
        imageFile: imageFile,
        recentMessages: _messages.where((m) => !m.isLoading).toList(),
        isOnline: effectiveOnline,
      );

      if (!mounted) return;
      setState(() {
        _isSending = false;
        _updateCurrentSession((s) {
          final messages = s.messages.where((m) => !m.isLoading).toList()
            ..add(
              AnimalChatMessage.assistant(
                result.text,
                mentionedAnimals: result.animals,
                isOfflineAnswer: result.isOffline,
              ),
            );
          return s.copyWith(messages: messages, updatedAt: DateTime.now());
        });
      });
      await _persist();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _updateCurrentSession((s) {
          final messages = s.messages.where((m) => !m.isLoading).toList()
            ..add(AnimalChatMessage.assistant('Lỗi: $e'));
          return s.copyWith(messages: messages, updatedAt: DateTime.now());
        });
      });
      await _persist();
      _scrollToBottom();
    }
  }

  String _makeTitle(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean.length <= 32 ? clean : '${clean.substring(0, 32)}...';
  }

  void _openSessionsSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => _ChatHistorySheet(
        sessions: _sessions,
        currentSessionId: _currentSessionId,
        onSelect: (id) {
          Navigator.pop(ctx);
          setState(() {
            _currentSessionId = id;
            _pendingImage = null;
            _inputCtrl.clear();
          });
          _scrollToBottom(jump: true);
        },
        onNewChat: () {
          Navigator.pop(ctx);
          _newChat();
        },
        onClearAll: () {
          Navigator.pop(ctx);
          _clearAllChats();
        },
      ),
    );
  }

  void _openAnimalDetail(String animalId, String? animalType) {
    final enabled = AnimalCategory.getEnabledCategories();
    final category = enabled.firstWhere(
      (c) => c.id.toLowerCase() == (animalType ?? '').toLowerCase(),
      orElse: () => enabled.isNotEmpty
          ? enabled.first
          : AnimalCategory.allCategories.first,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AnimalDetailScreen(animalId: animalId, category: category),
      ),
    );
  }

  // Dựng giao diện

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final session = _currentSession;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          tooltip: 'Lịch sử chat',
          onPressed: _isLoadingSessions ? null : _openSessionsSheet,
          icon: const Icon(Icons.forum_rounded),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Flexible(
                  child: Text(
                    'Trợ lý động vật AI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 8),
                // Nhãn online/offline
                _ConnectivityBadge(isOnline: _isOnline, isSyncing: _isSyncing),
              ],
            ),
            Text(
              session?.title ?? 'Đang tải...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Chat mới',
            onPressed: _isLoadingSessions ? null : _newChat,
            icon: const Icon(Icons.add_comment_rounded),
          ),
          IconButton(
            tooltip: 'Xoá chat hiện tại',
            onPressed: _isLoadingSessions ? null : _deleteCurrentChat,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: _isLoadingSessions
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) => AnimalChatBubble(
                            message: _messages[i],
                            onOpenAnimal: (id, type) =>
                                _openAnimalDetail(id, type),
                          ),
                        ),
                ),
                _SuggestedPromptBar(
                  onTap: (text) {
                    _inputCtrl.text = text;
                    _send();
                  },
                ),
                _buildComposer(cs),
              ],
            ),
    );
  }

  Widget _buildComposer(ColorScheme cs) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withOpacity(0.7)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_pendingImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _pendingImage!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isOnline
                              ? 'Ảnh sẽ được gửi kèm câu hỏi.'
                              : '⚠️ Offline: ảnh không được phân tích.',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _pendingImage = null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Thêm ảnh',
                  onPressed: (_isSending || !_isOnline)
                      ? null
                      : _showImagePickerSheet,
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: _isOnline
                          ? 'Hỏi về động vật...'
                          : '🔌 Offline — tìm kiếm local...',
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isSending ? null : _send,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Trạng thái kết nối

class _ConnectivityBadge extends StatelessWidget {
  final bool isOnline;
  final bool isSyncing;
  const _ConnectivityBadge({required this.isOnline, required this.isSyncing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (isOnline && !isSyncing) return const SizedBox.shrink();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 82),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSyncing ? cs.primaryContainer : cs.errorContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSyncing)
              SizedBox(
                width: 9,
                height: 9,
                child: CircularProgressIndicator(
                  strokeWidth: 1.4,
                  color: cs.onPrimaryContainer,
                ),
              )
            else
              Icon(
                Icons.wifi_off_rounded,
                size: 10,
                color: cs.onErrorContainer,
              ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                isSyncing ? 'Sync' : 'Offline',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSyncing
                      ? cs.onPrimaryContainer
                      : cs.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Gợi ý câu hỏi

class _SuggestedPromptBar extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _SuggestedPromptBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = const [
      'Mèo lông dài màu trắng mắt xanh là giống gì?',
      'Hổ ăn gì và sống ở đâu?',
      'Tìm con vật 4 chân ăn cỏ có sừng',
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (_, i) => ActionChip(
          label: Text(items[i], style: const TextStyle(fontSize: 12)),
          backgroundColor: cs.surfaceContainerHighest,
          side: BorderSide(color: cs.outlineVariant),
          onPressed: () => onTap(items[i]),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }
}

// Lịch sử chat

class _ChatHistorySheet extends StatelessWidget {
  final List<AnimalChatSession> sessions;
  final String? currentSessionId;
  final ValueChanged<String> onSelect;
  final VoidCallback onNewChat;
  final VoidCallback onClearAll;

  const _ChatHistorySheet({
    required this.sessions,
    required this.currentSessionId,
    required this.onSelect,
    required this.onNewChat,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.68,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lịch sử chat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClearAll,
                    icon: const Icon(Icons.delete_sweep_rounded),
                  ),
                  FilledButton.icon(
                    onPressed: onNewChat,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Chat mới'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: sessions.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: cs.outlineVariant),
                itemBuilder: (_, i) {
                  final s = sessions[i];
                  final selected = s.id == currentSessionId;
                  final lastText = s.messages.where((m) => !m.isLoading).isEmpty
                      ? 'Chưa có tin nhắn'
                      : s.messages.where((m) => !m.isLoading).last.text;
                  return ListTile(
                    selected: selected,
                    leading: CircleAvatar(
                      backgroundColor: selected
                          ? cs.primary
                          : cs.surfaceContainerHighest,
                      foregroundColor: selected ? cs.onPrimary : cs.primary,
                      child: const Icon(Icons.smart_toy_rounded),
                    ),
                    title: Text(
                      s.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      lastText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _formatTime(s.updatedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    onTap: () => onSelect(s.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final sameDay =
        now.year == dt.year && now.month == dt.month && now.day == dt.day;
    if (sameDay) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}

// Bong bóng chat

class AnimalChatBubble extends StatelessWidget {
  final AnimalChatMessage message;
  final void Function(String animalId, String? animalType)? onOpenAnimal;

  const AnimalChatBubble({super.key, required this.message, this.onOpenAnimal});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = message.role == AnimalChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imagePath != null &&
                File(message.imagePath!).existsSync()) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(message.imagePath!),
                  width: 180,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (message.isLoading)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    message.text,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              )
            else ...[
              // Badge offline nếu là câu trả lời offline
              if (!isUser && message.isOfflineAnswer) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 11,
                        color: cs.onTertiaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Kết quả offline · dữ liệu local',
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SelectableText(
                message.text,
                style: TextStyle(
                  color: isUser ? cs.onPrimary : cs.onSurface,
                  height: 1.42,
                  fontSize: 14,
                ),
              ),
            ],
            // Chip loài
            if (!isUser && message.mentionedAnimals.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: message.mentionedAnimals.map((a) {
                  final canOpen = a.hasDbRecord;
                  return InkWell(
                    onTap: canOpen
                        ? () => onOpenAnimal?.call(a.dbId!, a.animalType)
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: canOpen
                            ? cs.primaryContainer
                            : cs.surface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: canOpen
                              ? cs.primary.withOpacity(0.5)
                              : cs.outlineVariant,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pets_rounded,
                            size: 14,
                            color: canOpen ? cs.primary : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            a.labelForChip,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: canOpen
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: canOpen
                                  ? cs.onPrimaryContainer
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                          if (canOpen) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 12,
                              color: cs.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Model và lưu trữ

enum AnimalChatRole { user, assistant }

class AnimalChatMessage {
  final AnimalChatRole role;
  final String text;
  final DateTime createdAt;
  final bool isLoading;
  final String? imagePath;
  final List<AiMentionedAnimal> mentionedAnimals;
  final bool isOfflineAnswer;

  AnimalChatMessage({
    required this.role,
    required this.text,
    required this.createdAt,
    this.isLoading = false,
    this.imagePath,
    this.mentionedAnimals = const [],
    this.isOfflineAnswer = false,
  });

  factory AnimalChatMessage.user(String text, {String? imagePath}) =>
      AnimalChatMessage(
        role: AnimalChatRole.user,
        text: text,
        imagePath: imagePath,
        createdAt: DateTime.now(),
      );

  factory AnimalChatMessage.assistant(
    String text, {
    bool isLoading = false,
    List<AiMentionedAnimal> mentionedAnimals = const [],
    bool isOfflineAnswer = false,
  }) => AnimalChatMessage(
    role: AnimalChatRole.assistant,
    text: text,
    createdAt: DateTime.now(),
    isLoading: isLoading,
    mentionedAnimals: mentionedAnimals,
    isOfflineAnswer: isOfflineAnswer,
  );

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'text': text,
    'created_at': createdAt.toIso8601String(),
    'image_path': imagePath,
    'is_offline_answer': isOfflineAnswer,
    'mentioned_animals': mentionedAnimals
        .map(
          (a) => {
            'name_display': a.nameDisplay,
            'name_english': a.nameEnglish,
            'animal_type': a.animalType,
            'db_id': a.dbId,
            'db_name_vi': a.dbNameVi,
            'db_name_en': a.dbNameEn,
          },
        )
        .toList(),
  };

  factory AnimalChatMessage.fromJson(Map<String, dynamic> json) {
    final rawAnimals = json['mentioned_animals'];
    final animals = rawAnimals is List
        ? rawAnimals.whereType<Map>().map((e) {
            final m = Map<String, dynamic>.from(e);
            return AiMentionedAnimal(
              nameDisplay: m['name_display']?.toString() ?? '',
              nameEnglish: m['name_english']?.toString(),
              animalType: m['animal_type']?.toString(),
              dbId: m['db_id']?.toString(),
              dbNameVi: m['db_name_vi']?.toString(),
              dbNameEn: m['db_name_en']?.toString(),
            );
          }).toList()
        : <AiMentionedAnimal>[];

    return AnimalChatMessage(
      role: json['role'] == 'user'
          ? AnimalChatRole.user
          : AnimalChatRole.assistant,
      text: json['text']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      imagePath: json['image_path']?.toString(),
      isOfflineAnswer: json['is_offline_answer'] == true,
      mentionedAnimals: animals,
    );
  }
}

class AnimalChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AnimalChatMessage> messages;

  const AnimalChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  bool get isDefaultTitle => title == 'Đoạn chat mới';

  factory AnimalChatSession.createWelcome() {
    final now = DateTime.now();
    return AnimalChatSession(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'Đoạn chat mới',
      createdAt: now,
      updatedAt: now,
      messages: [
        AnimalChatMessage.assistant(
          'Xin chào! Mình là trợ lý AI động vật. Hỏi tôi về bất kỳ loài nào nhé!\n\nKhi offline, tôi vẫn tìm kiếm được từ dữ liệu đã lưu sẵn trên máy.',
        ),
      ],
    );
  }

  AnimalChatSession copyWith({
    String? title,
    DateTime? updatedAt,
    List<AnimalChatMessage>? messages,
  }) => AnimalChatSession(
    id: id,
    title: title ?? this.title,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    messages: messages ?? this.messages,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'messages': messages
        .where((m) => !m.isLoading)
        .map((m) => m.toJson())
        .toList(),
  };

  factory AnimalChatSession.fromJson(Map<String, dynamic> json) =>
      AnimalChatSession(
        id:
            json['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: json['title']?.toString() ?? 'Đoạn chat mới',
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
            DateTime.now(),
        messages: json['messages'] is List
            ? List<AnimalChatMessage>.from(
                (json['messages'] as List).map(
                  (e) => AnimalChatMessage.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                ),
              )
            : [],
      );
}

class AnimalChatStorage {
  static const _key = 'animal_ai_chat_sessions_v3';

  static Future<List<AnimalChatSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map(
            (e) =>
                AnimalChatSession.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSessions(List<AnimalChatSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final keep = sessions.length > 30 ? sessions.take(30).toList() : sessions;
    final trimmed = keep.map((s) {
      final messages = s.messages.length > 80
          ? s.messages.sublist(s.messages.length - 80)
          : s.messages;
      return s.copyWith(messages: messages).toJson();
    }).toList();
    await prefs.setString(_key, jsonEncode(trimmed));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// Model phản hồi

class AiMentionedAnimal {
  final String nameDisplay;
  final String? nameEnglish;
  final String? animalType;
  final String? dbId;
  final String? dbNameVi;
  final String? dbNameEn;

  const AiMentionedAnimal({
    required this.nameDisplay,
    this.nameEnglish,
    this.animalType,
    this.dbId,
    this.dbNameVi,
    this.dbNameEn,
  });

  bool get hasDbRecord => dbId != null;
  String get labelForChip => dbNameVi ?? dbNameEn ?? nameDisplay;
}

// NETWORK HEALTH - kiểm tra Internet thật, tránh chờ timeout giả online

class NetworkHealth {
  NetworkHealth._();

  static Future<bool> hasInternet({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    // Ưu tiên kiểm tra HTTPS thật. Không cần API key; 401/403 vẫn chứng minh có mạng.
    try {
      final client = HttpClient()..connectionTimeout = timeout;
      final req = await client
          .getUrl(Uri.parse('https://api.groq.com/openai/v1/models'))
          .timeout(timeout);
      final res = await req.close().timeout(timeout);
      await res.drain<void>();
      client.close(force: true);
      return res.statusCode >= 200 && res.statusCode < 500;
    } catch (_) {
      // Dự phòng DNS ngắn, tránh treo lâu khi vừa tắt mạng.
      try {
        final result = await InternetAddress.lookup(
          'api.groq.com',
        ).timeout(timeout);
        return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }
}

// LOCAL CACHE - SQLite (sync từ Supabase, dùng khi offline)

class AnimalLocalCache {
  AnimalLocalCache._();
  static final instance = AnimalLocalCache._();

  static const _dbName = 'animal_cache.db';
  static const _dbVersion = 1;
  static const _prefsKeyUpdatedAt = 'animal_cache_updated_at';
  // Sync lại nếu data cũ hơn 24 giờ
  static const _syncIntervalHours = 24;

  Database? _db;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final dbPath = p.join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE animals (
            id TEXT PRIMARY KEY,
            name_vietnamese TEXT,
            name_english TEXT,
            animal_type TEXT,
            description_short TEXT,
            updated_at TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_name_en ON animals(name_english COLLATE NOCASE)',
        );
        await db.execute(
          'CREATE INDEX idx_name_vi ON animals(name_vietnamese COLLATE NOCASE)',
        );
        await db.execute('CREATE INDEX idx_type ON animals(animal_type)');
      },
    );
    _initialized = true;
  }

  // Sync nếu chưa sync hoặc data đã cũ hơn [_syncIntervalHours]
  Future<void> syncIfNeeded() async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString(_prefsKeyUpdatedAt);
    if (lastSyncStr != null) {
      final lastSync = DateTime.tryParse(lastSyncStr);
      if (lastSync != null) {
        final age = DateTime.now().difference(lastSync);
        if (age.inHours < _syncIntervalHours) return; // Còn mới, bỏ qua
      }
    }
    await _syncFromSupabase();
  }

  // Force sync (gọi khi muốn refresh thủ công)
  Future<void> forceSync() async {
    await init();
    await _syncFromSupabase();
  }

  Future<void> _syncFromSupabase() async {
    try {
      final db = Supabase.instance.client;
      // Lấy toàn bộ animals - chỉ các field cần thiết cho lookup & display
      // Dùng range để tránh timeout với bảng lớn (mỗi batch 1000 rows)
      var offset = 0;
      const batchSize = 1000;
      final allRows = <Map<String, dynamic>>[];

      while (true) {
        final batch = await db
            .from('animals')
            .select(
              'id, name_vietnamese, name_english, animal_type, description_short, updated_at',
            )
            .range(offset, offset + batchSize - 1)
            .timeout(const Duration(seconds: 12));
        final list = batch as List;
        if (list.isEmpty) break;
        allRows.addAll(list.map((e) => Map<String, dynamic>.from(e as Map)));
        if (list.length < batchSize) break;
        offset += batchSize;
      }

      if (allRows.isEmpty) return;

      // Upsert vào SQLite theo batch
      final sqlDb = _db!;
      await sqlDb.transaction((txn) async {
        // Xoá hết rồi insert lại để đảm bảo xoá những con đã bị delete trên server
        await txn.delete('animals');
        for (final row in allRows) {
          await txn.insert('animals', {
            'id': row['id']?.toString() ?? '',
            'name_vietnamese': row['name_vietnamese']?.toString(),
            'name_english': row['name_english']?.toString(),
            'animal_type': row['animal_type']?.toString(),
            'description_short': row['description_short']?.toString(),
            'updated_at': row['updated_at']?.toString(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

      // Lưu timestamp sync
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKeyUpdatedAt,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Sync fail không crash app
      debugPrint('[AnimalCache] sync failed: $e');
    }
  }

  // Fuzzy search trong SQLite local - dùng khi offline.
  // Bản cũ chỉ dùng LIKE nên nhập sai 1 ký tự như "belgal" sẽ không ra
  // "Bengal". Bản này tìm nhanh bằng LIKE trước, sau đó dự phòng sang
  // chấm điểm gần đúng trong Dart.
  Future<List<Map<String, dynamic>>> fuzzySearch({
    required String query,
    String? animalType,
    int limit = 8,
  }) async {
    await init();
    if (_db == null) return [];

    final cleanQuery = query.trim();
    final normalizedQuery = _normalizeForSearch(cleanQuery);
    if (normalizedQuery.isEmpty) return [];

    final typeFilter = animalType != null && animalType.isNotEmpty
        ? animalType
        : null;
    final picked = <Map<String, dynamic>>[];

    void addUnique(Iterable<Map<String, dynamic>> rows) {
      for (final r in rows) {
        final id = r['id']?.toString();
        if (id == null || id.isEmpty) continue;
        if (!picked.any((e) => e['id']?.toString() == id)) {
          picked.add(r);
        }
        if (picked.length >= limit) return;
      }
    }

    // 1) Tìm nhanh bằng LIKE cho trường hợp gõ đúng.
    final q = '%${cleanQuery.toLowerCase()}%';
    String sql;
    List<Object?> args;
    if (typeFilter != null) {
      sql = '''
        SELECT * FROM animals
        WHERE (LOWER(name_english) LIKE ? OR LOWER(name_vietnamese) LIKE ?)
          AND animal_type = ?
        LIMIT ?
      ''';
      args = [q, q, typeFilter, limit];
    } else {
      sql = '''
        SELECT * FROM animals
        WHERE LOWER(name_english) LIKE ? OR LOWER(name_vietnamese) LIKE ?
        LIMIT ?
      ''';
      args = [q, q, limit];
    }
    addUnique(
      (await _db!.rawQuery(sql, args)).map((e) => Map<String, dynamic>.from(e)),
    );
    if (picked.length >= limit) return picked.take(limit).toList();

    // 2) Dự phòng fuzzy: lấy pool nhỏ rồi tự so khớp bỏ dấu + sai chính tả nhẹ.
    final poolArgs = <Object?>[];
    final poolSql = typeFilter != null
        ? 'SELECT * FROM animals WHERE animal_type = ? LIMIT 2500'
        : 'SELECT * FROM animals LIMIT 5000';
    if (typeFilter != null) poolArgs.add(typeFilter);

    final pool = await _db!.rawQuery(poolSql, poolArgs);
    final scored = <({Map<String, dynamic> row, double score})>[];

    for (final raw in pool) {
      final row = Map<String, dynamic>.from(raw);
      final id = row['id']?.toString();
      if (id == null || picked.any((e) => e['id']?.toString() == id)) {
        continue;
      }
      final score = _scoreAnimalRow(normalizedQuery, row);
      if (score >= 0.72) scored.add((row: row, score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    addUnique(scored.map((e) => e.row));
    return picked.take(limit).toList();
  }

  double _scoreAnimalRow(String normalizedQuery, Map<String, dynamic> row) {
    final names = [
      row['name_english']?.toString() ?? '',
      row['name_vietnamese']?.toString() ?? '',
    ].where((e) => e.trim().isNotEmpty).join(' ');

    final normalizedNames = _normalizeForSearch(names);
    if (normalizedNames.isEmpty) return 0;
    if (normalizedNames.contains(normalizedQuery)) return 1;

    final queryTokens = normalizedQuery
        .split(' ')
        .where((t) => t.length >= 3)
        .toList();
    final nameTokens = normalizedNames
        .split(' ')
        .where((t) => t.length >= 3)
        .toList();
    if (queryTokens.isEmpty || nameTokens.isEmpty) return 0;

    var total = 0.0;
    for (final q in queryTokens) {
      var best = 0.0;
      for (final n in nameTokens) {
        final score = _tokenScore(q, n);
        if (score > best) best = score;
      }
      total += best;
    }
    return total / queryTokens.length;
  }

  double _tokenScore(String a, String b) {
    if (a == b) return 1;
    if (a.length >= 4 && b.contains(a)) return 0.96;
    if (b.length >= 4 && a.contains(b)) return 0.92;

    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen == 0) return 0;
    final maxDistance = maxLen <= 5 ? 1 : 2;
    final d = _levenshtein(a, b, maxDistance: maxDistance + 1);
    if (d > maxDistance) return 0;
    return 1 - (d / maxLen);
  }

  int _levenshtein(String a, String b, {int maxDistance = 3}) {
    if ((a.length - b.length).abs() > maxDistance) return maxDistance + 1;
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 0; i < a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0);
      current[0] = i + 1;
      var rowMin = current[0];
      for (var j = 0; j < b.length; j++) {
        final insertCost = current[j] + 1;
        final deleteCost = previous[j + 1] + 1;
        final replaceCost =
            previous[j] + (a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1);
        final value = insertCost < deleteCost
            ? (insertCost < replaceCost ? insertCost : replaceCost)
            : (deleteCost < replaceCost ? deleteCost : replaceCost);
        current[j + 1] = value;
        if (value < rowMin) rowMin = value;
      }
      if (rowMin > maxDistance) return maxDistance + 1;
      previous = current;
    }
    return previous.last;
  }

  String _normalizeForSearch(String input) {
    var s = input.toLowerCase().trim();
    const accents = {
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
    };
    accents.forEach((from, to) => s = s.replaceAll(from, to));
    return s
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Lookup chính xác theo tên để resolve chip - dùng khi offline
  Future<Map<String, dynamic>?> lookupByName({
    required String nameEn,
    required String nameDisplay,
    String? animalType,
  }) async {
    await init();
    if (_db == null) return null;

    final candidates = <String>{};
    if (nameEn.isNotEmpty) candidates.add(nameEn.toLowerCase());
    if (nameDisplay.isNotEmpty) candidates.add(nameDisplay.toLowerCase());
    // Biến thể bỏ suffix
    for (final suffix in [
      'cattle',
      'breed',
      'cow',
      'dog',
      'cat',
      'horse',
      'sheep',
      'pig',
    ]) {
      final trimmed = nameEn
          .toLowerCase()
          .replaceAll(RegExp(r'\b' + suffix + r'\b'), '')
          .trim();
      if (trimmed.isNotEmpty) candidates.add(trimmed);
    }

    for (final name in candidates) {
      if (name.isEmpty) continue;
      final q = '%$name%';
      String sql;
      List<Object?> args;

      if (animalType != null && animalType.isNotEmpty) {
        sql =
            'SELECT * FROM animals WHERE LOWER(name_english) LIKE ? AND animal_type = ? LIMIT 1';
        args = [q, animalType];
      } else {
        sql = 'SELECT * FROM animals WHERE LOWER(name_english) LIKE ? LIMIT 1';
        args = [q];
      }

      final rows = await _db!.rawQuery(sql, args);
      if (rows.isNotEmpty) return rows.first;

      // Thử name_vietnamese
      if (animalType != null && animalType.isNotEmpty) {
        sql =
            'SELECT * FROM animals WHERE LOWER(name_vietnamese) LIKE ? AND animal_type = ? LIMIT 1';
        args = [q, animalType];
      } else {
        sql =
            'SELECT * FROM animals WHERE LOWER(name_vietnamese) LIKE ? LIMIT 1';
        args = [q];
      }
      final rows2 = await _db!.rawQuery(sql, args);
      if (rows2.isNotEmpty) return rows2.first;
    }

    return null;
  }

  Future<int> get cachedCount async {
    await init();
    if (_db == null) return 0;
    final result = await _db!.rawQuery('SELECT COUNT(*) as cnt FROM animals');
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<DateTime?> get lastSyncTime async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_prefsKeyUpdatedAt);
    return s == null ? null : DateTime.tryParse(s);
  }
}

// OFFLINE KEYWORD SEARCH - trả lời khi không có mạng

class OfflineKeywordSearch {
  static final instance = OfflineKeywordSearch._();
  OfflineKeywordSearch._();

  static const _featureBlueEyes = 'blue_eyes';
  static const _featureOddEyes = 'odd_eyes';
  static const _featureHairless = 'hairless';

  Future<({String text, List<AiMentionedAnimal> animals})> search(
    String question,
  ) async {
    final cache = AnimalLocalCache.instance;
    final count = await cache.cachedCount;

    if (count == 0) {
      return (
        text:
            '📵 Chưa có dữ liệu offline. Vui lòng kết nối mạng lần đầu để tải dữ liệu về máy.',
        animals: <AiMentionedAnimal>[],
      );
    }

    final normalizedQuestion = _normalize(question);
    final animalType = _detectAnimalType(question);
    final requestedCount = _requestedCount(normalizedQuestion);
    final isListQuestion =
        _isListQuestion(normalizedQuestion) || requestedCount > 1;

    // 1) Rule theo đặc điểm phổ biến. Đặt TRƯỚC keyword search để tránh:
    // "mèo mắt hai màu" bị dính rule "màu"/"mắt xanh".
    // "mèo không lông" bị keyword "lông" kéo sang "mèo Anh lông dài".
    // "kể 4 con mèo có mắt xanh" bị ép chỉ trả 1 con.
    final feature = _detectFeatureIntent(normalizedQuestion);
    if (feature != null) {
      final desired = isListQuestion ? requestedCount.clamp(2, 8).toInt() : 1;
      final candidates = _featureCandidateNames(feature);
      final rows = await _findCandidateRows(
        cache: cache,
        candidates: candidates,
        animalType: animalType ?? 'cat',
        limit: desired,
      );
      final animals = _mentionsFromRowsAndCandidates(
        rows: rows,
        candidates: candidates,
        limit: desired,
        animalType: animalType ?? 'cat',
      );

      if (isListQuestion) {
        return (
          text: _buildFeatureListAnswer(
            feature: feature,
            desired: desired,
            animals: animals,
            cachedCount: count,
          ),
          animals: animals,
        );
      }

      final primaryRow = rows.isNotEmpty ? rows.first : null;
      return (
        text: _buildFeatureSingleAnswer(
          feature: feature,
          primaryRow: primaryRow,
          fallbackName: candidates.first,
          cachedCount: count,
        ),
        animals: animals.take(1).toList(),
      );
    }

    // 2) Rule tên riêng / typo phổ biến, ví dụ Bengal bị gõ thành benal/belgal.
    final specialKeywords = _specialSearchKeywords(normalizedQuestion);
    final keywords = specialKeywords.isNotEmpty
        ? specialKeywords
        : _extractKeywords(question);

    if (keywords.isEmpty) {
      return (
        text:
            '🔌 Đang offline. Hãy nhập tên loài, tên giống hoặc đặc điểm rõ hơn để tìm trong dữ liệu local ($count loài đã lưu).',
        animals: <AiMentionedAnimal>[],
      );
    }

    final limit = isListQuestion ? requestedCount.clamp(2, 8).toInt() : 8;
    final results = <Map<String, dynamic>>[];

    for (final kw in keywords) {
      final rows = await cache.fuzzySearch(
        query: kw,
        animalType: animalType,
        limit: limit,
      );
      for (final r in rows) {
        if (!results.any((e) => e['id']?.toString() == r['id']?.toString())) {
          results.add(r);
        }
      }
      if (!isListQuestion && specialKeywords.isNotEmpty && results.isNotEmpty) {
        break;
      }
      if (results.length >= limit) break;
    }

    if (results.isEmpty) {
      return (
        text:
            '🔍 Không tìm thấy "$question" trong ${count} loài đã lưu offline. Thử từ khoá khác hoặc kết nối mạng để hỏi AI.',
        animals: <AiMentionedAnimal>[],
      );
    }

    final shouldAnswerOne =
        !isListQuestion &&
        (specialKeywords.isNotEmpty ||
            _isColorQuestion(normalizedQuestion) ||
            _isIdentityQuestion(normalizedQuestion) ||
            _isDescriptionQuestion(normalizedQuestion));

    if (shouldAnswerOne) {
      final primary = _pickBestResult(results, normalizedQuestion);
      return (
        text: _buildSingleAnimalAnswer(
          question: question,
          normalizedQuestion: normalizedQuestion,
          row: primary,
          cachedCount: count,
        ),
        animals: [_toMentionedAnimal(primary)],
      );
    }

    final animals = results.take(limit).map(_toMentionedAnimal).toList();
    final names = animals.map((a) => a.labelForChip).join(', ');
    final typeLabel = animalType != null ? ' (nhóm: $animalType)' : '';
    final text = isListQuestion
        ? '🔌 Kết quả offline$typeLabel — mình tìm thấy ${animals.length} kết quả phù hợp nhất:\n\n$names\n\nBấm vào tên loài để xem chi tiết.'
        : '🔌 Kết quả offline$typeLabel — tìm thấy ${results.length} loài khớp với "${keywords.join(", ")}":\n\n$names\n\nBấm vào tên loài để xem chi tiết.';

    return (text: text, animals: animals);
  }

  Future<List<Map<String, dynamic>>> _findCandidateRows({
    required AnimalLocalCache cache,
    required List<String> candidates,
    required String? animalType,
    required int limit,
  }) async {
    final rows = <Map<String, dynamic>>[];
    for (final name in candidates) {
      final found = await cache.fuzzySearch(
        query: name,
        animalType: animalType,
        limit: 2,
      );
      for (final row in found) {
        final id = row['id']?.toString();
        if (id == null || id.isEmpty) continue;
        if (!rows.any((e) => e['id']?.toString() == id)) {
          rows.add(row);
        }
        if (rows.length >= limit) return rows;
      }
    }
    return rows;
  }

  List<AiMentionedAnimal> _mentionsFromRowsAndCandidates({
    required List<Map<String, dynamic>> rows,
    required List<String> candidates,
    required int limit,
    required String animalType,
  }) {
    final animals = <AiMentionedAnimal>[];
    final used = <String>{};

    for (final row in rows) {
      final a = _toMentionedAnimal(row);
      animals.add(a);
      used.add(
        _normalize(
          '${a.dbNameVi ?? ''} ${a.dbNameEn ?? ''} ${a.nameDisplay} ${a.nameEnglish ?? ''}',
        ),
      );
      if (animals.length >= limit) return animals;
    }

    // Nếu local DB chưa đủ những giống trong rule, vẫn trả tên gợi ý nhưng chip
    // sẽ không mở được detail. Như vậy offline vẫn trả lời đúng ý thay vì im lặng.
    for (final name in candidates) {
      final n = _normalize(name);
      final exists = used.any((u) => u.contains(n) || n.contains(u));
      if (exists) continue;
      animals.add(
        AiMentionedAnimal(
          nameDisplay: name,
          nameEnglish: name,
          animalType: animalType,
        ),
      );
      if (animals.length >= limit) break;
    }
    return animals;
  }

  String? _detectFeatureIntent(String q) {
    // Thứ tự rất quan trọng: "mắt hai màu" cũng có chữ "màu", nên phải bắt
    // odd-eyes trước blue-eyes/color.
    if (_isOddEyesQuestion(q)) return _featureOddEyes;
    if (_isBlueEyesQuestion(q)) return _featureBlueEyes;
    if (_isHairlessQuestion(q)) return _featureHairless;
    return null;
  }

  List<String> _featureCandidateNames(String feature) {
    switch (feature) {
      case _featureOddEyes:
        return const [
          'Khao Manee',
          'Turkish Angora',
          'Turkish Van',
          'Japanese Bobtail',
          'Persian',
          'Sphynx',
        ];
      case _featureBlueEyes:
        return const [
          'Siamese',
          'Ragdoll',
          'Birman',
          'Himalayan',
          'Balinese',
          'Snowshoe',
          'Tonkinese',
          'Colorpoint Shorthair',
        ];
      case _featureHairless:
        return const [
          'Sphynx',
          'Peterbald',
          'Donskoy',
          'Bambino',
          'Ukrainian Levkoy',
        ];
      default:
        return const [];
    }
  }

  String _buildFeatureListAnswer({
    required String feature,
    required int desired,
    required List<AiMentionedAnimal> animals,
    required int cachedCount,
  }) {
    final names = animals.take(desired).map((a) => a.labelForChip).join(', ');
    final missingDbCount = animals.where((a) => !a.hasDbRecord).length;
    final dbNote = missingDbCount > 0
        ? '\n\nLưu ý: có $missingDbCount tên là gợi ý theo rule offline nhưng chưa match được bản ghi local, nên chip có thể không mở detail.'
        : '';

    switch (feature) {
      case _featureOddEyes:
        return '🔌 Kết quả offline — ${animals.length} giống mèo có thể có mắt hai màu/odd eyes gồm:\n\n$names\n\nMắt hai màu là hiện tượng hai mắt có màu khác nhau, hay gặp ở một số mèo lông trắng hoặc có gene màu trắng.$dbNote';
      case _featureBlueEyes:
        return '🔌 Kết quả offline — ${animals.length} giống mèo thường có mắt xanh gồm:\n\n$names\n\nNhóm này hay gặp ở các giống colorpoint hoặc giống có biến thể mắt xanh.$dbNote';
      case _featureHairless:
        return '🔌 Kết quả offline — ${animals.length} giống mèo không lông/ít lông gồm:\n\n$names\n\nCác giống này thường cần giữ ấm và vệ sinh da kỹ hơn mèo có lông.$dbNote';
      default:
        return '🔌 Kết quả offline — mình tìm thấy ${animals.length} kết quả:\n\n$names$dbNote';
    }
  }

  String _buildFeatureSingleAnswer({
    required String feature,
    required Map<String, dynamic>? primaryRow,
    required String fallbackName,
    required int cachedCount,
  }) {
    final display = primaryRow == null
        ? fallbackName
        : _displayName(primaryRow);
    final en = primaryRow?['name_english']?.toString().trim() ?? fallbackName;
    final enPart = en.isNotEmpty && en != display ? ' ($en)' : '';
    final desc = primaryRow?['description_short']?.toString().trim() ?? '';

    switch (feature) {
      case _featureOddEyes:
        return '🔌 Kết quả offline — mèo mắt hai màu thường được gọi là mèo odd-eyed/heterochromia. Một giống rất nổi bật là $display$enPart.\n\n${desc.isNotEmpty ? '$desc\n\n' : ''}Muốn xem nhiều giống hơn, hỏi kiểu: "kể 4 con mèo mắt hai màu".';
      case _featureBlueEyes:
        return '🔌 Kết quả offline — một giống mèo nổi bật có mắt xanh là $display$enPart.\n\n${desc.isNotEmpty ? '$desc\n\n' : ''}Muốn xem nhiều giống hơn, hỏi kiểu: "kể 4 con mèo có mắt xanh".';
      case _featureHairless:
        return '🔌 Kết quả offline — mèo không lông thường là $display$enPart. Giống này nổi bật vì gần như không có lông, da lộ rõ và cần được giữ ấm, vệ sinh da thường xuyên.\n\n${desc.isNotEmpty ? '$desc\n\n' : ''}Bấm vào chip bên dưới để xem chi tiết trong dữ liệu local.';
      default:
        return '🔌 Kết quả offline — mình tìm thấy $display trong $cachedCount loài đã lưu.';
    }
  }

  Map<String, dynamic> _pickBestResult(
    List<Map<String, dynamic>> rows,
    String normalizedQuestion,
  ) {
    if (rows.length == 1) return rows.first;

    // Ưu tiên match tên giống xuất hiện rõ trong câu hỏi.
    for (final row in rows) {
      final normalizedNames = _normalize(
        '${row['name_vietnamese'] ?? ''} ${row['name_english'] ?? ''}',
      );
      final nameTokens = normalizedNames
          .split(' ')
          .where((t) => t.length >= 4)
          .toList();
      if (nameTokens.any((t) => normalizedQuestion.contains(t))) {
        return row;
      }
    }
    return rows.first;
  }

  String _buildSingleAnimalAnswer({
    required String question,
    required String normalizedQuestion,
    required Map<String, dynamic> row,
    required int cachedCount,
  }) {
    final vi = row['name_vietnamese']?.toString().trim() ?? '';
    final en = row['name_english']?.toString().trim() ?? '';
    final display = _displayName(row);
    final desc = row['description_short']?.toString().trim() ?? '';
    final normalizedNames = _normalize('$vi $en');
    final enPart = en.isNotEmpty && en != display ? ' ($en)' : '';

    if (_isColorQuestion(normalizedQuestion)) {
      if (normalizedNames.contains('bengal')) {
        return '🔌 Kết quả offline — $display$enPart thường có nền lông vàng, cam, nâu vàng hoặc kem, '
            'trên đó có hoa văn đốm/hoa thị hoặc vân cẩm thạch màu nâu, đen. Một số biến thể có màu silver hoặc snow.\n\n'
            'Bấm vào chip bên dưới để xem chi tiết trong dữ liệu local.';
      }

      if (desc.isNotEmpty) {
        return '🔌 Kết quả offline — mình tìm thấy $display$enPart.\n\n'
            'Dữ liệu local hiện có mô tả ngắn: $desc\n\n'
            'Nếu cần câu trả lời màu lông chính xác hơn, hãy bật mạng để hỏi AI online.';
      }

      return '🔌 Kết quả offline — mình tìm thấy $display$enPart, nhưng dữ liệu local hiện chưa có thông tin màu lông chi tiết.\n\n'
          'Bấm vào chip bên dưới để xem chi tiết hoặc bật mạng để hỏi AI online.';
    }

    if (_isIdentityQuestion(normalizedQuestion)) {
      return '🔌 Kết quả offline — đó nhiều khả năng là $display$enPart.\n\n'
          '${desc.isNotEmpty ? '$desc\n\n' : ''}'
          'Bấm vào chip bên dưới để xem chi tiết trong dữ liệu local.';
    }

    if (desc.isNotEmpty) {
      return '🔌 Kết quả offline — $display$enPart:\n\n$desc\n\n'
          'Bấm vào chip bên dưới để xem chi tiết.';
    }

    return '🔌 Kết quả offline — mình tìm thấy $display$enPart trong $cachedCount loài đã lưu.\n\n'
        'Bấm vào chip bên dưới để xem chi tiết.';
  }

  List<String> _specialSearchKeywords(String normalizedQuestion) {
    final result = <String>[];

    // Các lỗi gõ thường gặp: Bengal bị gõ thành benal/belgal.
    if (normalizedQuestion.contains('bengal') ||
        normalizedQuestion.contains('benal') ||
        normalizedQuestion.contains('belgal')) {
      result.add('bengal');
    }

    return result.toSet().toList();
  }

  bool _isHairlessQuestion(String q) {
    return q.contains('khong long') ||
        q.contains('khong co long') ||
        q.contains('hairless') ||
        q.contains('sphynx') ||
        q.contains('sphinx');
  }

  bool _isOddEyesQuestion(String q) {
    return q.contains('mat hai mau') ||
        q.contains('hai mau mat') ||
        q.contains('2 mau mat') ||
        q.contains('mat 2 mau') ||
        q.contains('mat lech mau') ||
        q.contains('mat khac mau') ||
        q.contains('odd eye') ||
        q.contains('odd eyed') ||
        q.contains('heterochromia');
  }

  bool _isBlueEyesQuestion(String q) {
    return q.contains('mat xanh') ||
        q.contains('mat mau xanh') ||
        q.contains('mat xanh duong') ||
        q.contains('blue eye') ||
        q.contains('blue eyed') ||
        q.contains('blue eyes');
  }

  bool _isColorQuestion(String q) {
    // Không coi "mắt hai màu" là hỏi màu lông.
    if (_isOddEyesQuestion(q)) return false;
    return q.contains('mau long') ||
        q.contains('long mau') ||
        q.contains('mau gi') ||
        q.contains('color') ||
        q.contains('colour') ||
        q.contains('coat color');
  }

  bool _isIdentityQuestion(String q) {
    return q.contains('la meo gi') ||
        q.contains('la con gi') ||
        q.contains('giong gi') ||
        q.contains('loai gi') ||
        q.contains('ten gi') ||
        q.contains('what breed') ||
        q.contains('which breed');
  }

  bool _isDescriptionQuestion(String q) {
    return q.contains('mo ta') ||
        q.contains('dac diem') ||
        q.contains('thong tin') ||
        q.contains('nhu the nao');
  }

  bool _isListQuestion(String q) {
    return q.contains('ke ') ||
        q.startsWith('ke') ||
        q.contains('liet ke') ||
        q.contains('danh sach') ||
        q.contains('nhung con') ||
        q.contains('cac con') ||
        q.contains('may con') ||
        q.contains('vai con') ||
        q.contains('list') ||
        q.contains('top');
  }

  int _requestedCount(String q) {
    final m = RegExp(r'\b([2-9]|10)\b').firstMatch(q);
    if (m != null) return int.tryParse(m.group(1) ?? '') ?? 4;

    final words = <String, int>{
      'hai': 2,
      'ba': 3,
      'bon': 4,
      'tu': 4,
      'nam': 5,
      'sau': 6,
      'bay': 7,
      'tam': 8,
      'chin': 9,
      'muoi': 10,
    };
    for (final entry in words.entries) {
      if (q.split(' ').contains(entry.key)) return entry.value;
    }
    return _isListQuestion(q) ? 4 : 1;
  }

  AiMentionedAnimal _toMentionedAnimal(Map<String, dynamic> r) {
    return AiMentionedAnimal(
      nameDisplay:
          r['name_vietnamese']?.toString() ??
          r['name_english']?.toString() ??
          '',
      nameEnglish: r['name_english']?.toString(),
      animalType: r['animal_type']?.toString(),
      dbId: r['id']?.toString(),
      dbNameVi: r['name_vietnamese']?.toString(),
      dbNameEn: r['name_english']?.toString(),
    );
  }

  String _displayName(Map<String, dynamic> r) {
    final vi = r['name_vietnamese']?.toString().trim() ?? '';
    final en = r['name_english']?.toString().trim() ?? '';
    return vi.isNotEmpty ? vi : en;
  }

  List<String> _extractKeywords(String question) {
    final stopWords = {
      'là', 'la', 'gì', 'gi', 'con', 'và', 'va', 'của', 'cua', 'có', 'co',
      'không', 'khong', 'được', 'duoc', 'cho', 'the', 'and', 'what', 'is',
      'are', 'how', 'why', 'when', 'một', 'mot', 'những', 'nhung', 'các',
      'cac', 'hay', 'hoặc', 'hoac', 'tôi', 'toi', 'bạn', 'ban', 'mình',
      'minh', 'về', 've', 'trong', 'với', 'voi', 'từ', 'tu', 'đến', 'den',
      'này', 'nay', 'đó', 'do', 'thì', 'thi', 'tìm', 'tim', 'kiếm', 'kiem',
      'giống', 'giong', 'loài', 'loai', 'thông', 'thong', 'tin', 'nhận',
      'nhan', 'biết', 'biet', 'hỏi', 'hoi', 'màu', 'mau', 'mắt', 'mat',
      'xanh', 'hai', 'bon', 'bốn', 'kể', 'ke', 'liệt', 'liet', 'danh',
      'sách', 'sach',
      // Từ chỉ nhóm loài dùng để detect animal_type, không dùng làm keyword.
      'mèo', 'meo', 'cat', 'cats', 'chó', 'cho', 'dog', 'dogs', 'bò', 'bo',
      'cow', 'cattle', 'trâu', 'trau', 'buffalo', 'ngựa', 'ngua', 'horse',
      'hổ', 'ho', 'tiger', 'sư', 'su', 'tử', 'tu', 'lion', 'gấu', 'gau',
      'bear', 'lợn', 'lon', 'heo', 'pig', 'cừu', 'cuu', 'sheep', 'dê', 'de',
      'goat', 'thỏ', 'tho', 'rabbit', 'gà', 'ga', 'chicken', 'vịt', 'vit',
      'duck',
    };

    final tokens = _normalize(question)
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 3 && !stopWords.contains(t))
        .toSet()
        .toList();
    return tokens;
  }

  String? _detectAnimalType(String q) {
    final lower = _normalize(q);
    if (_has(lower, ['meo', 'cat'])) return 'cat';
    if (_has(lower, ['cho', 'dog'])) return 'dog';
    if (_has(lower, ['bo', 'cattle', 'cow'])) return 'cattle';
    if (_has(lower, ['trau', 'buffalo'])) return 'buffalo';
    if (_has(lower, ['ngua', 'horse'])) return 'horse';
    if (_has(lower, ['ho', 'tiger'])) return 'tiger';
    if (_has(lower, ['su tu', 'lion'])) return 'lion';
    if (_has(lower, ['gau', 'bear'])) return 'bear';
    if (_has(lower, ['lon', 'heo', 'pig'])) return 'pig';
    if (_has(lower, ['cuu', 'sheep'])) return 'sheep';
    if (_has(lower, ['de', 'goat'])) return 'goat';
    if (_has(lower, ['tho', 'rabbit'])) return 'rabbit';
    if (_has(lower, ['ga', 'chicken'])) return 'chicken';
    if (_has(lower, ['vit', 'duck'])) return 'duck';
    return null;
  }

  bool _has(String q, List<String> terms) => terms.any((t) => q.contains(t));

  String _normalize(String input) {
    var s = input.toLowerCase().trim();
    const accents = {
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
    };
    accents.forEach((from, to) => s = s.replaceAll(from, to));
    return s
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

// GROQ SERVICE - online: Groq, offline: local keyword search

class GroqAnimalChatService {
  static const String _groqApiKey = AppEnv.groqApiKey;
  static const String _groqUrl = AppEnv.groqChatUrl;
  static const String _groqModel = AppEnv.groqChatModel;

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<({String text, List<AiMentionedAnimal> animals, bool isOffline})> ask({
    required String question,
    File? imageFile,
    List<AnimalChatMessage> recentMessages = const [],
    bool isOnline = true,
  }) async {
    // Offline path
    // Không chỉ tin ConnectivityResult, vì máy có Wi-Fi nhưng Internet đã mất
    // vẫn làm Groq/Supabase treo tới timeout.
    if (!AppEnv.hasGroq) {
      return _offlineFallback(
        question,
        reason:
            '⚠️ Chưa cấu hình GROQ_API_KEY, mình đã chuyển sang tìm offline.',
      );
    }

    final hasInternet = await NetworkHealth.hasInternet(
      timeout: const Duration(seconds: 2),
    );
    if (!hasInternet) {
      return _offlineFallback(
        question,
        reason:
            '⚠️ Máy đang có Wi‑Fi/mobile nhưng không truy cập được Internet, mình đã chuyển sang tìm offline.',
      );
    }

    try {
      // Online path
      final historyText = _buildHistoryText(recentMessages);
      final imagePart = await _buildOptionalImagePart(imageFile);

      const systemPrompt =
          'Bạn là trợ lý AI của ứng dụng từ điển động vật ZooTrek. Trả lời bằng tiếng Việt.\n\n'
          'BẮT BUỘC: Mỗi câu trả lời PHẢI là JSON hợp lệ theo đúng cấu trúc sau, KHÔNG có markdown, KHÔNG có backtick:\n'
          '{"answer":"<câu trả lời đầy đủ bằng tiếng Việt, ngắn gọn dễ hiểu>","animals":[{"name_display":"<tên loài/giống bạn viết trong answer>","name_english":"<tên tiếng Anh chuẩn nhất>","animal_type":"<cattle|dog|cat|horse|buffalo|tiger|lion|bear|pig|sheep|goat|rabbit|chicken|duck|fish|bird|reptile|other>"}]}\n\n'
          'QUY TẮC:\n'
          '- Nếu không đề cập loài cụ thể nào, animals = []\n'
          '- Liệt kê TẤT CẢ loài/giống bạn nhắc đến trong answer\n'
          '- name_english phải là tên tiếng Anh phổ biến/khoa học nhất\n'
          '- Từ chối nhẹ nếu câu hỏi không liên quan động vật\n'
          '- KHÔNG bịa thông tin khi không chắc chắn';

      final userPrompt = 'LỊCH SỬ GẦN ĐÂY:\n$historyText\n\nCÂU HỎI: $question';

      final userContent = imagePart == null
          ? userPrompt
          : [
              {'type': 'text', 'text': userPrompt},
              imagePart,
            ];

      final body = jsonEncode({
        'model': _groqModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userContent},
        ],
        'temperature': 0.2,
        'max_tokens': 1200,
      });

      final res = await http
          .post(
            Uri.parse(_groqUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_groqApiKey',
            },
            body: body,
          )
          // Đừng để user chờ 40s. Quá 15s thì dự phòng offline ngay.
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        return (
          text: 'Groq API lỗi ${res.statusCode}.',
          animals: <AiMentionedAnimal>[],
          isOffline: false,
        );
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        return (
          text: 'AI không trả về nội dung.',
          animals: <AiMentionedAnimal>[],
          isOffline: false,
        );
      }

      final rawText =
          choices.first['message']?['content']?.toString().trim() ?? '';

      // Đọc JSON từ phản hồi online
      Map<String, dynamic>? parsed;
      try {
        final cleaned = rawText
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '')
            .trim();
        parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      } catch (_) {
        return (
          text: rawText,
          animals: <AiMentionedAnimal>[],
          isOffline: false,
        );
      }

      final displayText = parsed['answer']?.toString() ?? rawText;
      final animalsRaw = parsed['animals'];

      if (animalsRaw == null || animalsRaw is! List || animalsRaw.isEmpty) {
        return (
          text: displayText,
          animals: <AiMentionedAnimal>[],
          isOffline: false,
        );
      }

      final aiList = animalsRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final resolved = await _resolveAnimals(aiList, isOnline: true);
      return (text: displayText, animals: resolved, isOffline: false);
    } on TimeoutException {
      return _offlineFallback(
        question,
        reason: '⏱️ Kết nối AI quá lâu, mình đã chuyển sang tìm offline.',
      );
    } on SocketException {
      return _offlineFallback(
        question,
        reason: '⚠️ Mất mạng giữa chừng, mình đã chuyển sang tìm offline.',
      );
    } on http.ClientException {
      return _offlineFallback(
        question,
        reason: '⚠️ Không gọi được AI online, mình đã chuyển sang tìm offline.',
      );
    }
  }

  Future<({String text, List<AiMentionedAnimal> animals, bool isOffline})>
  _offlineFallback(String question, {String? reason}) async {
    final result = await OfflineKeywordSearch.instance.search(question);
    final prefix = reason == null ? '' : '$reason\n\n';
    return (
      text: '$prefix${result.text}',
      animals: result.animals,
      isOffline: true,
    );
  }

  // Resolve tên loài -> lookup DB (online: Supabase, offline: SQLite)
  Future<List<AiMentionedAnimal>> _resolveAnimals(
    List<Map<String, dynamic>> aiAnimals, {
    required bool isOnline,
  }) async {
    final result = <AiMentionedAnimal>[];
    for (final a in aiAnimals) {
      final nameDisplay = a['name_display']?.toString() ?? '';
      final nameEn = a['name_english']?.toString() ?? '';
      final animalType = a['animal_type']?.toString();

      Map<String, dynamic>? dbRow;
      try {
        if (isOnline) {
          dbRow = await _supabaseLookup(
            nameEn: nameEn,
            nameDisplay: nameDisplay,
            animalType: animalType,
          );
        }
        // Fallback: local cache (cả khi online để bù lỗi Supabase)
        dbRow ??= await AnimalLocalCache.instance.lookupByName(
          nameEn: nameEn,
          nameDisplay: nameDisplay,
          animalType: animalType,
        );
      } catch (_) {
        dbRow = null;
      }

      result.add(
        AiMentionedAnimal(
          nameDisplay: nameDisplay,
          nameEnglish: nameEn.isEmpty ? null : nameEn,
          animalType: animalType,
          dbId: dbRow?['id']?.toString(),
          dbNameVi: dbRow?['name_vietnamese']?.toString(),
          dbNameEn: dbRow?['name_english']?.toString(),
        ),
      );
    }
    return result;
  }

  Future<Map<String, dynamic>?> _supabaseLookup({
    required String nameEn,
    required String nameDisplay,
    String? animalType,
  }) async {
    final candidates = <String>{};
    if (nameEn.isNotEmpty) candidates.add(nameEn);
    if (nameDisplay.isNotEmpty) candidates.add(nameDisplay);
    for (final suffix in [
      'cattle',
      'breed',
      'cow',
      'dog',
      'cat',
      'horse',
      'sheep',
      'pig',
    ]) {
      final trimmed = nameEn
          .toLowerCase()
          .replaceAll(RegExp(r'\b' + suffix + r'\b'), '')
          .trim();
      if (trimmed.isNotEmpty && trimmed != nameEn.toLowerCase()) {
        candidates.add(trimmed);
      }
    }

    for (final name in candidates) {
      final escaped = name.replaceAll('%', '').trim();
      if (escaped.isEmpty) continue;

      try {
        dynamic q = _supabase
            .from('animals')
            .select('id, name_vietnamese, name_english, animal_type')
            .ilike('name_english', '%$escaped%');
        if (animalType != null && animalType.isNotEmpty) {
          q = q.eq('animal_type', animalType);
        }
        final data = await q.limit(1).timeout(const Duration(seconds: 6));
        final list = data as List;
        if (list.isNotEmpty)
          return Map<String, dynamic>.from(list.first as Map);
      } catch (_) {}

      try {
        dynamic qv = _supabase
            .from('animals')
            .select('id, name_vietnamese, name_english, animal_type')
            .ilike('name_vietnamese', '%$escaped%');
        if (animalType != null && animalType.isNotEmpty) {
          qv = qv.eq('animal_type', animalType);
        }
        final data = await qv.limit(1).timeout(const Duration(seconds: 6));
        final list = data as List;
        if (list.isNotEmpty)
          return Map<String, dynamic>.from(list.first as Map);
      } catch (_) {}
    }
    return null;
  }

  String _buildHistoryText(List<AnimalChatMessage> messages) {
    final clean = messages.where((m) => !m.isLoading).toList();
    final last = clean.length > 8 ? clean.sublist(clean.length - 8) : clean;
    if (last.isEmpty) return 'Chưa có lịch sử.';
    return last
        .map(
          (m) =>
              '${m.role == AnimalChatRole.user ? 'User' : 'Assistant'}: ${m.text}',
        )
        .join('\n');
  }

  Future<Map<String, dynamic>?> _buildOptionalImagePart(File? imageFile) async {
    if (imageFile == null) return null;
    try {
      final bytes = await imageFile.readAsBytes();
      if (bytes.length > 4 * 1024 * 1024) return null;
      return {
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,${base64Encode(bytes)}'},
      };
    } catch (_) {
      return null;
    }
  }
}
