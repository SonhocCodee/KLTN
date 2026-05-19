import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../language/Locale_provider.dart'; // Đảm bảo import Locale_provider

class IdentifyImageFrame extends StatelessWidget {
  final File? selectedImage;
  final VoidCallback onClear;

  const IdentifyImageFrame({super.key, required this.selectedImage, required this.onClear});
  static const _accentOrange = Color(0xFFEF6C00);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return AspectRatio(
      aspectRatio: 4 / 3.5,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: selectedImage == null ? colorScheme.surfaceContainer : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: selectedImage == null ? colorScheme.outlineVariant : colorScheme.primary,
            width: 3,
          ),
          boxShadow: selectedImage != null
              ? [BoxShadow(color: colorScheme.primary.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 12))]
              : null,
        ),
        child: selectedImage != null
            ? Stack(
          fit: StackFit.expand,
          children: [
            Image.file(selectedImage!, fit: BoxFit.cover),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                  ),
                  child: const Icon(CupertinoIcons.clear_thick, color: Colors.redAccent, size: 20),
                ),
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: _accentOrange.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.center_focus_strong_rounded, color: _accentOrange, size: 50),
            ),
            const SizedBox(height: 16),
            Text(t.tr('Chưa có dấu chân nào'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(t.tr('Chọn một bức ảnh để bắt đầu'), style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}