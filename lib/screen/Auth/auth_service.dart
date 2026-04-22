import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  static Stream<AuthState> get authStateStream =>
      _client.auth.onAuthStateChange;

  // ── Email + Password ─────────────────────────────────────
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': displayName},
    );
  }

  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ── Google Sign-In ───────────────────────────────────────
  static Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.kltnapp://login-callback',
    );
  }

  // ── Sign Out ─────────────────────────────────────────────
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── User Profile ─────────────────────────────────────────
  static Future<Map<String, dynamic>?> getProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
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
    if (uid == null) return;
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
    if (uid == null) return null;
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
    if (uid == null) return;
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