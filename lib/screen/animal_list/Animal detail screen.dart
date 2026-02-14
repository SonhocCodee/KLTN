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
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _animal;
  bool _isLoading = true;
  bool _showFullImage = false;

  @override
  void initState() {
    super.initState();
    _loadAnimalDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  // ═══════════════════════════════════════════════════════════════
  // 🌐 VIỆT HÓA - Translate English values to Vietnamese
  // ═══════════════════════════════════════════════════════════════
  String _translateValue(String key, String value) {
    final translations = {
      // Temperament
      'gentle': 'Hiền lành',
      'neutral': 'Trung tính',
      'aggressive': 'Hung dữ',
      'timid': 'Nhút nhát',
      'territorial': 'Bảo vệ lãnh thổ',

      // Social structure
      'solitary': 'Sống đơn độc',
      'pair': 'Sống theo cặp',
      'small_group': 'Nhóm nhỏ',
      'herd': 'Bầy đàn',
      'pack': 'Đàn săn mồi',
      'colony': 'Thuộc địa',
      'pride': 'Bầy (sư tử)',

      // Activity pattern
      'nocturnal': 'Hoạt động ban đêm',
      'diurnal': 'Hoạt động ban ngày',
      'crepuscular': 'Hoạt động lúc chạng vạng',
      'cathemeral': 'Cả ngày lẫn đêm',

      // Diet type
      'carnivore': 'Ăn thịt',
      'herbivore': 'Ăn cỏ',
      'omnivore': 'Ăn tạp',
      'insectivore': 'Ăn côn trùng',
      'piscivore': 'Ăn cá',

      // Habitat
      'savanna': 'Thảo nguyên',
      'tropical_forest': 'Rừng nhiệt đới',
      'temperate_forest': 'Rừng ôn đới',
      'desert': 'Sa mạc',
      'tundra': 'Đồng băng',
      'mountain': 'Núi cao',
      'ocean': 'Đại dương',
      'freshwater': 'Nước ngọt',
      'wetland': 'Đất ngập nước',
      'grassland': 'Đồng cỏ',
      'forest': 'Rừng',
      'domestic': 'Nhà nuôi',

      // Conservation status
      'Domesticated': 'Đã thuần hóa',
      'Least Concern': 'Ít quan tâm',
      'Near Threatened': 'Sắp bị đe dọa',
      'Vulnerable': 'Sắp nguy cấp',
      'Endangered': 'Nguy cấp',
      'Critically Endangered': 'Cực kỳ nguy cấp',
      'Extinct in Wild': 'Tuyệt chủng ngoài tự nhiên',
      'Extinct': 'Đã tuyệt chủng',

      // Danger level
      'harmless': 'Không nguy hiểm',
      'low': 'Ít nguy hiểm',
      'moderate': 'Trung bình',
      'high': 'Nguy hiểm',
      'dangerous': 'Rất nguy hiểm',
      'extreme': 'Cực kỳ nguy hiểm',

      // Colors
      'black': 'Đen',
      'white': 'Trắng',
      'brown': 'Nâu',
      'gray': 'Xám',
      'grey': 'Xám',
      'orange': 'Cam',
      'yellow': 'Vàng',
      'tan': 'Hung vàng',
      'red': 'Đỏ',
      'blue': 'Xanh dương',
      'green': 'Xanh lá',

      // Patterns
      'solid': 'Đồng nhất',
      'striped': 'Sọc',
      'spotted': 'Đốm',
      'patches': 'Vảy',

      // Fur/skin type
      'short_fur': 'Lông ngắn',
      'long_fur': 'Lông dài',
      'thick_fur': 'Lông dày',
      'scales': 'Vảy',
      'feathers': 'Lông vũ',
      'smooth_skin': 'Da mịn',
      'thick_skin': 'Da dày',
    };

    return translations[value.toLowerCase()] ?? value;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_animal == null) {
      return _buildErrorState();
    }

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Image header với parallax
              _buildImageHeader(),

              // Content
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildTitleSection(),
                      _buildQuickStats(),
                      _buildMainContent(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating buttons
          _buildFloatingButtons(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.category.gradient,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Không tìm thấy thông tin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    final imageUrl = _animal!['image_url'] ?? '';

    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      leading: const SizedBox.shrink(),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image hoặc gradient
            imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildGradientPlaceholder();
              },
            )
                : _buildGradientPlaceholder(),

            // Gradient overlay để text dễ đọc
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
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
          colors: widget.category.gradient,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.category.icon,
              size: 120,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có hình ảnh',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            _buildGlassButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),

            Row(
              children: [
                // Share button
                _buildGlassButton(
                  icon: Icons.share,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chia sẻ...')),
                    );
                  },
                ),
                const SizedBox(width: 12),

                // Favorite button
                _buildGlassButton(
                  icon: Icons.favorite_border,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã thêm vào yêu thích')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap}) {
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
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    final nameVi = _animal!['name_vietnamese'] ?? 'Chưa có tên';
    final nameEn = _animal!['name_english'] ?? '';
    final scientificName = _animal!['scientific_name'] ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
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
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.category.gradient[0],
            ),
          ),
          if (scientificName.isNotEmpty) ...[
            const SizedBox(height: 6),
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
      ),
    );
  }

  Widget _buildQuickStats() {
    final weightAvg = _animal!['weight_avg_kg'] ?? 0;
    final heightAvg = _animal!['height_avg_m'] ?? 0;
    final lifespanAvg = _animal!['lifespan_avg_years'] ?? 0;
    final maxSpeed = _animal!['max_speed_kmh'] ?? 0;

    final stats = <Map<String, dynamic>>[];

    if (weightAvg > 0) {
      stats.add({
        'icon': Icons.fitness_center,
        'value': '${weightAvg.toStringAsFixed(0)} kg',
        'label': 'Cân nặng',
      });
    }

    if (heightAvg > 0) {
      stats.add({
        'icon': Icons.height,
        'value': '${heightAvg.toStringAsFixed(1)} m',
        'label': 'Chiều cao',
      });
    }

    if (lifespanAvg > 0) {
      stats.add({
        'icon': Icons.schedule,
        'value': '$lifespanAvg năm',
        'label': 'Tuổi thọ',
      });
    }

    if (maxSpeed > 0) {
      stats.add({
        'icon': Icons.speed,
        'value': '$maxSpeed km/h',
        'label': 'Tốc độ tối đa',
      });
    }

    if (stats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: stats.map((stat) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildStatCard(
                icon: stat['icon'],
                value: stat['value'],
                label: stat['label'],
              ),
            ),
          );
        }).toList(),
      ),
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
          Icon(icon, color: widget.category.gradient[0], size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
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

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDescription(),
          const SizedBox(height: 24),
          _buildCharacteristics(),
          const SizedBox(height: 24),
          _buildPhysicalTraits(),
          const SizedBox(height: 24),
          _buildHabitat(),
          const SizedBox(height: 24),
          _buildConservation(),
          const SizedBox(height: 24),
          _buildTaxonomy(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    final description = _animal!['description_short'] ?? '';
    final funFact = _animal!['fun_fact_vietnamese'] ?? '';

    // Nếu không có description, tạo description từ các thuộc tính
    String finalDescription = description;
    if (finalDescription.isEmpty) {
      finalDescription = _generateDescription();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Giới thiệu', Icons.info_outline),
        const SizedBox(height: 12),

        if (finalDescription.isNotEmpty) ...[
          Text(
            finalDescription,
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (funFact.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFBBF24), width: 1),
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

  // Tạo description từ các thuộc tính nếu không có description_short
  String _generateDescription() {
    final nameVi = _animal!['name_vietnamese'] ?? '';
    final habitat = _translateValue('habitat', _animal!['primary_habitat'] ?? '');
    final dietType = _translateValue('diet', _animal!['diet_type'] ?? '');
    final temperament = _translateValue('temperament', _animal!['temperament'] ?? '');
    final conservationStatus = _translateValue('conservation', _animal!['conservation_status'] ?? '');

    List<String> parts = [];

    if (nameVi.isNotEmpty) {
      parts.add('$nameVi là một loài động vật');

      if (habitat.isNotEmpty) {
        parts.add('sống chủ yếu ở môi trường $habitat');
      }

      if (dietType.isNotEmpty) {
        parts.add('với chế độ ăn $dietType');
      }

      if (temperament.isNotEmpty) {
        parts.add('và có tính cách $temperament');
      }

      if (conservationStatus.isNotEmpty) {
        parts.add('Tình trạng bảo tồn hiện tại: $conservationStatus');
      }
    }

    return parts.isNotEmpty ? parts.join('. ') + '.' : '';
  }

  Widget _buildCharacteristics() {
    final temperament = _animal!['temperament'] ?? '';
    final socialStructure = _animal!['social_structure'] ?? '';
    final activityPattern = _animal!['activity_pattern'] ?? '';
    final dietType = _animal!['diet_type'] ?? '';
    final dangerLevel = _animal!['danger_to_humans'] ?? '';

    final traits = <Map<String, String>>[];

    if (temperament.isNotEmpty) {
      traits.add({
        'icon': '🎭',
        'label': 'Tính cách',
        'value': _translateValue('temperament', temperament),
      });
    }

    if (socialStructure.isNotEmpty) {
      traits.add({
        'icon': '👥',
        'label': 'Cấu trúc xã hội',
        'value': _translateValue('social', socialStructure),
      });
    }

    if (activityPattern.isNotEmpty) {
      traits.add({
        'icon': '🌓',
        'label': 'Hoạt động',
        'value': _translateValue('activity', activityPattern),
      });
    }

    if (dietType.isNotEmpty) {
      traits.add({
        'icon': '🍽️',
        'label': 'Chế độ ăn',
        'value': _translateValue('diet', dietType),
      });
    }

    if (dangerLevel.isNotEmpty) {
      traits.add({
        'icon': '⚠️',
        'label': 'Mức độ nguy hiểm',
        'value': _translateValue('danger', dangerLevel),
      });
    }

    if (traits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Đặc điểm', Icons.stars),
        const SizedBox(height: 12),
        ...traits.map((trait) => _buildTraitRow(
          emoji: trait['icon']!,
          label: trait['label']!,
          value: trait['value']!,
        )).toList(),
      ],
    );
  }

  Widget _buildPhysicalTraits() {
    final colors = (_animal!['primary_colors'] as List? ?? [])
        .map((c) => _translateValue('color', c.toString()))
        .join(', ');
    final patterns = (_animal!['patterns'] as List? ?? [])
        .map((p) => _translateValue('pattern', p.toString()))
        .join(', ');
    final furType = _translateValue('fur', _animal!['fur_type'] ?? '');
    final hasClaws = _animal!['has_claws'] ?? false;
    final hasSharpTeeth = _animal!['has_sharp_teeth'] ?? false;
    final hasTail = _animal!['has_tail'] ?? false;
    final hasHorns = _animal!['has_horns'] ?? false;

    final traits = <String>[];
    if (colors.isNotEmpty) traits.add('🎨 Màu sắc: $colors');
    if (patterns.isNotEmpty) traits.add('🦓 Vân: $patterns');
    if (furType.isNotEmpty) traits.add('🧥 $furType');
    if (hasClaws) traits.add('🦅 Có móng vuốt sắc');
    if (hasSharpTeeth) traits.add('🦷 Có nanh sắc');
    if (hasTail) traits.add('🦎 Có đuôi');
    if (hasHorns) traits.add('🦌 Có sừng');

    if (traits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ngoại hình', Icons.brush),
        const SizedBox(height: 12),
        ...traits.map((trait) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            trait,
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildHabitat() {
    final habitat = _translateValue('habitat', _animal!['primary_habitat'] ?? '');
    final regions = (_animal!['geographic_regions'] as List? ?? []).join(', ');

    if (habitat.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Môi trường sống', Icons.public),
        const SizedBox(height: 12),
        _buildTraitRow(
          emoji: '🌍',
          label: 'Môi trường',
          value: habitat,
        ),
        if (regions.isNotEmpty)
          _buildTraitRow(
            emoji: '📍',
            label: 'Khu vực',
            value: regions,
          ),
      ],
    );
  }

  Widget _buildConservation() {
    final conservationStatus = _animal!['conservation_status'] ?? '';
    final isEndangered = _animal!['is_endangered'] ?? false;

    if (conservationStatus.isEmpty) return const SizedBox.shrink();

    final statusVi = _translateValue('conservation', conservationStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tình trạng bảo tồn', Icons.eco),
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
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusVi,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isEndangered
                            ? const Color(0xFF991B1B)
                            : const Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEndangered
                          ? 'Loài này đang bị đe dọa tuyệt chủng'
                          : 'Tình trạng quần thể ổn định',
                      style: TextStyle(
                        fontSize: 14,
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
    final genus = _animal!['genus'] ?? '';

    final items = <Map<String, String>>[];
    if (kingdom.isNotEmpty) items.add({'label': 'Giới', 'value': kingdom});
    if (phylum.isNotEmpty) items.add({'label': 'Ngành', 'value': phylum});
    if (classValue.isNotEmpty) items.add({'label': 'Lớp', 'value': classValue});
    if (orderName.isNotEmpty) items.add({'label': 'Bộ', 'value': orderName});
    if (family.isNotEmpty) items.add({'label': 'Họ', 'value': family});
    if (genus.isNotEmpty) items.add({'label': 'Chi', 'value': genus});

    if (items.isEmpty) return const SizedBox.shrink();

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
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['label']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item['value']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade300, height: 1),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.category.gradient),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
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

  Widget _buildTraitRow({
    required String emoji,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}