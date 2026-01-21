import 'package:flutter/material.dart';

class ImageDisplayHelper {
  /// Tính alignment để con vật hiện ở chính giữa-dưới màn hình
  ///
  /// Ảnh sau khi extend từ AI sẽ có format 1080x1920 (9:16)
  /// Ta cần alignment sao cho:
  /// - X: 0 (giữa ngang)
  /// - Y: 0.3 đến 0.5 (giữa-dưới màn hình)
  static Alignment getAnimalAlignment({
    required String animalName,
    required bool isExtendedImage,
  }) {
    if (!isExtendedImage) {
      // Ảnh gốc chưa extend → dùng preset cũ
      return _getPresetAlignment(animalName);
    }

    // Ảnh đã extend bởi AI → Con vật đã ở center-bottom
    // Ta chỉ cần căn sao cho phần dưới của ảnh hiện rõ
    return const Alignment(0, 0.3); // Giữa ngang, hơi xuống dưới
  }

  static Alignment _getPresetAlignment(String animalName) {
    final presets = {
      'lion': Alignment(0, 0.2),
      'tiger': Alignment(0, 0.2),
      'elephant': Alignment(0, 0.3),
      'giraffe': Alignment(0, -0.1), // Cao nên lên trên
      'bear': Alignment(0, 0.2),
      'wolf': Alignment(0, 0.2),
      'cheetah': Alignment(0, 0.25),
      'leopard': Alignment(0, 0.2),
      // Thêm các loài khác...
    };

    return presets[animalName.toLowerCase()] ?? const Alignment(0, 0.2);
  }

  /// Tính BoxFit phù hợp
  static BoxFit getOptimalFit({
    required bool isExtendedImage,
    required double screenWidth,
    required double screenHeight,
  }) {
    if (isExtendedImage) {
      // Ảnh đã extend về đúng tỷ lệ phone → cover full screen
      return BoxFit.cover;
    } else {
      // Ảnh gốc có thể không đúng tỷ lệ
      return BoxFit.cover;
    }
  }
}