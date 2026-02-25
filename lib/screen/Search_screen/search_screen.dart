import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;

  static const _primaryGreen = Color(0xFF34D399);

  final List<String> _suggestions = [
    '🐅  Hổ Bengal sống ở đâu?',
    '🦜  Vẹt có thể học nói không?',
    '🐬  Cá heo thông minh như thế nào?',
    '🦁  Sư tử và báo khác nhau ra sao?',
    '🐧  Chim cánh cụt đẻ bao nhiêu trứng?',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tìm Kiếm',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hỏi bất cứ điều gì về động vật',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _isFocused
                            ? _primaryGreen
                            : Colors.grey.withOpacity(0.15),
                        width: _isFocused ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isFocused
                              ? _primaryGreen.withOpacity(0.1)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: _isFocused ? 16 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Icon(
                            CupertinoIcons.search,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            decoration: const InputDecoration(
                              hintText: 'Hổ có bao nhiêu loài phụ?',
                              hintStyle: TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                            onSubmitted: (val) {
                              // TODO: gọi API tìm kiếm
                            },
                          ),
                        ),
                        if (_controller.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _controller.clear();
                              setState(() {});
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(
                                CupertinoIcons.xmark_circle_fill,
                                color: Color(0xFFCBD5E1),
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Gợi ý câu hỏi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _primaryGreen,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Câu hỏi gợi ý',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return _SuggestionTile(
                    text: _suggestions[index],
                    onTap: () {
                      _controller.text =
                          _suggestions[index].substring(3).trim();
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionTile({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const Icon(
                CupertinoIcons.arrow_up_left,
                size: 16,
                color: Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}