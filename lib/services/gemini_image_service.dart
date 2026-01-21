import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GeminiImageService {
  // PASTE API KEY CỦA BẠN VÀO ĐÂY ↓
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';

  // Gemini API endpoint cho image generation
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Mở rộng ảnh động vật qua Gemini
  ///
  /// Gemini sẽ:
  /// 1. Phân tích ảnh gốc
  /// 2. Nhận diện con vật
  /// 3. Tạo prompt mô tả để extend
  /// 4. Generate ảnh mới với background tự nhiên
  static Future<String?> extendAnimalImage({
    required String originalImageUrl,
    required String animalName,
    int targetWidth = 1080,
    int targetHeight = 1920,
  }) async {
    print('🎨 [Gemini] Bắt đầu extend ảnh cho: $animalName');
    print('   - Ảnh gốc: $originalImageUrl');
    print('   - Target size: ${targetWidth}x$targetHeight');

    try {
      // BƯỚC 1: Download ảnh gốc
      print('📥 [Gemini] Downloading original image...');
      final imageResponse = await http.get(Uri.parse(originalImageUrl));

      if (imageResponse.statusCode != 200) {
        print('❌ [Gemini] Failed to download image: ${imageResponse.statusCode}');
        return null;
      }

      final Uint8List imageBytes = imageResponse.bodyBytes;
      final String base64Image = base64Encode(imageBytes);

      print('✅ [Gemini] Image encoded: ${imageBytes.length} bytes');

      // BƯỚC 2: Tạo prompt thông minh
      final prompt = _generateExtensionPrompt(animalName, targetWidth, targetHeight);
      print('📝 [Gemini] Prompt: $prompt');

      // BƯỚC 3: Gọi Gemini API
      // Gemini 2.0 Flash có thể generate image từ text+image input
      final apiUrl = '$_baseUrl/gemini-2.0-flash-exp:generateContent?key=$_apiKey';

      print('🌐 [Gemini] Calling API...');
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt,
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.4,
            'topK': 32,
            'topP': 1,
            'maxOutputTokens': 4096,
          }
        }),
      );

      print('📡 [Gemini] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse response
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content'];
          final parts = content['parts'];

          // Tìm phần chứa ảnh (nếu có)
          for (var part in parts) {
            if (part['inline_data'] != null) {
              final generatedImageBase64 = part['inline_data']['data'];
              print('✅ [Gemini] Image generated successfully!');

              // Return as data URL để dùng trực tiếp
              return 'data:image/jpeg;base64,$generatedImageBase64';
            }
          }

          print('⚠️ [Gemini] No image in response, only text');
          return null;
        }

        print('❌ [Gemini] No candidates in response');
        return null;

      } else {
        print('❌ [Gemini] API Error: ${response.statusCode}');
        print('   Body: ${response.body}');
        return null;
      }

    } catch (e, stackTrace) {
      print('❌ [Gemini] Exception: $e');
      print('   Stack: $stackTrace');
      return null;
    }
  }

  /// Tạo prompt thông minh để Gemini extend ảnh
  static String _generateExtensionPrompt(
      String animalName,
      int width,
      int height,
      ) {
    return '''
You are an expert wildlife photographer and image editor.

TASK: Extend this $animalName image to fill a mobile phone screen ($width x $height pixels, portrait orientation).

REQUIREMENTS:
1. Keep the $animalName in the CENTER-BOTTOM position of the new image
2. The animal should occupy roughly 40-50% of the frame
3. Generate a photorealistic natural habitat background around the animal
4. Match the lighting, color tone, and environment of the original image
5. Ensure seamless blending between original and generated parts
6. Maintain high quality and sharp details

HABITAT CONTEXT:
- If lion/tiger/cheetah: African savanna or grassland
- If elephant: Savanna or forest edge  
- If bear: Forest or mountain landscape
- If giraffe: Open savanna with acacia trees
- If penguin: Ice/snow environment
- If dolphin/shark: Ocean/underwater scene

OUTPUT: Generate a single extended image exactly $width x $height pixels.
''';
  }

  /// Alternative: Dùng Imagen 3 (nếu có access)
  /// Imagen 3 chuyên về image editing, quality cao hơn
  static Future<String?> extendWithImagen3({
    required String originalImageUrl,
    required String animalName,
  }) async {
    // Imagen 3 API (nếu Google cho phép access)
    const imagenUrl = 'https://us-central1-aiplatform.googleapis.com/v1/projects/YOUR_PROJECT/locations/us-central1/publishers/google/models/imagen-3.0-generate-001:predict';

    // TODO: Implement Imagen 3 API call
    // Hiện tại Imagen 3 chưa public, dùng Gemini Flash trước

    return null;
  }

  /// Validate API key
  static Future<bool> validateApiKey() async {
    if (_apiKey == 'AIzaSyCKfe1_udVnevaU1c0Ta5BH_CN7j8a5xSI') {
      print('❌ Chưa cấu hình Gemini API key!');
      return false;
    }

    try {
      // Test API với request đơn giản
      final response = await http.post(
        Uri.parse('$_baseUrl/gemini-2.0-flash-exp:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': 'Hello'}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Gemini API key hợp lệ!');
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('❌ Gemini API key không hợp lệ!');
        return false;
      } else {
        print('⚠️ Gemini API status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Không thể connect Gemini API: $e');
      return false;
    }
  }
}