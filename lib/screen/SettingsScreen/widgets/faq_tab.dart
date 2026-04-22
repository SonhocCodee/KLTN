import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';

class FAQTab extends StatefulWidget {
  final Color primaryGreen;
  final Color accentOrange;

  const FAQTab({
    super.key,
    required this.primaryGreen,
    required this.accentOrange,
  });

  @override
  State<FAQTab> createState() => _FAQTabState();
}

class _FAQTabState extends State<FAQTab> {
  final Set<int> _expandedIndices = {};

  final List<Map<String, String>> faqData = [
    {
      'q': 'Tính năng nhận diện động vật bằng AI hoạt động thế nào?',
      'a': 'Bạn chỉ cần hướng camera vào con vật hoặc tải ảnh lên. AI của AniQuest sẽ phân tích hình ảnh và trả về kết quả dự đoán với độ chính xác cao nhất kèm theo thông tin chi tiết về loài vật đó.'
    },
    {
      'q': 'Ứng dụng có cần kết nối Internet không?',
      'a': 'Có. Để AI có thể phân tích hình ảnh nhanh chóng và truy xuất dữ liệu từ bách khoa toàn thư, thiết bị của bạn cần được kết nối Wi-Fi hoặc 4G/5G.'
    },
    {
      'q': 'Dữ liệu động vật được lấy từ đâu?',
      'a': 'Tất cả thông tin, đặc tính và hình ảnh động vật trên AniQuest được tổng hợp và kiểm duyệt từ các nguồn bách khoa khoa học uy tín, đảm bảo tính giáo dục và độ chính xác cao.'
    },
    {
      'q': 'Tôi có thể lưu lại những con vật đã tìm kiếm không?',
      'a': 'Chắc chắn rồi! Bạn có thể nhấn vào biểu tượng "Trái tim" hoặc "Đánh dấu" ở trang chi tiết con vật để lưu chúng vào Bộ sưu tập cá nhân.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Custom màu sắc cho Dark Mode
    final cardColor = isDark ? Colors.grey[850] : colorScheme.surface;
    final answerBgColor = isDark ? Colors.grey[900] : colorScheme.surfaceVariant.withOpacity(0.3);
    final borderColor = isDark ? Colors.white12 : colorScheme.outlineVariant.withOpacity(0.5);
    final shadowColor = isDark ? Colors.transparent : Colors.black.withOpacity(0.04);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqData.length,
      itemBuilder: (context, index) {
        final bool isExpanded = _expandedIndices.contains(index);
        final String question = t.tr(faqData[index]['q']!);
        final String answer = t.tr(faqData[index]['a']!);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    isExpanded ? _expandedIndices.remove(index) : _expandedIndices.add(index);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          question,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(Icons.keyboard_arrow_down_rounded, color: widget.accentOrange),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                alignment: Alignment.topCenter,
                child: isExpanded
                    ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: answerBgColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    border: Border(top: BorderSide(color: borderColor)),
                  ),
                  child: Text(
                    answer,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}