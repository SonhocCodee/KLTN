import 'package:flutter/material.dart';
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

    return Column(
      children: [
        SettingsSectionHeader(
          title: 'Tùy chỉnh Nội dung',
          icon: Icons.book_outlined,
          primaryGreen: primaryGreen,
        ),
        SettingsCard(
          children: [
            ListTile(
              leading: Icon(Icons.straighten_rounded, color: primaryGreen),
              title: Text(
                'Đơn vị đo lường',
                style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
              ),
              trailing: DropdownButton<String>(
                value: selectedUnit,
                underline: const SizedBox(),
                iconEnabledColor: accentOrange,
                items: ['Hệ Mét (kg, m)', 'Hệ Anh (lbs, ft)'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                  );
                }).toList(),
                onChanged: onUnitChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}