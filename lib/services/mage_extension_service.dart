import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ImageExtensionService {
  // API Keys
  static const String _geminiApiKey = 'AIzaSyCKfe1_udVnevaU1c0Ta5BH_CN7j8a5xSI';

  // OPTION 1: Gemini Imagen API
  static const String _geminiImagenUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-001:predict';

  /// Mở rộng ảnh qua Gemini Imagen
  ///
  /// Input: URL ảnh gốc (ví dụ: 800x600px)
  /// Output: URL ảnh đã mở rộng (1080x1920px - full phone screen)
  ///
  /// Gemini sẽ:
  /// - Phân tích con vật trong ảnh
  /// - Giữ nguyên con vật ở center
  /// - Điền background tự nhiên xung quanh
  static Future<String?> extendImageWithGemini(String originalImageUrl) async {
    print('🎨 Bắt đầu extend ảnh qua Gemini...');

    try {
      // 1. Download ảnh gốc
      print('📥 Download ảnh gốc: $originalImageUrl');
      final response = await http.get(Uri.parse(originalImageUrl));
      if (response.statusCode != 200) {
        print('❌ Không tải được ảnh gốc');
        return null;
      }

      final Uint8List imageBytes = response.bodyBytes;
      final String base64Image = base64Encode(imageBytes);

      print('✅ Đã encode ảnh sang base64 (${imageBytes.length} bytes)');

      // 2. Gọi Gemini Imagen API
      final prompt = '''
Extend this animal image to fill a mobile phone screen (1080x1920px portrait).
Keep the animal in the center-bottom position.
Generate natural background that matches the animal's habitat.
Maintain photorealistic quality.
''';

      print('🤖 Gọi Gemini API với prompt...');

      final apiResponse = await http.post(
        Uri.parse('$_geminiImagenUrl?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'instances': [
            {
              'prompt': prompt,
              'image': {
                'bytesBase64Encoded': base64Image,
              },
              'parameters': {
                'sampleCount': 1,
                'aspectRatio': '9:16', // Portrait phone
                'targetWidth': 1080,
                'targetHeight': 1920,
                'mode': 'outpainting', // Mở rộng ảnh
              }
            }
          ]
        }),
      );

      if (apiResponse.statusCode == 200) {
        final data = json.decode(apiResponse.body);

        // 3. Lấy ảnh đã extend
        final extendedImageBase64 = data['predictions'][0]['bytesBase64Encoded'];

        // 4. Upload lên storage hoặc convert sang URL
        // (Tạm thời return base64, sau này upload lên Supabase Storage)
        print('✅ Gemini trả về ảnh mới!');
        return 'data:image/jpeg;base64,$extendedImageBase64';

      } else {
        print('❌ Gemini API Error: ${apiResponse.statusCode}');
        print('Body: ${apiResponse.body}');
        return null;
      }

    } catch (e) {
      print('❌ Exception: $e');
      return null;
    }
  }
  // OPTION 2: AI Local (nếu bạn có model local)
  /// Gọi AI model local của bạn để extend ảnh
  ///
  /// Endpoint: http://localhost:5000/extend-image
  /// Method: POST
  /// Body: { "image_url": "...", "target_width": 1080, "target_height": 1920 }
  static Future<String?> extendImageWithLocalAI(
      String originalImageUrl,
      String localAIEndpoint,
      ) async {
    print('🏠 Gọi Local AI: $localAIEndpoint');

    try {
      final response = await http.post(
        Uri.parse(localAIEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'image_url': originalImageUrl,
          'target_width': 1080,
          'target_height': 1920,
          'mode': 'outpainting',
          'keep_subject_position': 'center-bottom', // Con vật ở dưới giữa
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final extendedImageUrl = data['extended_image_url'];

        print('✅ Local AI trả về: $extendedImageUrl');
        return extendedImageUrl;
      } else {
        print('❌ Local AI Error: ${response.statusCode}');
        return null;
      }

    } catch (e) {
      print('❌ Local AI Exception: $e');
      return null;
    }
  }

  // WRAPPER: Auto chọn method
  /// Tự động chọn Gemini hoặc Local AI dựa vào config
  static Future<String?> extendImage({
    required String originalImageUrl,
    bool useLocalAI = false,
    String? localAIEndpoint,
  }) async {
    print('🎯 Bắt đầu extend ảnh...');
    print('   - Ảnh gốc: $originalImageUrl');
    print('   - Dùng Local AI: $useLocalAI');

    if (useLocalAI && localAIEndpoint != null) {
      return await extendImageWithLocalAI(originalImageUrl, localAIEndpoint);
    } else {
      return await extendImageWithGemini(originalImageUrl);
    }
  }
}
