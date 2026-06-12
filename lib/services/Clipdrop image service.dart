import 'dart:convert';
import 'package:http/http.dart' as http;

// Service xử lý ảnh qua ClipDrop Uncrop API
// Đã sửa lỗi tham số target_width/height gây lỗi 400
class ClipDropImageService {
  // 🔑 API KEY CỦA BẠN (Đã điền sẵn)
  static const String _apiKey =
      '7025151cda06e32fd33057885c49b51d5fd770cf7444d0537de31853e32f1182c9a034f88b2c28f5105fb8be84e5ee99';

  // ClipDrop Uncrop API endpoint
  static const String _uncropUrl = 'https://clipdrop-api.co/uncrop/v1';

  static Future<String?> extendAnimalImage({
    required String originalImageUrl,
    // Giữ tham số này để code gọi hàm không bị lỗi, nhưng ta sẽ dùng logic extend bên dưới
    int targetWidth = 1080,
    int targetHeight = 1920,
  }) async {
    // 1. Validate API Key
    if (_apiKey.isEmpty || _apiKey.contains('YOUR_API_KEY')) {
      print('❌ [ClipDrop] Chưa cấu hình API key!');
      return null;
    }

    try {
      // Download ảnh gốc từ URL
      print('📥 [ClipDrop] Downloading original image...');

      final imageResponse = await http.get(Uri.parse(originalImageUrl));

      if (imageResponse.statusCode != 200) {
        print(
          '❌ [ClipDrop] Failed to download image: ${imageResponse.statusCode}',
        );
        return null;
      }

      final imageBytes = imageResponse.bodyBytes;

      // Gọi ClipDrop Uncrop API
      print('🚀 [ClipDrop] Calling Uncrop API...');

      var request = http.MultipartRequest('POST', Uri.parse(_uncropUrl));
      request.headers['x-api-key'] = _apiKey;

      request.files.add(
        http.MultipartFile.fromBytes(
          'image_file',
          imageBytes,
          filename: 'original.jpg',
        ),
      );

      // 🛠️ QUAN TRỌNG: Sửa lỗi 400 tại đây
      // API Uncrop không nhận target_width, nó cần biết mở rộng hướng nào.
      // Để tạo hình nền điện thoại (dọc), ta mở rộng thêm 600px lên trên và xuống dưới.
      request.fields['extend_up'] = '600';
      request.fields['extend_down'] = '600';
      request.fields['extend_left'] = '0';
      request.fields['extend_right'] = '0';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Xử lý kết quả

      if (response.statusCode == 200) {
        print('✅ [ClipDrop] Thành công! Đã nhận ảnh.');
        // Convert ảnh binary sang Base64 để hiển thị
        final base64Image = base64Encode(response.bodyBytes);
        return 'data:image/png;base64,$base64Image';
      } else {
        print('❌ [ClipDrop] Lỗi API: ${response.statusCode}');
        print('   Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ [ClipDrop] Exception: $e');
      return null;
    }
  }

  // Hàm kiểm tra key (optional)
  static Future<bool> validateApiKey() async {
    if (_apiKey.isEmpty || _apiKey.contains('YOUR_API_KEY')) {
      return false;
    }
    return true;
  }
}
