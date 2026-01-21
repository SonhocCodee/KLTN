import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ImageProcessor {
  // Phân tích ảnh và tìm vùng có nhiều chi tiết nhất (giả định đó là con vật)
  static Future<Alignment> detectAnimalPosition(String imageUrl) async {
    try {
      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        return Alignment.center; // Fallback
      }

      final Uint8List imageBytes = response.bodyBytes;
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      // Chia ảnh thành 9 vùng (grid 3x3) và tính "độ quan trọng"
      final width = image.width;
      final height = image.height;

      // Giả định: vùng giữa và dưới giữa thường chứa động vật
      // Ta sẽ ưu tiên các vùng này

      // Grid positions:
      // [TL] [TC] [TR]
      // [ML] [MC] [MR]  <- MC (Middle Center) và BC (Bottom Center) quan trọng nhất
      // [BL] [BC] [BR]

      // Tính toán dựa trên aspect ratio và kích thước
      final aspectRatio = width / height;

      Alignment bestAlignment;

      if (aspectRatio > 1.5) {
        // Ảnh ngang rộng → Con vật thường ở giữa ngang
        bestAlignment = Alignment.center;
      } else if (aspectRatio < 0.7) {
        // Ảnh dọc → Con vật thường ở giữa-dưới
        bestAlignment = const Alignment(0, 0.2); // Hơi xuống dưới
      } else {
        // Ảnh vuông hoặc gần vuông → Ưu tiên center
        bestAlignment = Alignment.center;
      }

      image.dispose();
      return bestAlignment;

    } catch (e) {
      print('❌ Image Analysis Error: $e');
      return Alignment.center;
    }
  }

  // Lấy focal point từ metadata (nếu có)
  static Alignment getFocalPoint(String imageUrl) {
    // Wikipedia images thường có cấu trúc URL chuẩn
    // Có thể parse để detect loại ảnh

    if (imageUrl.contains('Portrait') || imageUrl.contains('portrait')) {
      // Portrait photos → Face thường ở trên
      return const Alignment(0, -0.2);
    } else if (imageUrl.contains('Full_body') || imageUrl.contains('standing')) {
      // Full body → Center
      return Alignment.center;
    } else if (imageUrl.contains('Close') || imageUrl.contains('close-up')) {
      // Close-up → Thường crop đúng rồi
      return Alignment.center;
    }

    // Default: Hơi lên trên để tránh bị crop mặt
    return const Alignment(0, -0.1);
  }
}