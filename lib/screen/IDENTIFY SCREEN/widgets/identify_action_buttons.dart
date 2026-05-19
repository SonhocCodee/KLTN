import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../language/Locale_provider.dart'; // Đảm bảo import Locale_provider
import '../service/Identify_service.dart';

class IdentifyActionButtons extends StatelessWidget {
  final IdentifyService service;
  final VoidCallback onSearch;

  const IdentifyActionButtons({super.key, required this.service, required this.onSearch});
  static const _accentOrange = Color(0xFFEF6C00);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOptionCard(
                icon: Icons.camera_alt_rounded,
                label: t.tr('Chụp Mới'),
                bgColor: colorScheme.primary,
                onTap: () => service.pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOptionCard(
                icon: Icons.photo_library_rounded,
                label: t.tr('Thư Viện'),
                bgColor: _accentOrange,
                onTap: () => service.pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),
        if (service.selectedImage != null) ...[
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: service.isAnalyzing ? null : onSearch,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: colorScheme.inverseSurface, // Nền tương phản cao (đen ở sáng, trắng ở tối)
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 8,
              shadowColor: colorScheme.shadow.withOpacity(0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.saved_search_rounded, color: colorScheme.onInverseSurface, size: 28),
                const SizedBox(width: 12),
                Text(
                  t.tr('Bắt Đầu Phân Tích'),
                  style: TextStyle(color: colorScheme.onInverseSurface, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionCard({required IconData icon, required String label, required Color bgColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: bgColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}