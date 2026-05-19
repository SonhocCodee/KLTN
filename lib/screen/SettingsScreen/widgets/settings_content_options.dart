import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';
import '../../SettingsScreen/provider/unit_provider.dart'; // 👈 thêm
import 'settings_components.dart';

class SettingsContentOptions extends StatelessWidget {
  final Color primaryGreen;
  final Color accentOrange;

  const SettingsContentOptions({
    super.key,
    required this.primaryGreen,
    required this.accentOrange,
    // 👆 Bỏ selectedUnit + onUnitChanged — giờ đọc thẳng từ UnitProvider
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();
    final u = context.watch<UnitProvider>(); // 👈 thêm

    return Column(
      children: [
        SettingsSectionHeader(
          title: t.tr('Tùy chỉnh Nội dung'),
          icon: Icons.book_outlined,
          primaryGreen: primaryGreen,
        ),
        SettingsCard(
          children: [
            ListTile(
              leading: Icon(Icons.straighten_rounded, color: primaryGreen),
              title: Text(
                t.tr('Đơn vị đo lường'),
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface),
              ),
              trailing: DropdownButton<String>(
                value: u.unit,                          // 👈 đọc từ provider
                underline: const SizedBox(),
                iconEnabledColor: accentOrange,
                items: [
                  DropdownMenuItem<String>(
                    value: 'metric',
                    child: Text(
                      t.tr('Hệ Mét (kg, m)'),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface),
                    ),
                  ),
                  DropdownMenuItem<String>(
                    value: 'imperial',
                    child: Text(
                      t.tr('Hệ Anh (lbs, ft)'),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) u.setUnit(val); // 👈 lưu vào provider + SharedPreferences
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}