import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Cache service cho ảnh đã extend
///
/// Lưu mapping: originalImageUrl -> extendedImageUrl
/// Mỗi ngày sẽ cache 1 ảnh mới (con vật mới)
class ExtendedImageCache {
  static const String _cachePrefix = 'extended_image_';
  static const String _cacheDateKey = 'extended_image_date';

  /// Lưu URL ảnh đã extend
  static Future<void> saveExtendedImage({
    required String originalUrl,
    required String extendedUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Tạo cache key từ original URL
    final cacheKey = _cachePrefix + _hashUrl(originalUrl);

    await prefs.setString(cacheKey, json.encode({
      'originalUrl': originalUrl,
      'extendedUrl': extendedUrl,
      'cachedAt': today,
    }));

    await prefs.setString(_cacheDateKey, today);

    print('💾 [Cache] Đã lưu ảnh extended: $cacheKey');
  }

  /// Lấy URL ảnh đã extend (nếu có)
  static Future<String?> getExtendedImage(String originalUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDate = prefs.getString(_cacheDateKey);
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Kiểm tra xem cache có phải của hôm nay không
    if (cachedDate != today) {
      print('🗑️ [Cache] Cache cũ (ngày $cachedDate), xóa...');
      await clearCache();
      return null;
    }

    final cacheKey = _cachePrefix + _hashUrl(originalUrl);
    final cachedData = prefs.getString(cacheKey);

    if (cachedData == null) {
      print('❌ [Cache] Không tìm thấy cache cho: $cacheKey');
      return null;
    }

    try {
      final data = json.decode(cachedData);
      final extendedUrl = data['extendedUrl'] as String;

      print('✅ [Cache] Tìm thấy ảnh extended: $extendedUrl');
      return extendedUrl;
    } catch (e) {
      print('❌ [Cache] Lỗi parse cache: $e');
      return null;
    }
  }

  /// Xóa cache (khi sang ngày mới)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();

    // Xóa tất cả key bắt đầu bằng _cachePrefix
    final allKeys = prefs.getKeys();
    final keysToRemove = allKeys.where((key) => key.startsWith(_cachePrefix));

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }

    await prefs.remove(_cacheDateKey);
    print('🗑️ [Cache] Đã xóa toàn bộ cache cũ');
  }

  /// Hash URL để tạo cache key ngắn gọn
  static String _hashUrl(String url) {
    return url.hashCode.abs().toString();
  }

  /// Kiểm tra xem có cache hợp lệ không
  static Future<bool> hasCacheForToday() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDate = prefs.getString(_cacheDateKey);
    final today = DateTime.now().toIso8601String().split('T')[0];

    return cachedDate == today;
  }
}