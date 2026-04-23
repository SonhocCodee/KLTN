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

    // ── Lấy thông tin user từ auth nếu đã đăng nhập ──────────
    final meta            = user?.userMetadata;
    final userDisplayName = meta?['full_name'] as String?;
    final userEmail       = user?.email;
    final userAvatarUrl   = meta?['avatar_url'] as String?;

    // Ưu tiên: nếu đã đăng nhập thì dùng thông tin từ tài khoản,
    // nếu không thì dùng thông tin người dùng nhập (anonymous)
    final finalName  = userDisplayName ?? reporterName;
    final finalEmail = userEmail ?? reporterEmail;

    await _db.from('animal_reports').insert({
      'animal_id': animalId,

      // Thông tin người báo cáo – merge giữa account info và manual input
      'reporter_name':    finalName,
      'reporter_email':   finalEmail,
      'reporter_user_id': user?.id,

      // Thông tin profile đầy đủ (để hiển thị trên dashboard)
      'reporter_display_name': userDisplayName,  // tên từ account
      'reporter_avatar_url':   userAvatarUrl,    // avatar từ account
      'is_authenticated':      user != null,     // đánh dấu đã đăng nhập hay chưa

      // Các trường đề xuất sửa
      'suggested_name_vietnamese':    suggestedNameVi,
      'suggested_name_english':       suggestedNameEn,
      'suggested_scientific_name':    suggestedScientificName,
      'suggested_description_short':  suggestedDescription,
      'suggested_fun_fact_vietnamese': suggestedFunFact,
      'suggested_image_url':          suggestedImageUrl,
      'suggested_fields':             suggestedFields ?? {},
      'note': note,
    });
  }
}