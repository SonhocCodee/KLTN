import 'dart:math' as math;
import 'dart:async'; // Đã thêm thư viện này để dùng StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Forgot password screen.dart';
import 'auth_service.dart';
import '../home/home_wrapper.dart';

// ── Entry point ───────────────────────────────────────────────
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {

  late AnimationController _bgController;
  late AnimationController _formController;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  bool _isLogin = true;

  // Biến lắng nghe trạng thái đăng nhập của Supabase
  late final StreamSubscription<AuthState> _authSubscription;

  // Gradient màu vàng-cam giống trang 4 onboarding (trang "Sẵn sàng")
  final List<Color> _gradientColors = [
    const Color(0xFFFBBF24),
    const Color(0xFFF97316),
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _formFade  = CurvedAnimation(parent: _formController, curve: Curves.easeOut);
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _formController, curve: Curves.easeOut));

    _formController.forward();

    // ── LẮNG NGHE TRẠNG THÁI ĐĂNG NHẬP (AUTO-LOGIN & REDIRECT) ──
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      // 1. Nếu user bấm link Quên mật khẩu từ Email -> Mở trang ResetPasswordScreen
      if (event == AuthChangeEvent.passwordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
            );
          }
        });
      }
      // 2. Nếu vừa mở app hoặc login thành công -> Vào thẳng Home
      else if ((event == AuthChangeEvent.initialSession || event == AuthChangeEvent.signedIn) && session != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeWrapper()),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // Huỷ lắng nghe để tránh rò rỉ bộ nhớ
    _authSubscription.cancel();

    _bgController.dispose();
    _formController.dispose();
    super.dispose();
  }

  void _switchMode() {
    _formController.reset();
    setState(() => _isLogin = !_isLogin);
    _formController.forward();
  }

  void _onLoginSuccess() {

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background động (giống onboarding) ──────────────
          _AuthBackground(controller: _bgController, colors: _gradientColors),

          // ── Particle dấu chân ───────────────────────────────
          _AuthParticles(color: _gradientColors[0]),

          // ── Nội dung ─────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _formFade,
              child: SlideTransition(
                position: _formSlide,
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    // Icon + tiêu đề
                    _buildHeader(),
                    const SizedBox(height: 32),
                    // Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: _isLogin
                            ? _LoginForm(
                          gradientColors: _gradientColors,
                          onSuccess: _onLoginSuccess,
                          onSwitchMode: _switchMode,
                        )
                            : _RegisterForm(
                          gradientColors: _gradientColors,
                          onSuccess: _onLoginSuccess,
                          onSwitchMode: _switchMode,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Icon chính với hiệu ứng glow
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _gradientColors[0].withOpacity(0.5),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
          ),
          child: const Center(
            child: Text('🐾', style: TextStyle(fontSize: 40)),
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: _gradientColors,
          ).createShader(bounds),
          child: Text(
            _isLogin ? 'Chào mừng trở lại!' : 'Tạo tài khoản',
            style: const TextStyle(
              fontSize: 28,
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
        const SizedBox(height: 6),
        Text(
          _isLogin
              ? 'Đăng nhập để sử dụng đầy đủ các tính năng'
              : 'Tham gia cùng hàng nghìn người yêu động vật',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Login Form ────────────────────────────────────────────────
class _LoginForm extends StatefulWidget {
  final List<Color> gradientColors;
  final VoidCallback onSuccess;
  final VoidCallback onSwitchMode;

  const _LoginForm({
    required this.gradientColors,
    required this.onSuccess,
    required this.onSwitchMode,
  });

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading     = false;
  bool _obscure     = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    HapticFeedback.mediumImpact();
    try {
      await AuthService.signInWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      widget.onSuccess();
    } on AuthException catch (e) {
      setState(() { _error = _mapError(e.message); _loading = false; });
    } catch (e) {
      setState(() { _error = 'Đã có lỗi xảy ra. Vui lòng thử lại.'; _loading = false; });
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.signInWithGoogle();
      // Kết quả sẽ được xử lý qua authStateStream listener ở màn hình chính
    } catch (e) {
      setState(() { _error = 'Đăng nhập Google thất bại.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AuthTextField(
          controller: _emailCtrl,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          gradientColors: widget.gradientColors,
        ),
        const SizedBox(height: 14),
        _AuthTextField(
          controller: _passwordCtrl,
          label: 'Mật khẩu',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscure,
          gradientColors: widget.gradientColors,
          suffixIcon: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.black38, size: 20,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Quên mật khẩu?',
                  style: TextStyle(fontSize: 13, color: widget.gradientColors[0], fontWeight: FontWeight.w600)),
            ),
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorBox(message: _error!),
        ],

        const SizedBox(height: 24),

        // Nút đăng nhập
        _GradientButton(
          text: 'Đăng nhập',
          icon: Icons.arrow_forward_rounded,
          colors: widget.gradientColors,
          loading: _loading,
          onTap: _submit,
        ),

        const SizedBox(height: 16),

        // Divider
        Row(children: [
          Expanded(child: Divider(color: Colors.black.withOpacity(0.15))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('hoặc', style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 13)),
          ),
          Expanded(child: Divider(color: Colors.black.withOpacity(0.15))),
        ]),

        const SizedBox(height: 16),

        // Google
        _GoogleButton(loading: _loading, onTap: _googleSignIn),

        const SizedBox(height: 24),

        // Switch sang register
        GestureDetector(
          onTap: widget.onSwitchMode,
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.5)),
              children: [
                const TextSpan(text: 'Chưa có tài khoản? '),
                TextSpan(
                  text: 'Đăng ký ngay',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: widget.gradientColors[0],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Register Form ─────────────────────────────────────────────
class _RegisterForm extends StatefulWidget {
  final List<Color> gradientColors;
  final VoidCallback onSuccess;
  final VoidCallback onSwitchMode;

  const _RegisterForm({
    required this.gradientColors,
    required this.onSuccess,
    required this.onSwitchMode,
  });

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng nhập tên hiển thị');
      return;
    }
    setState(() { _loading = true; _error = null; });
    HapticFeedback.mediumImpact();
    try {
      await AuthService.signUpWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        displayName: _nameCtrl.text.trim(),
      );
      widget.onSuccess();
    } on AuthException catch (e) {
      setState(() { _error = _mapError(e.message); _loading = false; });
    } catch (e) {
      setState(() { _error = 'Đã có lỗi xảy ra. Vui lòng thử lại.'; _loading = false; });
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.signInWithGoogle();
      // Chờ Listener xử lý chuyển trang
    } catch (e) {
      setState(() { _error = 'Đăng nhập Google thất bại.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AuthTextField(
          controller: _nameCtrl,
          label: 'Tên hiển thị',
          icon: Icons.person_outline_rounded,
          gradientColors: widget.gradientColors,
        ),
        const SizedBox(height: 14),
        _AuthTextField(
          controller: _emailCtrl,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          gradientColors: widget.gradientColors,
        ),
        const SizedBox(height: 14),
        _AuthTextField(
          controller: _passwordCtrl,
          label: 'Mật khẩu (ít nhất 6 ký tự)',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscure,
          gradientColors: widget.gradientColors,
          suffixIcon: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.black38, size: 20,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorBox(message: _error!),
        ],

        const SizedBox(height: 24),

        _GradientButton(
          text: 'Đăng ký',
          icon: Icons.check_rounded,
          colors: widget.gradientColors,
          loading: _loading,
          onTap: _submit,
        ),

        const SizedBox(height: 16),

        Row(children: [
          Expanded(child: Divider(color: Colors.black.withOpacity(0.15))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('hoặc', style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 13)),
          ),
          Expanded(child: Divider(color: Colors.black.withOpacity(0.15))),
        ]),

        const SizedBox(height: 16),
        _GoogleButton(loading: _loading, onTap: _googleSignIn),

        const SizedBox(height: 24),

        GestureDetector(
          onTap: widget.onSwitchMode,
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.5)),
              children: [
                const TextSpan(text: 'Đã có tài khoản? '),
                TextSpan(
                  text: 'Đăng nhập',
                  style: TextStyle(fontWeight: FontWeight.w700, color: widget.gradientColors[0]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<Color> gradientColors;
  final Widget? suffixIcon;

  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.gradientColors,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.black.withOpacity(0.45), fontSize: 14),
          prefixIcon: Icon(icon, color: gradientColors[0], size: 21),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final List<Color> colors;
  final bool loading;
  final VoidCallback onTap;

  const _GradientButton({
    required this.text,
    required this.icon,
    required this.colors,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.45),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Icon(icon, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _GoogleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('G', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFEA4335))),
            const SizedBox(width: 10),
            Text('Tiếp tục với Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black.withOpacity(0.7))),
          ],
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
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))),
        ],
      ),
    );
  }
}

