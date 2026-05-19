import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../language/Locale_provider.dart'; // Đảm bảo đường dẫn đúng

class AnimalExternalLinks extends StatelessWidget {
  final Map<String, dynamic> animal;

  const AnimalExternalLinks({super.key, required this.animal});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Không thể mở link: $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ưu tiên dùng tên tiếng Anh để search ra nhiều kết quả chuẩn xác hơn
    final String searchName = animal['name_english'] ?? animal['name_vietnamese'] ?? '';
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () {
                final url = 'https://www.google.com/search?tbm=isch&q=${Uri.encodeComponent(searchName)}';
                _launchUrl(url);
              },
              icon: const Icon(Icons.image_search, size: 20),
              label: Text(t.tr('Hình ảnh')),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.secondaryContainer.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () {
                final url = 'https://en.wikipedia.org/wiki/${Uri.encodeComponent(searchName)}';
                _launchUrl(url);
              },
              icon: const Icon(Icons.travel_explore, size: 20),
              label: Text(t.tr('Wiki')),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.secondaryContainer.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}