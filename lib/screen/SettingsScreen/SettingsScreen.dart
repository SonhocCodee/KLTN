import 'package:flutter/material.dart';

class AnimalSettingsScreen extends StatefulWidget {
  const AnimalSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AnimalSettingsScreen> createState() => _AnimalSettingsScreenState();
}

class _AnimalSettingsScreenState extends State<AnimalSettingsScreen>
    with SingleTickerProviderStateMixin {
  // Các biến state
  bool isDarkMode = false;
  String selectedLanguage = 'Tiếng Việt';
  double fontSizeFactor = 1.0;
  String selectedUnit = 'Hệ Mét (kg, m)';
  bool dailyAnimalNotif = true;
  bool streakNotif = true;

  // Animation cho icon chân thú ở Header
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color accentOrange = const Color(0xFFEF6C00);
  final Color cardColor = Colors.white;

  // Kích thước chữ gốc (chuẩn)
  final double baseFontSize = 14.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Cài đặt',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryGreen,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryGreen),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          _buildAnimatedHeader(),
          const SizedBox(height: 20),

          _buildSectionHeader('Giao diện & Hiển thị', Icons.palette_outlined),
          _buildCard([
            _buildSwitchTile(
              title: 'Chế độ tối (Dark Mode)',
              icon: Icons.dark_mode_rounded,
              value: isDarkMode,
              onChanged: (val) => setState(() => isDarkMode = val),
            ),
            _buildDivider(),
            ListTile(
              leading: Icon(Icons.language_rounded, color: primaryGreen),
              title: const Text('Ngôn ngữ', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: DropdownButton<String>(
                value: selectedLanguage,
                underline: const SizedBox(),
                items: ['Tiếng Việt', 'English'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedLanguage = val!),
              ),
            ),
            _buildDivider(),
            // --- PHẦN CỠ CHỮ CÓ PREVIEW MỚI ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.text_fields_rounded, color: primaryGreen),
                      const SizedBox(width: 16),
                      const Text('Cỡ chữ hiển thị', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: fontSizeFactor,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7, // Chia nhỏ hơn để kéo mượt hơn
                    activeColor: accentOrange,
                    inactiveColor: Colors.orange[100],
                    onChanged: (val) => setState(() => fontSizeFactor = val),
                  ),
                  // Khung xem trước (Preview Box)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentOrange.withOpacity(0.05), // Nền cam nhạt
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentOrange.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xem trước:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accentOrange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sư tử (Panthera leo) là một trong những đại miêu thuộc họ Mèo. Khác với phần lớn các loài họ Mèo khác, sư tử là loài có tính xã hội cao, sống tập trung thành các bầy đàn.',
                          // Cỡ chữ ở đây sẽ thay đổi theo thanh trượt
                          style: TextStyle(
                            fontSize: baseFontSize * fontSizeFactor,
                            color: Colors.black87,
                            height: 1.4, // Giãn dòng cho dễ đọc
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // --- KẾT THÚC PHẦN CỠ CHỮ ---
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader('Tùy chỉnh Nội dung', Icons.book_outlined),
          _buildCard([
            ListTile(
              leading: Icon(Icons.straighten_rounded, color: primaryGreen),
              title: const Text('Đơn vị đo lường', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: DropdownButton<String>(
                value: selectedUnit,
                underline: const SizedBox(),
                iconEnabledColor: accentOrange,
                items: ['Hệ Mét (kg, m)', 'Hệ Anh (lbs, ft)'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedUnit = val!),
              ),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader('Thông báo & Tương tác', Icons.notifications_active_outlined),
          _buildCard([
            _buildSwitchTile(
              title: 'Động vật của ngày',
              subtitle: 'Khám phá một loài vật mới mỗi ngày',
              icon: Icons.pets_rounded,
              value: dailyAnimalNotif,
              onChanged: (val) => setState(() => dailyAnimalNotif = val),
            ),
            _buildDivider(),
            _buildSwitchTile(
              title: 'Nhắc nhở chuỗi (Streak)',
              subtitle: 'Đừng quên làm nhiệm vụ thám hiểm!',
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.redAccent,
              value: streakNotif,
              onChanged: (val) => setState(() => streakNotif = val),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader('Thông tin', Icons.info_outline_rounded),
          _buildCard([
            ListTile(
              leading: Icon(Icons.bug_report_rounded, color: primaryGreen),
              title: const Text('Góp ý & Báo lỗi', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
            _buildDivider(),
            ListTile(
              leading: Icon(Icons.security_rounded, color: primaryGreen),
              title: const Text('Chính sách bảo mật', style: TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 30),
          Center(
            child: Text(
              'Phiên bản 1.0.0\nĐộng Vật Bách Khoa Toàn Thư',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.5),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.pets_rounded, size: 50, color: accentOrange),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tùy chỉnh chuyến thám hiểm của bạn',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryGreen),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Color? iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? primaryGreen),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 13)) : null,
      trailing: Switch(
        value: value,
        activeColor: accentOrange,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey[200], indent: 56);
  }
}