// ── Background giống onboarding ──────────────────────────────
class _AuthBackground extends StatelessWidget {
  final AnimationController controller;
  final List<Color> colors;

  const _AuthBackground({required this.controller, required this.colors});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
        ),
        child: Stack(children: [
          Positioned(
            top: -100 + math.sin(controller.value * 2 * math.pi) * 50,
            left: -150 + math.cos(controller.value * 2 * math.pi) * 30,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
            ),
          ),
          Positioned(
            bottom: -50 + math.sin(controller.value * 2 * math.pi * -1) * 40,
            right: -100 + math.cos(controller.value * 2 * math.pi * -1) * 25,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Particle dấu chân nhẹ ────────────────────────────────────
class _AuthParticles extends StatefulWidget {
  final Color color;
  const _AuthParticles({required this.color});

  @override
  State<_AuthParticles> createState() => _AuthParticlesState();
}

class _AuthParticlesState extends State<_AuthParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _PawPainter(progress: _ctrl.value, color: widget.color),
        size: Size.infinite,
      ),
    );
  }
}

class _PawPainter extends CustomPainter {
  final double progress;
  final Color color;
  static final _rng = math.Random(42);
  static final _particles = List.generate(15, (i) => [
    _rng.nextDouble(), _rng.nextDouble(),
    _rng.nextDouble() * 0.008 - 0.004,
    _rng.nextDouble() * 0.004,
    4 + _rng.nextDouble() * 5,
    _rng.nextDouble() * 0.25 + 0.05,
  ]);

