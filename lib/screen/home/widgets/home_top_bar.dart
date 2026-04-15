import 'package:flutter/material.dart';
import 'home_search_box.dart';

class HomeTopBar extends StatelessWidget {
  final Widget searchBox;

  const HomeTopBar({super.key, required this.searchBox});

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'AniQuest',
                    style: TextStyle(fontSize: 22, color: Color(0xFF2D4B2A)),
                  ),
                ],
              ),
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person_outline, color: Colors.grey),
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