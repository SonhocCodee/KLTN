import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';


class IdentifyScreen extends StatelessWidget {
  const IdentifyScreen({super.key});

  static const _primaryGreen = Color(0xFF34D399);
  static const _teal = Color(0xFF14B8A6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhận Diện',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Text(
                'Chụp hoặc tải ảnh để nhận diện động vật',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 32),

              // Camera card lớn
              Expanded(
                flex: 3,
                child: _buildUploadCard(context),
              ),
              const SizedBox(height: 20),

              // 2 lựa chọn nhỏ
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildOptionCard(
                        icon: CupertinoIcons.camera_fill,
                        label: 'Chụp ngay',
                        gradient: [_primaryGreen, _teal],
                        onTap: () {
                          // TODO: mở camera
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildOptionCard(
                        icon: CupertinoIcons.photo_on_rectangle,
                        label: 'Thư viện',
                        gradient: [
                          const Color(0xFF818CF8),
                          const Color(0xFF6366F1)
                        ],
                        onTap: () {
                          // TODO: mở gallery
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: chọn ảnh
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _primaryGreen.withOpacity(0.3),
            width: 2,
            // Dashed border effect bằng custom painter có thể thêm sau
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryGreen, _teal],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryGreen.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.camera_fill,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tải ảnh lên',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Chụp hoặc kéo thả ảnh vào đây',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Hỗ trợ JPG, PNG, WEBP',
                style: TextStyle(
                  fontSize: 12,
                  color: _primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}