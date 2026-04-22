import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../language/Locale_provider.dart';

class ContactTab extends StatelessWidget {
  final Color primaryGreen;

  const ContactTab({super.key, required this.primaryGreen});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? primaryGreen.withOpacity(0.2) : primaryGreen.withOpacity(0.1),
            ),
            child: Icon(Icons.support_agent_rounded, size: 50, color: primaryGreen),
          ),
          const SizedBox(height: 16),
          Text(
            t.tr('Chúng tôi luôn sẵn sàng lắng nghe bạn!'),
            style: TextStyle(fontSize: 15, color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          _buildContactCard(
            context: context,
            isDark: isDark,
            icon: Icons.email_rounded,
            color: Colors.redAccent,
            title: t.tr('Email Hỗ Trợ'),
            value: 'support@aniquest.com',
            onTap: () => _launch('mailto:support@aniquest.com'),
          ),
          _buildContactCard(
            context: context,
            isDark: isDark,
            icon: Icons.facebook_rounded,
            color: Colors.blue,
            title: 'Facebook',
            value: 'AniQuest Official',
            onTap: () => _launch('https://facebook.com/'), // Sửa link của bạn
          ),
          _buildContactCard(
            context: context,
            isDark: isDark,
            icon: Icons.code_rounded,
            color: isDark ? Colors.white : Colors.black87,
            title: 'GitHub',
            value: 'AniQuest Open Source',
            onTap: () => _launch('https://github.com/'), // Sửa link của bạn
          ),

          const SizedBox(height: 40),
          Text(
            '© 2026 AniQuest KLTN',
            style: TextStyle(fontSize: 12, color: colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // Custom Dark Mode cho từng thẻ
    final cardColor = isDark ? Colors.grey[850] : colorScheme.surface;
    final borderColor = isDark ? Colors.white12 : colorScheme.outlineVariant.withOpacity(0.5);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15)
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
        ),
        subtitle: Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.outline),
      ),
    );
  }
}