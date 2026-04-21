import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/theme_provider.dart';
import 'settings_components.dart';

class SettingsAppearanceOptions extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String?> onLanguageChanged;
  final Color primaryGreen;
  final Color accentOrange;

  const SettingsAppearanceOptions({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.primaryGreen,
    required this.accentOrange,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme   = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      children: [
        SettingsSectionHeader(
          title: 'Giao diện & Hiển thị',
          icon: Icons.palette_outlined,
          primaryGreen: primaryGreen,
        ),
        SettingsCard(
          children: [
            SettingsSwitchTile(
              title: 'Chế độ tối (Dark Mode)',
              icon: Icons.dark_mode_rounded,
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
              primaryGreen: primaryGreen,
              accentOrange: accentOrange,
            ),
            const SettingsDivider(),
            ListTile(
              leading: Icon(Icons.language_rounded, color: primaryGreen),
              title: Text(
                'Ngôn ngữ',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface),
              ),
              trailing: DropdownButton<String>(
                value: selectedLanguage,
                underline: const SizedBox(),
                items: ['Tiếng Việt', 'English'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface),
                    ),
                  );
                }).toList(),
                onChanged: onLanguageChanged,
              ),
            ),
            const SettingsDivider(),
            _FontSizeTile(
              primaryGreen: primaryGreen,
              accentOrange: accentOrange,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Widget riêng để watch ThemeProvider và rebuild độc lập ──
class _FontSizeTile extends StatelessWidget {
  final Color primaryGreen;
  final Color accentOrange;

  const _FontSizeTile({
    required this.primaryGreen,
    required this.accentOrange,
  });

  static const _labels = ['Nhỏ', 'Bình thường', 'Lớn'];
  static const _previewText =
      'Sư tử (Panthera leo) là một trong những đại miêu thuộc họ Mèo. '
      'Khác với phần lớn các loài họ Mèo khác, sư tử là loài có tính xã hội '
      'cao, sống tập trung thành các bầy đàn.';

  @override
  Widget build(BuildContext context) {
    final colorScheme   = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final currentStep   = themeProvider.currentFontStep; // 0 | 1 | 2

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tiêu đề ──
          Row(
            children: [
              Icon(Icons.text_fields_rounded, color: primaryGreen),
              const SizedBox(width: 16),
              Text(
                'Cỡ chữ hiển thị',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colorScheme.onSurface),
              ),
              const Spacer(),
              // Badge hiển thị mốc đang chọn
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _labels[currentStep],
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentOrange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ── Slider 3 mốc ──
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape:
              const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape:
              const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: accentOrange,
              inactiveTrackColor: accentOrange.withOpacity(0.2),
              thumbColor: accentOrange,
              overlayColor: accentOrange.withOpacity(0.15),
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 4),
              activeTickMarkColor: Colors.white,
              inactiveTickMarkColor: accentOrange.withOpacity(0.4),
            ),
            child: Slider(
              value: currentStep.toDouble(),
              min: 0,
              max: 2,
              divisions: 2,
              onChanged: (val) =>
                  themeProvider.setFontSizeByStep(val.round()),
            ),
          ),

          // ── Label 3 mốc ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (i) {
                final isSelected = i == currentStep;
                return GestureDetector(
                  onTap: () => themeProvider.setFontSizeByStep(i),
                  child: Text(
                    _labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? accentOrange
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 14),

          // ── Xem trước — dùng textScaler: 1.0 để không bị nhân đôi ──
          // (vì MediaQuery đã scale rồi, ở đây ta chỉ muốn preview đúng kích thước thật)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentOrange.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentOrange.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xem trước:',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentOrange),
                ),
                const SizedBox(height: 8),
                // Text này sẽ tự scale theo MediaQuery của app
                Text(
                  _previewText,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}