import 'package:flutter/material.dart';
import 'package:kltn_app/screen/SettingsScreen/widgets/contact_tab.dart';
import 'package:kltn_app/screen/SettingsScreen/widgets/faq_tab.dart';
import 'package:provider/provider.dart';
import '../language/Locale_provider.dart';


class HelpCenterScreen extends StatefulWidget {
  final int initialIndex; // Quyết định mở Tab FAQ(0) hay Tab Liên hệ(1)
  const HelpCenterScreen({super.key, this.initialIndex = 0});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color accentOrange = const Color(0xFFEF6C00);

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialIndex,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          centerTitle: true,
          title: Text(
            t.tr('Trung tâm trợ giúp'),
            style: TextStyle(
              color: isDark ? Colors.white : primaryGreen, // Dark mode: chữ trắng
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: IconThemeData(color: isDark ? Colors.white : primaryGreen),
          bottom: TabBar(
            indicatorColor: accentOrange,
            indicatorWeight: 3,
            labelColor: accentOrange,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            dividerColor: colorScheme.outlineVariant.withOpacity(0.5), // Đường kẻ nhạt
            tabs: [
              Tab(text: t.tr('FAQ')),
              Tab(text: t.tr('Liên hệ')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FAQTab(primaryGreen: primaryGreen, accentOrange: accentOrange),
            ContactTab(primaryGreen: primaryGreen),
          ],
        ),
      ),
    );
  }
}