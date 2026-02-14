import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/animal_home_service.dart';
import '../models/animal_category_model.dart';

class AnimalDetailScreen extends StatefulWidget {
  final String animalId;
  final AnimalCategory category;

  const AnimalDetailScreen({
    super.key,
    required this.animalId,
    required this.category,
  });

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  final AnimalHomeService _service = AnimalHomeService();

  Map<String, dynamic>? _animal;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnimalDetails();
  }

  Future<void> _loadAnimalDetails() async {
    setState(() => _isLoading = true);

    try {
      final animal = await _service.getAnimalById(widget.animalId);

      setState(() {
        _animal = animal;
        _isLoading = false;
      });

      if (animal != null) {
        print('✅ Loaded: ${animal['name_english']}');
      }
    } catch (e) {
      print('❌ Error loading animal details: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildLoadingState()
          : _animal == null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.category.gradient,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header với back button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildBackButton(),
                  const Spacer(),
                  const Text(
                    'Không tìm thấy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Không tìm thấy thông tin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final imageUrl = _animal!['image_url'] ?? '';
    final nameVi = _animal!['name_vietnamese'] ?? 'Chưa có tên';
    final nameEn = _animal!['name_english'] ?? '';
    final scientificName = _animal!['scientific_name'] ?? '';

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Background Image với parallax effect
          _buildBackgroundImage(imageUrl),

          // Content
          _buildScrollableContent(),

          // Header overlay
          _buildHeaderOverlay(),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage(String imageUrl) {
    return Positioned.fill(
      child: imageUrl.isNotEmpty
          ? Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.category.gradient,
              ),
            ),
          );
        },
      )
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.category.gradient,
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableContent() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(),
                      const SizedBox(height: 24),
                      _buildQuickStats(),
                      const SizedBox(height: 24),
                      _buildDescription(),
                      const SizedBox(height: 24),
                      _buildPhysicalTraits(),
                      const SizedBox(height: 24),
                      _buildBehavioralTraits(),
                      const SizedBox(height: 24),
                      _buildConservationInfo(),
                      const SizedBox(height: 24),
                      _buildTaxonomy(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _buildBackButton(),
              const Spacer(),
              _buildFavoriteButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã thêm vào yêu thích'),
                    backgroundColor: Color(0xFF34D399),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    final nameVi = _animal!['name_vietnamese'] ?? '';
    final nameEn = _animal!['name_english'] ?? '';
    final scientificName = _animal!['scientific_name'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nameVi,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          nameEn,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: widget.category.gradient[0],
          ),
        ),
        if (scientificName.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            scientificName,
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickStats() {
    final weightAvg = _animal!['weight_avg_kg'] ?? 0;
    final heightAvg = _animal!['height_avg_m'] ?? 0;
    final lifespanAvg = _animal!['lifespan_avg_years'] ?? 0;
    final maxSpeed = _animal!['max_speed_kmh'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.fitness_center,
            value: '${weightAvg.toStringAsFixed(0)} kg',
            label: 'Cân nặng',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.height,
            value: '${heightAvg.toStringAsFixed(1)} m',
            label: 'Chiều cao',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule,
            value: '$lifespanAvg năm',
            label: 'Tuổi thọ',
          ),
        ),
        if (maxSpeed > 0) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.speed,
              value: '$maxSpeed km/h',
              label: 'Tốc độ',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.category.gradient[0].withOpacity(0.1),
            widget.category.gradient[1].withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.category.gradient[0].withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: widget.category.gradient[0],
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    final description = _animal!['description_short'] ?? '';
    final funFact = _animal!['fun_fact_vietnamese'] ?? '';

    if (description.isEmpty && funFact.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Giới thiệu', Icons.info_outline),
        const SizedBox(height: 12),
        if (description.isNotEmpty) ...[
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (funFact.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFBBF24),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Có thể bạn chưa biết',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        funFact,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF78350F),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPhysicalTraits() {
    final colors = _animal!['primary_colors'] as List? ?? [];
    final patterns = _animal!['patterns'] as List? ?? [];
    final furType = _animal!['fur_type'] ?? '';
    final hasClaws = _animal!['has_claws'] ?? false;
    final hasSharpTeeth = _animal!['has_sharp_teeth'] ?? false;
    final hasTail = _animal!['has_tail'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Đặc điểm vật lý', Icons.brush),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (colors.isNotEmpty)
              _buildTraitChip('Màu sắc: ${colors.join(", ")}'),
            if (patterns.isNotEmpty)
              _buildTraitChip('Vân: ${patterns.join(", ")}'),
            if (furType.isNotEmpty)
              _buildTraitChip(furType.replaceAll('_', ' ')),
            if (hasClaws)
              _buildTraitChip('Có móng vuốt', icon: Icons.check),
            if (hasSharpTeeth)
              _buildTraitChip('Có nanh sắc', icon: Icons.check),
            if (hasTail)
              _buildTraitChip('Có đuôi', icon: Icons.check),
          ],
        ),
      ],
    );
  }

  Widget _buildBehavioralTraits() {
    final temperament = _animal!['temperament'] ?? '';
    final socialStructure = _animal!['social_structure'] ?? '';
    final activityPattern = _animal!['activity_pattern'] ?? '';
    final dietType = _animal!['diet_type'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Hành vi', Icons.pets),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (temperament.isNotEmpty)
              _buildTraitChip('Tính cách: $temperament'),
            if (socialStructure.isNotEmpty)
              _buildTraitChip('Xã hội: $socialStructure'),
            if (activityPattern.isNotEmpty)
              _buildTraitChip('Hoạt động: $activityPattern'),
            if (dietType.isNotEmpty)
              _buildTraitChip('Chế độ ăn: $dietType'),
          ],
        ),
      ],
    );
  }

  Widget _buildConservationInfo() {
    final conservationStatus = _animal!['conservation_status'] ?? '';
    final isEndangered = _animal!['is_endangered'] ?? false;

    if (conservationStatus.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Bảo tồn', Icons.eco),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isEndangered
                ? const Color(0xFFFEE2E2)
                : const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEndangered
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF22C55E),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isEndangered ? Icons.warning_amber : Icons.check_circle,
                color: isEndangered
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF22C55E),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conservationStatus,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isEndangered
                            ? const Color(0xFF991B1B)
                            : const Color(0xFF166534),
                      ),
                    ),
                    Text(
                      isEndangered
                          ? 'Đang bị đe dọa tuyệt chủng'
                          : 'Tình trạng ổn định',
                      style: TextStyle(
                        fontSize: 13,
                        color: isEndangered
                            ? const Color(0xFF991B1B)
                            : const Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaxonomy() {
    final kingdom = _animal!['kingdom'] ?? '';
    final phylum = _animal!['phylum'] ?? '';
    final classValue = _animal!['class'] ?? '';
    final orderName = _animal!['order_name'] ?? '';
    final family = _animal!['family'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Phân loại khoa học', Icons.science),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (kingdom.isNotEmpty)
                _buildTaxonomyRow('Giới', kingdom),
              if (phylum.isNotEmpty)
                _buildTaxonomyRow('Ngành', phylum),
              if (classValue.isNotEmpty)
                _buildTaxonomyRow('Lớp', classValue),
              if (orderName.isNotEmpty)
                _buildTaxonomyRow('Bộ', orderName),
              if (family.isNotEmpty)
                _buildTaxonomyRow('Họ', family, isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: widget.category.gradient[0],
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildTraitChip(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.category.gradient[0].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.category.gradient[0].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: widget.category.gradient[0],
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.category.gradient[0],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxonomyRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          Divider(
            color: Colors.grey.shade300,
            height: 1,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}