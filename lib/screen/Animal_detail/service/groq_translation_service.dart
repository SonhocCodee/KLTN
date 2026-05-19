import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service dịch fun_fact_vietnamese + description_short sang tiếng Anh
/// bằng Groq API (llama-3.1-8b-instant), sau đó UPDATE thẳng lên Supabase.
///
/// Flow:
///   1. Gọi [translateAndSave] từ AnimalDetailScreen sau khi load animal
///   2. Nếu fun_fact_english hoặc description_english còn null → gọi Groq
///   3. Parse JSON response → PATCH lên Supabase
///   4. Cập nhật map [animal] tại chỗ → UI tự setState mà không cần reload
class GroqTranslationService {
  // ── Groq ────────────────────────────────────────────────────────────────
  static const String _groqUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _groqKey =
      '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'; // TODO: chuyển sang --dart-define khi production
  static const String _groqModel = 'llama-3.1-8b-instant';

  // ── Supabase ─────────────────────────────────────────────────────────────
  static const String _supabaseUrl =
      'https://dnvlqnixommhjqwpflmw.supabase.co';
  static const String _supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudmxxbml4b21taGpxd3BmbG13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzMzE1MDEsImV4cCI6MjA4NTkwNzUwMX0.sz5oI5lhecJ0DCJNByI3CIHFICHh2PBt5FHnrMfmDaE';

  // ── Public entry point ───────────────────────────────────────────────────

  /// Kiểm tra xem animal có cần dịch không, nếu có thì dịch + lưu DB.
  /// [animal] là map trả về từ getAnimalById — sẽ được mutate tại chỗ
  /// để UI cập nhật ngay sau khi gọi setState().
  ///
  /// Trả về true nếu đã dịch thành công.
  Future<bool> translateAndSave(Map<String, dynamic> animal) async {
    final missingFunFact =
        (animal['fun_fact_english'] as String? ?? '').trim().isEmpty;
    final missingDesc =
        (animal['description_english'] as String? ?? '').trim().isEmpty;

    if (!missingFunFact && !missingDesc) return false; // Đã có hết, bỏ qua

    final funFactVi =
    (animal['fun_fact_vietnamese'] as String? ?? '').trim();
    final descVi =
    (animal['description_short'] as String? ?? '').trim();
    final nameEn =
    (animal['name_english'] as String? ?? 'this animal').trim();
    final id = animal['id'];

    if (funFactVi.isEmpty && descVi.isEmpty) return false; // Không có gì để dịch

    print('[Groq] Dịch "$nameEn" (id=$id)...');

    final result = await _callGroq(
      funFactVi: funFactVi,
      descVi: descVi,
      nameEn: nameEn,
    );

    if (result == null) return false;

    // Cập nhật map tại chỗ để UI dùng ngay
    if (missingFunFact) {
      animal['fun_fact_english'] = result['fun_fact_english'];
    }
    if (missingDesc) {
      animal['description_english'] = result['description_english'];
    }

    // Lưu lên Supabase (fire-and-forget, không block UI)
    _patchSupabase(
      id: id,
      funFactEnglish: missingFunFact ? result['fun_fact_english']! : null,
      descriptionEnglish:
      missingDesc ? result['description_english']! : null,
    );

    return true;
  }

  // ── Gọi Groq API ─────────────────────────────────────────────────────────

  Future<Map<String, String>?> _callGroq({
    required String funFactVi,
    required String descVi,
    required String nameEn,
  }) async {
    if (_groqKey == 'YOUR_GROQ_API_KEY') {
      print('[Groq] ⚠️ Chưa điền API key');
      return null;
    }

    final prompt = '''
Translate the following Vietnamese texts about "$nameEn" into natural, engaging English.
Return ONLY a valid JSON object with exactly these 2 keys, no explanation, no markdown:
{
  "fun_fact_english": "<translated fun fact>",
  "description_english": "<translated description>"
}

Vietnamese fun fact: $funFactVi
Vietnamese description: $descVi
''';

    try {
      final response = await http
          .post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqKey',
        },
        body: json.encode({
          'model': _groqModel,
          'max_tokens': 400,
          'temperature': 0.3,
          'messages': [
            {
              'role': 'system',
              'content':
              'You are a professional wildlife translator. Return only valid JSON, no extra text.',
            },
            {'role': 'user', 'content': prompt},
          ],
        }),
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('[Groq] ❌ ${response.statusCode}: ${response.body}');
        return null;
      }

      final data = json.decode(response.body);
      final content =
      data['choices'][0]['message']['content'] as String;

      // Strip markdown fences nếu model trả về ```json ... ```
      final clean = content
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      final parsed = json.decode(clean) as Map<String, dynamic>;

      final funFactEn = (parsed['fun_fact_english'] as String? ?? '').trim();
      final descEn =
      (parsed['description_english'] as String? ?? '').trim();

      if (funFactEn.isEmpty && descEn.isEmpty) return null;

      print('[Groq] ✅ Dịch thành công');
      return {
        'fun_fact_english': funFactEn,
        'description_english': descEn,
      };
    } catch (e) {
      print('[Groq] ❌ Exception: $e');
      return null;
    }
  }

  // ── PATCH lên Supabase ───────────────────────────────────────────────────

  Future<void> _patchSupabase({
    required dynamic id,
    String? funFactEnglish,
    String? descriptionEnglish,
  }) async {
    final body = <String, dynamic>{};
    if (funFactEnglish != null) body['fun_fact_english'] = funFactEnglish;
    if (descriptionEnglish != null) {
      body['description_english'] = descriptionEnglish;
    }
    if (body.isEmpty) return;

    try {
      final res = await http.patch(
        Uri.parse('$_supabaseUrl/rest/v1/animals?id=eq.$id'),
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: json.encode(body),
      );

      if (res.statusCode == 204) {
        print('[Groq] 💾 Đã lưu bản dịch lên Supabase (id=$id)');
      } else {
        print('[Groq] ⚠️ PATCH thất bại ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      print('[Groq] ⚠️ PATCH exception: $e');
    }
  }
}