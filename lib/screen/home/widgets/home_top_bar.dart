import 'package:flutter/material.dart';

class HomeTopBar extends StatelessWidget {
  final Widget searchBox;
  final VoidCallback? onProfileTap; // Thêm callback

  const HomeTopBar({
    super.key,
    required this.searchBox,
    this.onProfileTap, // Thêm vào constructor
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 15, 24, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.asset(
                        'assets/images/appicon.jpg',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AniQuest',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface
                    ),
                  ),
                ],
              ),
              // Bọc Avatar để nhấn được
              GestureDetector(
                onTap: onProfileTap,
                child: CircleAvatar(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.person_outline, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          searchBox,
        ],
      ),
    );
  }
}