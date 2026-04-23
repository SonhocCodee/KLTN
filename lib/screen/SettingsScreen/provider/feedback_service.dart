import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackService {
  final _db = Supabase.instance.client;

  /// Upload file (ảnh hoặc video) lên Supabase Storage bucket 'feedback-media'
  /// Trả về public URL
  Future<String?> uploadMedia(File file, String fileName) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      final path = 'feedback/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _db.storage.from('feedback-media').upload(
        path,
        file,
        fileOptions: FileOptions(
          contentType: _mimeType(ext),
          upsert: false,
        ),
      );

      final url = _db.storage.from('feedback-media').getPublicUrl(path);
      return url;
    } catch (e) {
      return null;
    }
  }

  String _mimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png':  return 'image/png';
      case 'gif':  return 'image/gif';
      case 'webp': return 'image/webp';
      case 'mp4':  return 'video/mp4';
      case 'mov':  return 'video/quicktime';
      case 'avi':  return 'video/avi';
      default:     return 'application/octet-stream';
    }
  }

  /// Gửi góp ý / báo lỗi vào bảng app_feedbacks
  Future<void> submitFeedback({
    required String type,          // 'bug' | 'suggestion' | 'other'
    required String description,
    List<String> mediaUrls = const [],
    String? contactEmail,
    String? contactName,
  }) async {
    final user = _db.auth.currentUser;

    // Lấy thêm display_name từ user metadata nếu đã đăng nhập
    final meta = user?.userMetadata;
    final userDisplayName = meta?['full_name'] as String?;
    final userEmail = user?.email;
    final userAvatarUrl = meta?['avatar_url'] as String?;

    await _db.from('app_feedbacks').insert({
      // Loại và nội dung
      'type': type,
      'description': description,
      'media_urls': mediaUrls,

      // Thông tin liên hệ (người dùng nhập thêm nếu muốn)
      'contact_name': contactName,
      'contact_email': contactEmail,

      // Thông tin từ tài khoản (nếu đã đăng nhập)
      'user_id': user?.id,
      'user_display_name': userDisplayName,
      'user_email': userEmail,
      'user_avatar_url': userAvatarUrl,

      // Status ban đầu
      'status': 'new',
    });
  }
}