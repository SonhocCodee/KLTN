import 'package:flutter/material.dart';
import '../models/animal_suggestion.dart';

class HomeSearchBox extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final List<AnimalSuggestion> suggestions;
  final bool showSuggestions;
  final bool isSearching;
  final Function(String) onSearchChanged;
  final Function(AnimalSuggestion) onSuggestionTap;
  final VoidCallback onClearSearch;

  const HomeSearchBox({
    super.key,
    required this.searchController,
    required this.searchFocus,
    required this.suggestions,
    required this.showSuggestions,
    required this.isSearching,
    required this.onSearchChanged,
    required this.onSuggestionTap,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            focusNode: searchFocus,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm bạn động vật...',
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
              border: InputBorder.none,
              icon: isSearching
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              )
                  : Icon(Icons.search, color: colorScheme.primary),
              suffixIcon: searchController.text.isNotEmpty
                  ? GestureDetector(
                onTap: onClearSearch,
                child: Icon(Icons.close, color: colorScheme.onSurfaceVariant, size: 18),
              )
                  : null,
            ),
          ),
        ),

        if (showSuggestions && suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest, // SỬA Ở ĐÂY
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: suggestions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return _buildSuggestionItem(s, i, i == suggestions.length - 1, context);
                }).toList(),
              ),
            ),
          ),

        if (showSuggestions && suggestions.isEmpty && !isSearching)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest, // SỬA Ở ĐÂY
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('😕', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Text(
                  'Không tìm thấy "${searchController.text}"',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionItem(AnimalSuggestion s, int index, bool isLast, BuildContext context) {
    final query = searchController.text.trim();
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onSuggestionTap(s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
            bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.8),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: s.imageUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  s.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(s.typeEmoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
              )
                  : Center(child: Text(s.typeEmoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHighlightedText(s.nameVi, query, context,
                      baseStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface)),
                  const SizedBox(height: 2),
                  _buildHighlightedText(s.nameEn, query, context,
                      baseStyle: TextStyle(
                          fontSize: 12, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.typeLabel,
                style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query, BuildContext context, {required TextStyle baseStyle}) {
    if (query.isEmpty) return Text(text, style: baseStyle);

    final lower = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final start = lower.indexOf(lowerQuery);

    if (start == -1) return Text(text, style: baseStyle);

    final colorScheme = Theme.of(context).colorScheme;

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          if (start > 0) TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, start + query.length),
            style: baseStyle.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (start + query.length < text.length)
            TextSpan(text: text.substring(start + query.length)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}