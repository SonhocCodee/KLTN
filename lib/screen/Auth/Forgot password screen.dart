import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
// Màn 1: Nhập email → gửi link reset
// ─────────────────────────────────────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  bool _loading  = false;
  bool _sent     = false;
  String? _error;

  late AnimationController _bgCtrl;

  final _colors = [const Color(0xFFFBBF24), const Color(0xFFF97316)];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }
  final List<Color> _gradientColors = [
    const Color(0xFFFBBF24),
    const Color(0xFFF97316),
  ];

  @override
  void dispose() {
    _bgCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Vui lòng nhập email');
      return;
    }
    setState(() { _loading = true; _error = null; });
    HapticFeedback.mediumImpact();
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.kltnapp://reset-password',
      );
      setState(() { _sent = true; _loading = false; });
    } on AuthException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Đã có lỗi xảy ra. Thử lại sau.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _AuthBg(controller: _bgCtrl, colors: _colors),
          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _GlassBackButton(onTap: () => Navigator.pop(context)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: _sent ? _buildSuccess() : _buildForm(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _colors),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _colors[0].withOpacity(0.5), blurRadius: 24, spreadRadius: 3)],
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
          ),
          child: const Center(child: Text('🔑', style: TextStyle(fontSize: 36))),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: _gradientColors,
          ).createShader(bounds),
          child: Text(
            'Quên mật khẩu?',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              shadows: [
                Shadow(color: Colors.black87, offset: Offset(0, 0), blurRadius: 8),
                Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 4),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Nhập email của bạn, chúng tôi sẽ gửi link đặt lại mật khẩu',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.5), height: 1.5),
        ),
        const SizedBox(height: 32),

        // Email field
        _GlassTextField(
          controller: _emailCtrl,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          colors: _colors,
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorBox(message: _error!),
        ],

        const SizedBox(height: 24),

        // Submit button
        _GradBtn(
          text: 'Gửi link đặt lại',
          icon: Icons.send_rounded,
          colors: _colors,
          loading: _loading,
          onTap: _sendReset,
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('📬', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (b) => LinearGradient(colors: _colors).createShader(b),
          child: const Text('Đã gửi!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Link đặt lại mật khẩu đã được gửi đến\n${_emailCtrl.text.trim()}\n\nKiểm tra hộp thư (kể cả spam) và nhấn vào link.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.55), height: 1.7),
        ),
        const SizedBox(height: 32),
        _GradBtn(
          text: 'Quay lại đăng nhập',
          icon: Icons.arrow_back_rounded,
          colors: _colors,
          loading: false,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(height: 16),
        // Gửi lại
        GestureDetector(
          onTap: () => setState(() { _sent = false; }),
          child: Text(
            'Không nhận được? Gửi lại',
            style: TextStyle(fontSize: 14, color: _colors[0], fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Màn 2: Đặt lại mật khẩu mới (sau khi user bấm link trong email)
// Deep link → io.supabase.kltnapp://reset-password
// Supabase tự inject session, gọi màn này sau khi xác thực xong
// ─────────────────────────────────────────────────────────────
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading   = false;
  bool _obscure1  = true;
  bool _obscure2  = true;
  bool _done      = false;
  String? _error;

  late AnimationController _bgCtrl;
  final _colors = [const Color(0xFFFBBF24), const Color(0xFFF97316)];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final pass    = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (pass.length < 6) {
      setState(() => _error = 'Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() { _loading = true; _error = null; });
    HapticFeedback.mediumImpact();
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pass),
      );
      setState(() { _done = true; _loading = false; });
    } on AuthException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Đã có lỗi xảy ra. Thử lại.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _AuthBg(controller: _bgCtrl, colors: _colors),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _done ? _buildSuccess(context) : _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: _colors),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _colors[0].withOpacity(0.5), blurRadius: 24, spreadRadius: 3)],
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
          ),
          child: const Center(child: Text('🔒', style: TextStyle(fontSize: 36))),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (b) => LinearGradient(colors: _colors).createShader(b),
          child: const Text('Đặt lại mật khẩu',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Nhập mật khẩu mới cho tài khoản của bạn',
          style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.5)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        _GlassTextField(
          controller: _passCtrl,
          label: 'Mật khẩu mới',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscure1,
          colors: _colors,
          suffixIcon: IconButton(
            icon: Icon(_obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.black38, size: 20),
            onPressed: () => setState(() => _obscure1 = !_obscure1),
          ),
        ),
        const SizedBox(height: 14),
        _GlassTextField(
          controller: _confirmCtrl,
          label: 'Xác nhận mật khẩu',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscure2,
          colors: _colors,
          suffixIcon: IconButton(
            icon: Icon(_obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.black38, size: 20),
            onPressed: () => setState(() => _obscure2 = !_obscure2),
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorBox(message: _error!),
        ],

        const SizedBox(height: 24),
        _GradBtn(
          text: 'Cập nhật mật khẩu',
          icon: Icons.check_rounded,
          colors: _colors,
          loading: _loading,
          onTap: _updatePassword,
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('✅', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (b) => LinearGradient(colors: _colors).createShader(b),
          child: const Text('Thành công!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Mật khẩu đã được cập nhật.\nBạn có thể đăng nhập bằng mật khẩu mới.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.55), height: 1.7),
        ),
        const SizedBox(height: 32),
        _GradBtn(
          text: 'Về trang đăng nhập',
          icon: Icons.login_rounded,
          colors: _colors,
          loading: false,
          onTap: () {
            // Pop hết stack về AuthScreen
            Navigator.of(context).pushNamedAndRemoveUntil('/auth', (_) => false);
          },
        ),
      ],
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────

class _AuthBg extends StatelessWidget {
  final AnimationController controller;
  final List<Color> colors;
  const _AuthBg({required this.controller, required this.colors});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: colors, begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Stack(children: [
          Positioned(
            top: -100 + math.sin(controller.value * 2 * math.pi) * 50,
            left: -150 + math.cos(controller.value * 2 * math.pi) * 30,
            child: Container(width: 400, height: 400,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1))),
          ),
          Positioned(
            bottom: -50 + math.sin(controller.value * 2 * math.pi * -1) * 40,
            right: -100,
            child: Container(width: 300, height: 300,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08))),
          ),
        ]),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<Color> colors;
  final Widget? suffixIcon;

  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.colors,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.black.withOpacity(0.45), fontSize: 14),
          prefixIcon: Icon(icon, color: colors[0], size: 21),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }
}

class _GradBtn extends StatelessWidget {
  final String text;
  final IconData icon;
  final List<Color> colors;
  final bool loading;
  final VoidCallback onTap;

  const _GradBtn({required this.text, required this.icon, required this.colors, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity, height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [BoxShadow(color: colors[0].withOpacity(0.45), blurRadius: 22, offset: const Offset(0, 10))],
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisSize: MainAxisSize.min, children: [
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Icon(icon, color: Colors.white, size: 22),
          ]),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))),
      ]),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GlassBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}