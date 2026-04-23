import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Auth/auth_service.dart';
import '../../language/Locale_provider.dart';
import '../provider/feedback_service.dart';

class ContactTab extends StatelessWidget {
  final Color primaryGreen;
  const ContactTab({super.key, required this.primaryGreen});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? primaryGreen.withOpacity(0.2) : primaryGreen.withOpacity(0.1),
                  ),
                  child: Icon(Icons.support_agent_rounded, size: 46, color: primaryGreen),
                ),
                const SizedBox(height: 12),
                Text(
                  t.tr('Chúng tôi luôn lắng nghe bạn!'),
                  style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Kênh liên hệ nhanh ──────────────────────────────
          _SectionLabel(label: t.tr('Kênh liên hệ'), color: primaryGreen),
          const SizedBox(height: 10),
          _buildContactCard(
            context: context, isDark: isDark,
            icon: Icons.email_rounded, color: Colors.redAccent,
            title: t.tr('Email Hỗ Trợ'), value: 'support@aniquest.com',
            onTap: () => _launch('mailto:support@aniquest.com'),
          ),
          _buildContactCard(
            context: context, isDark: isDark,
            icon: Icons.facebook_rounded, color: Colors.blue,
            title: 'Facebook', value: 'AniQuest Official',
            onTap: () => _launch('https://facebook.com/'),
          ),
          _buildContactCard(
            context: context, isDark: isDark,
            icon: Icons.code_rounded,
            color: isDark ? Colors.white : Colors.black87,
            title: 'GitHub', value: 'AniQuest Open Source',
            onTap: () => _launch('https://github.com/'),
          ),

          const SizedBox(height: 32),

          // ── Form góp ý / báo lỗi ────────────────────────────
          _SectionLabel(label: t.tr('Góp ý & Báo lỗi'), color: primaryGreen),
          const SizedBox(height: 12),
          _FeedbackForm(primaryGreen: primaryGreen),

          const SizedBox(height: 32),
          Center(
            child: Text(
              '© 2026 AniQuest KLTN',
              style: TextStyle(fontSize: 12, color: colorScheme.outline),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor   = isDark ? Colors.grey[850] : colorScheme.surface;
    final borderColor = isDark ? Colors.white12 : colorScheme.outlineVariant.withOpacity(0.5);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        subtitle: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorScheme.outline),
      ),
    );
  }
}

// ── Label tiêu đề section ────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Form Góp ý / Báo lỗi
// ══════════════════════════════════════════════════════════════
class _FeedbackForm extends StatefulWidget {
  final Color primaryGreen;
  const _FeedbackForm({required this.primaryGreen});

  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  final _formKey      = GlobalKey<FormState>();
  final _service      = FeedbackService();
  final _picker       = ImagePicker();

  final _descCtrl     = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();

  String _type        = 'bug';        // bug | suggestion | other
  bool _isSubmitting  = false;
  bool _submitted     = false;

  // Danh sách file đã chọn (ảnh hoặc video)
  final List<XFile> _mediaFiles = [];
  static const _maxFiles = 5;

  @override
  void initState() {
    super.initState();
    // Pre-fill nếu đã đăng nhập
    final user = AuthService.currentUser;
    if (user != null) {
      final meta = user.userMetadata;
      _nameCtrl.text  = (meta?['full_name'] as String?) ?? '';
      _emailCtrl.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMedia({required bool isVideo}) async {
    if (_mediaFiles.length >= _maxFiles) {
      _showSnack('Tối đa $_maxFiles file mỗi lần gửi');
      return;
    }
    try {
      XFile? file;
      if (isVideo) {
        file = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 2));
      } else {
        file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      }
      if (file != null) setState(() => _mediaFiles.add(file!));
    } catch (_) {
      _showSnack('Không thể chọn file. Kiểm tra quyền truy cập.');
    }
  }

  void _removeFile(int index) => setState(() => _mediaFiles.removeAt(index));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      // Upload từng file media
      final List<String> urls = [];
      for (final xfile in _mediaFiles) {
        final file = File(xfile.path);
        final url  = await _service.uploadMedia(file, xfile.name);
        if (url != null) urls.add(url);
      }

      // Gửi feedback
      await _service.submitFeedback(
        type: _type,
        description: _descCtrl.text.trim(),
        mediaUrls: urls,
        contactName:  _nameCtrl.text.trim().isNotEmpty  ? _nameCtrl.text.trim()  : null,
        contactEmail: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      );

