// lib/core/app_env.dart
// Chạy bằng:
// flutter run --dart-define-from-file=..env.json
// Dựng giao diện:
// flutter build apk --release --dart-define-from-file=..env.json
// flutter build ios --release --dart-define-from-file=..env.json

class AppEnv {
  AppEnv._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  // Chỉ dùng anon key trong Flutter app.
  // TUYỆT ĐỐI không đưa service_role vào app.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static const String groqApiKey = String.fromEnvironment('GROQ_API_KEY');

  static const String groqChatUrl = String.fromEnvironment(
    'GROQ_CHAT_URL',
    defaultValue: 'https://api.groq.com/openai/v1/chat/completions',
  );

  static const String groqChatModel = String.fromEnvironment(
    'GROQ_CHAT_MODEL',
    defaultValue: 'llama-3.3-70b-versatile',
  );

  static const String groqVisionModel = String.fromEnvironment(
    'GROQ_VISION_MODEL',
    defaultValue: 'meta-llama/llama-4-scout-17b-16e-instruct',
  );

  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const String geminiUrl = String.fromEnvironment(
    'GEMINI_URL',
    defaultValue:
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
  );

  static const String clipDropApiKey = String.fromEnvironment(
    'CLIPDROP_API_KEY',
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasGroq => groqApiKey.isNotEmpty;

  static bool get hasGemini => geminiApiKey.isNotEmpty;

  static bool get hasClipDrop => clipDropApiKey.isNotEmpty;

  static void checkRequiredForAppStart() {
    final missing = <String>[];

    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');

    if (missing.isNotEmpty) {
      throw StateError('Thiếu biến môi trường: ${missing.join(', ')}');
    }
  }
}