  _PawPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final x = ((p[0] + progress * p[2] * 10) % 1.2 - 0.1) * size.width;
      final y = ((p[1] - progress * p[3] * 5) % 1.2 - 0.1) * size.height;
      final r = p[4] as double;
      final paint = Paint()..color = color.withOpacity(p[5] as double);
      canvas.save();
      canvas.translate(x, y);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 2.2, height: r * 1.8), paint);
      canvas.drawCircle(Offset(-r * 0.8, -r * 1.4), r * 0.7, paint);
      canvas.drawCircle(Offset(0, -r * 1.2 * 1.2), r * 0.7, paint);
      canvas.drawCircle(Offset(r * 0.8, -r * 1.4), r * 0.7, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PawPainter old) => true;
}

// ── Helper: map lỗi Supabase sang tiếng Việt ─────────────────
String _mapError(String msg) {
  if (msg.contains('Invalid login credentials')) return 'Email hoặc mật khẩu không đúng.';
  if (msg.contains('Email not confirmed'))        return 'Vui lòng xác nhận email trước khi đăng nhập.';
  if (msg.contains('User already registered'))    return 'Email này đã được đăng ký.';
  if (msg.contains('Password should be'))         return 'Mật khẩu phải có ít nhất 6 ký tự.';
  if (msg.contains('Unable to validate'))         return 'Email không hợp lệ.';
  return msg;
}