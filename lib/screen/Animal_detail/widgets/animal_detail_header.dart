import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../home/animal_category_model.dart';
import '../../report/Animal report sheet.dart';

// ── Trạng thái Loading ────────────────────────────────────────
class AnimalDetailLoading extends StatelessWidget {
  final AnimalCategory category;
  const AnimalDetailLoading({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36, height: 36,
              child: CircularProgressIndicator(color: category.gradient[0], strokeWidth: 2.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Đang tải...',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trạng thái Error ──────────────────────────────────────────
class AnimalDetailError extends StatelessWidget {
  const AnimalDetailError({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy thông tin',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Loài này chưa có dữ liệu trong hệ thống',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Quay lại',
                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ảnh đầu trang (SliverAppBar) ──────────────────────────────
class AnimalDetailImageHeader extends StatelessWidget {
  final String imageUrl;
  final AnimalCategory category;

  const AnimalDetailImageHeader({super.key, required this.imageUrl, required this.category});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      expandedHeight: 420,
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      leading: const SizedBox.shrink(),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildGradientPlaceholder(),
            )
                : _buildGradientPlaceholder(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.55, 1.0],
                  colors: [
                    Colors.black.withOpacity(0.22),
                    Colors.transparent,
                    colorScheme.surface,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: category.gradient,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, size: 100, color: Colors.white.withOpacity(0.35)),
            const SizedBox(height: 12),
            Text(
              'Chưa có hình ảnh',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nút Floating (Back + Report) ───────────────────────────────
class AnimalDetailFloatingButtons extends StatelessWidget {
  final String animalId;
  final Map<String, dynamic> animal;

  const AnimalDetailFloatingButtons({
    super.key,
    required this.animalId,
    required this.animal,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildGlassButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),
            _buildGlassButton(
              icon: Icons.flag_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
                showAnimalReportSheet(context, animalId: animalId, animal: animal);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}