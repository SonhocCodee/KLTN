import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class SharedImageCacheService {
  static final _supabase = Supabase.instance.client;

  // Tên table trong Supabase DB (tạo bên dưới)
  static const String _table = 'daily_animal_image_cache';

  // Tên bucket trong Supabase Storage
  static const String _bucket = 'animal-images';

  /// Lấy URL ảnh đã extend từ shared cache (Supabase)
  /// Trả về null nếu chưa có cache hôm nay
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

  /// Upload ảnh lên Supabase Storage và lưu URL vào DB
  /// Gọi sau khi ClipDrop trả về bytes ảnh
  static Future<String?> uploadAndSaveSharedCache({
    required String originalImageUrl,
    required Uint8List imageBytes,
    required String animalName,
  }) async {
    final today = _todayString();

    try {
      // 1. Upload ảnh lên Supabase Storage
      final fileName = 'daily_${today}_${animalName.replaceAll(' ', '_').toLowerCase()}.png';
      final storagePath = 'extended/$fileName';

      print('📤 [SharedCache] Uploading to Supabase Storage: $storagePath');

      await _supabase.storage.from(_bucket).uploadBinary(
        storagePath,
        imageBytes,
        fileOptions: const FileOptions(
          contentType: 'image/png',
          upsert: true, // Ghi đè nếu đã tồn tại
        ),
      );

      // 2. Lấy public URL
      final publicUrl = _supabase.storage.from(_bucket).getPublicUrl(storagePath);
      print('✅ [SharedCache] Upload thành công: $publicUrl');

      // 3. Lưu URL vào DB
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
