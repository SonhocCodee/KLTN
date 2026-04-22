import 'package:supabase_flutter/supabase_flutter.dart';

class AnimalReportService {
  final _db = Supabase.instance.client;

  /// Gửi report từ người dùng (có hoặc không đăng nhập)
  Future<void> submitReport({
    required String animalId,
    String? reporterName,
    String? reporterEmail,
    String? suggestedNameVi,
    String? suggestedNameEn,
    String? suggestedScientificName,
    String? suggestedDescription,
    String? suggestedFunFact,
    String? suggestedImageUrl,
    Map<String, dynamic>? suggestedFields,
    String? note,
  }) async {
    final user = _db.auth.currentUser;

    await _db.from('animal_reports').insert({
      'animal_id': animalId,
      'reporter_name': reporterName,
      'reporter_email': reporterEmail,
      'reporter_user_id': user?.id,
      'suggested_name_vietnamese': suggestedNameVi,
      'suggested_name_english': suggestedNameEn,
      'suggested_scientific_name': suggestedScientificName,
      'suggested_description_short': suggestedDescription,
      'suggested_fun_fact_vietnamese': suggestedFunFact,
      'suggested_image_url': suggestedImageUrl,
      'suggested_fields': suggestedFields ?? {},
      'note': note,
    });
  }
}