      setState(() { _isSubmitting = false; _submitted = true; });
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showSnack('Gửi thất bại: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final isLoggedIn = AuthService.isLoggedIn;

    if (_submitted) return _buildSuccess(cs);

    final cardBg     = isDark ? Colors.grey[850] : cs.surface;
    final borderCol  = isDark ? Colors.white12 : cs.outlineVariant.withOpacity(0.5);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Loại phản hồi ─────────────────────────────────
            Text('Loại phản hồi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
            const SizedBox(height: 10),
            _TypeSelector(
              selected: _type,
              primaryGreen: widget.primaryGreen,
              onChanged: (v) => setState(() => _type = v),
            ),

            const SizedBox(height: 20),

            // ── Thông tin người dùng ──────────────────────────
            if (!isLoggedIn) ...[
              Text('Thông tin của bạn (tùy chọn)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
              const SizedBox(height: 10),
              _buildField(_nameCtrl,  'Họ tên', Icons.person_outline_rounded, cs),
              const SizedBox(height: 10),
              _buildField(_emailCtrl, 'Email', Icons.email_outlined, cs, type: TextInputType.emailAddress),
              const SizedBox(height: 20),
            ] else ...[
              // Đã đăng nhập: hiển thị info thay vì form nhập
              _LoggedInUserInfo(primaryGreen: widget.primaryGreen),
              const SizedBox(height: 20),
            ],

            // ── Mô tả ─────────────────────────────────────────
            Text('Mô tả chi tiết *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descCtrl,
              maxLines: 5,
              style: TextStyle(fontSize: 14, color: cs.onSurface),
              decoration: _inputDeco(
                cs: cs,
                hint: _type == 'bug'
                    ? 'Mô tả lỗi bạn gặp phải, các bước tái hiện lỗi...'
                    : _type == 'suggestion'
                    ? 'Tính năng bạn muốn thêm, cải tiến mong muốn...'
                    : 'Nội dung góp ý của bạn...',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng mô tả vấn đề' : null,
            ),

            const SizedBox(height: 20),

            // ── Upload media ──────────────────────────────────
            Text('Đính kèm ảnh / video (tùy chọn)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Tối đa $_maxFiles file · Ảnh hoặc video ≤ 2 phút', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withOpacity(0.6))),
            const SizedBox(height: 10),

            // Grid preview media đã chọn
            if (_mediaFiles.isNotEmpty) ...[
              _MediaPreviewGrid(files: _mediaFiles, onRemove: _removeFile),
              const SizedBox(height: 10),
            ],

            // Nút chọn file
            if (_mediaFiles.length < _maxFiles)
              Row(
                children: [
                  _MediaPickerBtn(
                    icon: Icons.image_outlined,
                    label: 'Chọn ảnh',
                    color: Colors.blue,
                    onTap: () => _pickMedia(isVideo: false),
                  ),
                  const SizedBox(width: 10),
                  _MediaPickerBtn(
                    icon: Icons.videocam_outlined,
                    label: 'Chọn video',
                    color: Colors.purple,
                    onTap: () => _pickMedia(isVideo: true),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // ── Submit ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                label: Text(_isSubmitting ? 'Đang gửi...' : 'Gửi phản hồi'),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.primaryGreen,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: widget.primaryGreen.withOpacity(0.12), shape: BoxShape.circle),
            child: const Center(child: Text('✅', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(height: 16),
          Text('Đã gửi thành công!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 8),
          Text(
            'Cảm ơn bạn đã góp ý. Chúng tôi sẽ xem xét và phản hồi sớm nhất có thể.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.6),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => setState(() { _submitted = false; _descCtrl.clear(); _mediaFiles.clear(); }),
            child: const Text('Gửi thêm phản hồi'),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, ColorScheme cs, {TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      style: TextStyle(fontSize: 14, color: cs.onSurface),
      decoration: _inputDeco(cs: cs, label: label, icon: icon),
    );
  }

  InputDecoration _inputDeco({required ColorScheme cs, String? label, String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withOpacity(0.5)),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: cs.onSurfaceVariant) : null,
      filled: true,
      fillColor: cs.surfaceContainerHighest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
    );
  }
}

// ── Widget hiển thị info user đã đăng nhập ──────────────────
class _LoggedInUserInfo extends StatelessWidget {
  final Color primaryGreen;
  const _LoggedInUserInfo({required this.primaryGreen});

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final user = AuthService.currentUser;
    final meta = user?.userMetadata;
    final name  = (meta?['full_name'] as String?) ?? 'Người dùng';
    final email = user?.email ?? '';
    final avatar = meta?['avatar_url'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: primaryGreen.withOpacity(0.2),
            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
            child: avatar == null ? Text(name[0].toUpperCase(), style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cs.onSurface)),
                Text(email, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.verified_rounded, size: 18, color: primaryGreen),
        ],
      ),
    );
  }
}

// ── Selector loại phản hồi ───────────────────────────────────
class _TypeSelector extends StatelessWidget {
  final String selected;
  final Color primaryGreen;
  final ValueChanged<String> onChanged;

  const _TypeSelector({required this.selected, required this.primaryGreen, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final types = [
      ('bug',        '🐛', 'Báo lỗi'),
      ('suggestion', '💡', 'Góp ý'),
      ('other',      '💬', 'Khác'),
    ];

    return Row(
      children: types.map((t) {
        final isSelected = selected == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? primaryGreen.withOpacity(0.15) : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? primaryGreen : cs.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Text(t.$2, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(t.$3, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? primaryGreen : cs.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Preview grid media đã chọn ───────────────────────────────
class _MediaPreviewGrid extends StatelessWidget {
  final List<XFile> files;
  final void Function(int) onRemove;

  const _MediaPreviewGrid({required this.files, required this.onRemove});

  bool _isVideo(XFile f) {
    final ext = f.name.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: files.asMap().entries.map((e) {
        final index = e.key;
        final file  = e.value;
        final video = _isVideo(file);

        return Stack(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey[200]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: video
                    ? Container(
                  color: Colors.black87,
                  child: const Center(child: Icon(Icons.videocam_rounded, color: Colors.white, size: 32)),
                )
                    : Image.file(File(file.path), fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 4, right: 4,
              child: GestureDetector(
                onTap: () => onRemove(index),
                child: Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ── Nút chọn file ─────────────────────────────────────────────
class _MediaPickerBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaPickerBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}