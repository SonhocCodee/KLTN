import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart'; // Chỉnh lại đường dẫn nếu cần
import 'settings_components.dart';

class SettingsContentOptions extends StatelessWidget {
  final String selectedUnit;
  final ValueChanged<String?> onUnitChanged;
  final Color primaryGreen;
  final Color accentOrange;

  const SettingsContentOptions({
    super.key,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.primaryGreen,
    required this.accentOrange,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return Column(
      children: [
        SettingsSectionHeader(
          title: t.tr( 'Tùy chỉnh Nội dung'),
          icon: Icons.book_outlined,
          primaryGreen: primaryGreen,
        ),
        SettingsCard(
          children: [
            ListTile(
              leading: Icon(Icons.straighten_rounded, color: primaryGreen),
              title: Text(
                t.tr('Đơn vị đo lường'),
                style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
              ),
              trailing: DropdownButton<String>(
                value: selectedUnit, // Đang nhận chữ 'metric' hoặc 'imperial'
                underline: const SizedBox(),
                iconEnabledColor: accentOrange,
                items: [
                  DropdownMenuItem<String>(
                    value: 'metric',
                    child: Text(
                      t.tr('Hệ Mét (kg, m)'),
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                  ),
                  DropdownMenuItem<String>(
                    value: 'imperial',
                    child: Text(
                      t.tr('Hệ Anh (lbs, ft)'),
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                  ),
                ],
                onChanged: onUnitChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}