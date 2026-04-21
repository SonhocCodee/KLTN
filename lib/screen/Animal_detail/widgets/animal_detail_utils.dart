import 'package:flutter/material.dart';

class AnimalDetailUtils {
  static String translateValue(String key, String value) {
    final translations = {
      'gentle': 'Hiền lành', 'neutral': 'Trung tính', 'aggressive': 'Hung dữ',
      'timid': 'Nhút nhát', 'territorial': 'Bảo vệ lãnh thổ',
      'solitary': 'Sống đơn độc', 'pair': 'Sống theo cặp',
      'small_group': 'Nhóm nhỏ', 'herd': 'Bầy đàn', 'pack': 'Đàn săn mồi',
      'colony': 'Thuộc địa', 'pride': 'Bầy (sư tử)',
      'nocturnal': 'Hoạt động ban đêm', 'diurnal': 'Hoạt động ban ngày',
      'crepuscular': 'Hoạt động lúc chạng vạng', 'cathemeral': 'Cả ngày lẫn đêm',
      'carnivore': 'Ăn thịt', 'herbivore': 'Ăn cỏ', 'omnivore': 'Ăn tạp',
      'insectivore': 'Ăn côn trùng', 'piscivore': 'Ăn cá',
      'savanna': 'Thảo nguyên', 'tropical_forest': 'Rừng nhiệt đới',
      'temperate_forest': 'Rừng ôn đới', 'desert': 'Sa mạc', 'tundra': 'Đồng băng',
      'mountain': 'Núi cao', 'ocean': 'Đại dương', 'freshwater': 'Nước ngọt',
      'wetland': 'Đất ngập nước', 'grassland': 'Đồng cỏ', 'forest': 'Rừng',
      'domestic': 'Nhà nuôi', 'Domesticated': 'Đã thuần hóa',
      'Least Concern': 'Ít quan tâm', 'Near Threatened': 'Sắp bị đe dọa',
      'Vulnerable': 'Sắp nguy cấp', 'Endangered': 'Nguy cấp',
      'Critically Endangered': 'Cực kỳ nguy cấp', 'Extinct in Wild': 'Tuyệt chủng ngoài tự nhiên',
      'Extinct': 'Đã tuyệt chủng',
      'harmless': 'Không nguy hiểm', 'low': 'Ít nguy hiểm', 'moderate': 'Trung bình',
      'high': 'Nguy hiểm', 'dangerous': 'Rất nguy hiểm', 'extreme': 'Cực kỳ nguy hiểm',
      'black': 'Đen', 'white': 'Trắng', 'brown': 'Nâu', 'gray': 'Xám',
      'grey': 'Xám', 'orange': 'Cam', 'yellow': 'Vàng', 'tan': 'Hung vàng',
      'red': 'Đỏ', 'blue': 'Xanh dương', 'green': 'Xanh lá',
      'solid': 'Đồng nhất', 'striped': 'Sọc', 'spotted': 'Đốm', 'patches': 'Vảy',
      'short_fur': 'Lông ngắn', 'long_fur': 'Lông dài', 'thick_fur': 'Lông dày',
      'scales': 'Vảy', 'feathers': 'Lông vũ', 'smooth_skin': 'Da mịn',
      'thick_skin': 'Da dày',
    };
    return translations[value.toLowerCase()] ?? value;
  }

  static String generateDescription(Map<String, dynamic> animal) {
    final nameVi = animal['name_vietnamese'] ?? '';
    final habitat = translateValue('habitat', animal['primary_habitat'] ?? '');
    final dietType = translateValue('diet', animal['diet_type'] ?? '');
    final temperament = translateValue('temperament', animal['temperament'] ?? '');
    final conservationStatus = translateValue('conservation', animal['conservation_status'] ?? '');
    List<String> parts = [];
    if (nameVi.isNotEmpty) {
      parts.add('$nameVi là một loài động vật');
      if (habitat.isNotEmpty) parts.add('sống chủ yếu ở môi trường $habitat');
      if (dietType.isNotEmpty) parts.add('với chế độ ăn $dietType');
      if (temperament.isNotEmpty) parts.add('và có tính cách $temperament');
      if (conservationStatus.isNotEmpty) parts.add('Tình trạng bảo tồn hiện tại: $conservationStatus');
    }
    return parts.isNotEmpty ? parts.join('. ') + '.' : '';
  }

  static Widget buildSectionTitle(String title, String emoji, ColorScheme colorScheme) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: colorScheme.onSurface, letterSpacing: -0.2)),
      ],
    );
  }

  static Widget buildSectionGap(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Container(height: 1, color: colorScheme.outlineVariant),
    );
  }

  static Widget buildTableRow(String icon, String label, String value, bool isLast, ColorScheme colorScheme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500))),
              Expanded(child: Text(value, style: TextStyle(fontSize: 14, color: colorScheme.onSurface, fontWeight: FontWeight.w600, height: 1.4), textAlign: TextAlign.right)),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 46, color: colorScheme.outlineVariant),
      ],
    );
  }
}