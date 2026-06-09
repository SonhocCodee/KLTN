import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class AuthService {
  static final _client = Supabase.instance.client;
  static const _guestKey = 'is_guest';

  static User? get currentUser => _client.auth.currentUser;

  /// Có session Supabase hay không.
  /// Lưu ý: guest mode không được tính là user thật để dùng Profile/Quiz.
  static bool get isLoggedIn => currentUser != null;

  /// User thật để dùng các tính năng cần tài khoản.
  static bool get isAuthenticatedUser => currentUser != null && !_isGuest;

  static Stream<AuthState> get authStateStream =>
      _client.auth.onAuthStateChange;

  // ── Guest Mode (persist qua SharedPreferences) ───────────────
  static bool _isGuest = false;

  static bool get isGuest => _isGuest;

  /// Gọi trong main() trước runApp để load trạng thái guest
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool(_guestKey) ?? false;
  }

  static Future<void> continueAsGuest() async {
    // Nếu máy còn session Supabase cũ thì xoá đi, tránh Profile tưởng là đã đăng nhập.
    try {
      if (_client.auth.currentSession != null) {
        await _client.auth.signOut();
      }
    } catch (_) {
      // Bỏ qua lỗi signOut khi không có session hợp lệ.
    }

    _isGuest = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, true);
  }

  /// Gọi ngay sau khi đăng nhập thành công để thoát guest mode.
  static Future<void> markLoggedIn() async {
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestKey);
  }

  static Future<void> _clearGuestMode() => markLoggedIn();

  // ── Email + Password ─────────────────────────────────────
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': displayName},
    );

    await _clearGuestMode();
    return res;
  }

  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    await _clearGuestMode();
    return res;
  }

  // ── Google Sign-In ───────────────────────────────────────
  static Future<bool> signInWithGoogle() async {
    final res = await _client.auth.getOAuthSignInUrl(
      provider: OAuthProvider.google,
      redirectTo: 'io.supabase.kltnapp://login-callback',
    );

    final result = await FlutterWebAuth2.authenticate(
      url: res.url.toString(),
      callbackUrlScheme: 'io.supabase.kltnapp',
    );

    final uri = Uri.parse(result);
    await _client.auth.getSessionFromUrl(uri);
    await _clearGuestMode();
    return true;
  }

  // ── Sign Out ─────────────────────────────────────────────
  static Future<void> signOut() async {
    await _clearGuestMode();
    await _client.auth.signOut();
  }

  // ── User Profile ─────────────────────────────────────────
  static Future<Map<String, dynamic>?> getProfile() async {
    final uid = currentUser?.id;
    if (uid == null || _isGuest) return null;

    final data = await _client
        .from('user_profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    return data;
  }

  static Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final uid = currentUser?.id;
    if (uid == null || _isGuest) return;

    await _client.from('user_profiles').upsert({
      'id': uid,
      if (displayName != null) 'display_name': displayName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });
  }

  // ── Quiz Progress ────────────────────────────────────────
  static Future<Map<String, dynamic>?> getTodayQuiz() async {
    final uid = currentUser?.id;
    if (uid == null || _isGuest) return null;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await _client
        .from('quiz_progress')
        .select()
        .eq('user_id', uid)
        .eq('quiz_date', today)
        .maybeSingle();
  }

  static Future<void> saveQuizProgress({
    required int score,
    required int total,
    required List<Map<String, dynamic>> answers,
    bool completed = false,
  }) async {
    final uid = currentUser?.id;
    if (uid == null || _isGuest) return;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _client.from('quiz_progress').upsert({
      'user_id': uid,
      'quiz_date': today,
      'score': score,
      'total': total,
      'answers': answers,
      'completed': completed,
      if (completed) 'completed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,quiz_date');
  }
}
