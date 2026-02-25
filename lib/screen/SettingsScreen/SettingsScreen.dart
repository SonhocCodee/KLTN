import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _soundEffect = true;
  String _selectedLang = 'vi';

  static const _primaryGreen = Color(0xFF34D399);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cài Đặt',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Avatar / Profile mini
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primaryGreen, Color(0xFF14B8A6)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              CupertinoIcons.person_fill,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Khách',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  'Đăng nhập để lưu tiến trình',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primaryGreen, Color(0xFF14B8A6)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Đăng nhập',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Giao diện ───────────────────
                    _sectionTitle('Giao diện'),
                    _buildSettingsGroup([
                      _SettingsTile(
                        icon: CupertinoIcons.moon_fill,
                        iconColor: const Color(0xFF6366F1),
                        title: 'Chế độ tối',
                        trailing: CupertinoSwitch(
                          value: _darkMode,
                          activeColor: _primaryGreen,
                          onChanged: (v) => setState(() => _darkMode = v),
                        ),
                      ),
                      _SettingsTile(
                        icon: CupertinoIcons.globe,
                        iconColor: const Color(0xFF3B82F6),
                        title: 'Ngôn ngữ',
                        trailing: CupertinoSlidingSegmentedControl<String>(
                          groupValue: _selectedLang,
                          children: const {
                            'vi': Text('VI'),
                            'en': Text('EN'),
                          },
                          onValueChanged: (v) {
                            if (v != null) setState(() => _selectedLang = v);
                          },
                        ),
                      ),
                    ]),

                    _sectionTitle('Thông báo & Âm thanh'),
                    _buildSettingsGroup([
                      _SettingsTile(
                        icon: CupertinoIcons.bell_fill,
                        iconColor: const Color(0xFFF59E0B),
                        title: 'Thông báo',
                        trailing: CupertinoSwitch(
                          value: _notifications,
                          activeColor: _primaryGreen,
                          onChanged: (v) =>
                              setState(() => _notifications = v),
                        ),
                      ),
                      _SettingsTile(
                        icon: CupertinoIcons.volume_up,
                        iconColor: const Color(0xFF10B981),
                        title: 'Hiệu ứng âm thanh',
                        trailing: CupertinoSwitch(
                          value: _soundEffect,
                          activeColor: _primaryGreen,
                          onChanged: (v) =>
                              setState(() => _soundEffect = v),
                        ),
                      ),
                    ]),

                    _sectionTitle('Thông tin'),
                    _buildSettingsGroup([
                      _SettingsTile(
                        icon: CupertinoIcons.info_circle_fill,
                        iconColor: const Color(0xFF64748B),
                        title: 'Về AniQuest',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: CupertinoIcons.doc_text_fill,
                        iconColor: const Color(0xFF64748B),
                        title: 'Điều khoản sử dụng',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: CupertinoIcons.shield_fill,
                        iconColor: const Color(0xFF64748B),
                        title: 'Chính sách bảo mật',
                        onTap: () {},
                      ),
                    ]),

                    const SizedBox(height: 12),

                    // Version
                    Center(
                      child: Text(
                        'AniQuest v1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF94A3B8),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<_SettingsTile> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(tiles.length, (index) {
          final tile = tiles[index];
          final isLast = index == tiles.length - 1;
          return Column(
            children: [
              tile,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 0,
                  color: Colors.grey.withOpacity(0.1),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            if (trailing != null) trailing!
            else const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}