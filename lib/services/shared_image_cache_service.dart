import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class SharedImageCacheService {
  // Dùng getter thay vì static final
  // static final chạy ngay khi class được load -> crash vì Supabase chưa init
  // getter chỉ gọi Supabase.instance.client khi hàm thực sự được gọi
  static SupabaseClient get _supabase => Supabase.instance.client;

  static const String _table = 'daily_animal_image_cache';
  static const String _bucket = 'animal-images';

  // Lấy URL ảnh đã extend từ shared cache (Supabase)
  // Trả về null nếu chưa có cache hôm nay
  static Future<String?> getSharedCachedImage(String originalImageUrl) async {
    final today = _todayString();

    try {
      final response = await _supabase
          .from(_table)
          .select('extended_image_url')
          .eq('cache_date', today)
          .eq('original_image_url', originalImageUrl)
          .maybeSingle();

      if (response == null) {
        print('🌐 [SharedCache] Chưa có cache hôm nay ($today)');
        return null;
      }

      final url = response['extended_image_url'] as String?;
      print('✅ [SharedCache] Tìm thấy shared cache: $url');
      return url;
    } catch (e) {
      print('❌ [SharedCache] Lỗi đọc cache: $e');
      return null;
    }
  }

  // Upload ảnh lên Supabase Storage và lưu URL vào DB
  static Future<String?> uploadAndSaveSharedCache({
    required String originalImageUrl,
    required Uint8List imageBytes,
    required String animalName,
  }) async {
    final today = _todayString();

    try {
      final fileName =
          'daily_${today}_${animalName.replaceAll(' ', '_').toLowerCase()}.png';
      final storagePath = 'extended/$fileName';

      print('📤 [SharedCache] Uploading to Supabase Storage: $storagePath');

      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            storagePath,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from(_bucket)
          .getPublicUrl(storagePath);
      print('✅ [SharedCache] Upload thành công: $publicUrl');

      await _supabase.from(_table).upsert({
        'cache_date': today,
        'original_image_url': originalImageUrl,
        'extended_image_url': publicUrl,
        'animal_name': animalName,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'cache_date,original_image_url');

      print('💾 [SharedCache] Đã lưu vào DB');
      return publicUrl;
    } catch (e) {
      print('❌ [SharedCache] Lỗi upload: $e');
      return null;
    }
  }

  static String _todayString() {
    return DateTime.now().toIso8601String().split('T')[0];
  }
}
