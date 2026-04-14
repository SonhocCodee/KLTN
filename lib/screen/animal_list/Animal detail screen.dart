import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../services/animal_home_service.dart';
import '../home/animal_category_model.dart';

// ═══════════════════════════════════════════════════════════════
// DATA / LOGIC — KHÔNG THAY ĐỔI GÌ Ở ĐÂY
// ═══════════════════════════════════════════════════════════════

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

class _AnimalDetailScreenState extends State<AnimalDetailScreen>
    with TickerProviderStateMixin {
  final AnimalHomeService _service = AnimalHomeService();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _animal;
  bool _isLoading = true;
  bool _showFullImage = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _loadAnimalDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ══ DATA — GIỮ NGUYÊN 100% ══════════════════════════════════

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
        _fadeController.forward();
        _slideController.forward();
      }
    } catch (e) {
      print('❌ Error loading animal details: $e');
      setState(() => _isLoading = false);
    }
  }

  String _translateValue(String key, String value) {
    final translations = {
      'gentle': 'Hiền lành', 'neutral': 'Trung tính', 'aggressive': 'Hung dữ',
      'timid': 'Nhút nhát', 'territorial': 'Bảo vệ lãnh thổ',
      'solitary': 'Sống đơn độc', 'pair': 'Sống theo cặp',
      'small_group': 'Nhóm nhỏ', 'herd': 'Bầy đàn', 'pack': 'Đàn săn mồi',
      'colony': 'Thuộc địa', 'pride': 'Bầy (sư tử)',
      'nocturnal': 'Hoạt động ban đêm', 'diurnal': 'Hoạt động ban ngày',
      'crepuscular': 'Hoạt động lúc chạng vạng', 'cathemeral': 'Cả ngày lẫn đêm',
      'carnivore': 'Ăn thịt', 'herbivore': 'Ăn cỏ', 'omnivore': 'Ăn tạp',
      'insectivore': 'Ăn côn trùng', 'piscivore': 'Ăn cá',
      'savanna': 'Thảo nguyên', 'tropical_forest': 'Rừng nhiệt đới',
      'temperate_forest': 'Rừng ôn đới', 'desert': 'Sa mạc', 'tundra': 'Đồng băng',
      'mountain': 'Núi cao', 'ocean': 'Đại dương', 'freshwater': 'Nước ngọt',
      'wetland': 'Đất ngập nước', 'grassland': 'Đồng cỏ', 'forest': 'Rừng',
      'domestic': 'Nhà nuôi',
      'Domesticated': 'Đã thuần hóa', 'Least Concern': 'Ít quan tâm',
      'Near Threatened': 'Sắp bị đe dọa', 'Vulnerable': 'Sắp nguy cấp',
      'Endangered': 'Nguy cấp', 'Critically Endangered': 'Cực kỳ nguy cấp',
      'Extinct in Wild': 'Tuyệt chủng ngoài tự nhiên', 'Extinct': 'Đã tuyệt chủng',
      'harmless': 'Không nguy hiểm', 'low': 'Ít nguy hiểm', 'moderate': 'Trung bình',
      'high': 'Nguy hiểm', 'dangerous': 'Rất nguy hiểm', 'extreme': 'Cực kỳ nguy hiểm',
      'black': 'Đen', 'white': 'Trắng', 'brown': 'Nâu', 'gray': 'Xám',
      'grey': 'Xám', 'orange': 'Cam', 'yellow': 'Vàng', 'tan': 'Hung vàng',
      'red': 'Đỏ', 'blue': 'Xanh dương', 'green': 'Xanh lá',
      'solid': 'Đồng nhất', 'striped': 'Sọc', 'spotted': 'Đốm', 'patches': 'Vảy',
      'short_fur': 'Lông ngắn', 'long_fur': 'Lông dài', 'thick_fur': 'Lông dày',
      'scales': 'Vảy', 'feathers': 'Lông vũ', 'smooth_skin': 'Da mịn',
      'thick_skin': 'Da dày',
    };
    return translations[value.toLowerCase()] ?? value;
  }

  String _generateDescription() {
    final nameVi = _animal!['name_vietnamese'] ?? '';
    final habitat = _translateValue('habitat', _animal!['primary_habitat'] ?? '');
    final dietType = _translateValue('diet', _animal!['diet_type'] ?? '');
    final temperament = _translateValue('temperament', _animal!['temperament'] ?? '');
    final conservationStatus =
    _translateValue('conservation', _animal!['conservation_status'] ?? '');
    List<String> parts = [];
    if (nameVi.isNotEmpty) {
      parts.add('$nameVi là một loài động vật');
      if (habitat.isNotEmpty) parts.add('sống chủ yếu ở môi trường $habitat');
      if (dietType.isNotEmpty) parts.add('với chế độ ăn $dietType');
      if (temperament.isNotEmpty) parts.add('và có tính cách $temperament');
      if (conservationStatus.isNotEmpty)
        parts.add('Tình trạng bảo tồn hiện tại: $conservationStatus');
    }
    return parts.isNotEmpty ? parts.join('. ') + '.' : '';
  }

  // ══ UI BUILD ════════════════════════════════════════════════

  // Màu sắc thiết kế — trắng sạch kiểu tạp chí khoa học tự nhiên
  static const _bg        = Color(0xFFFAFAF8);       // Trắng ngà nhẹ
  static const _surface   = Colors.white;
  static const _ink       = Color(0xFF1A1A18);        // Gần đen, ấm
  static const _inkLight  = Color(0xFF5C5C58);        // Xám trung
  static const _inkMuted  = Color(0xFF9C9C96);        // Xám nhạt
  static const _rule      = Color(0xFFE8E8E4);        // Đường kẻ mờ
  static const _accent    = Color(0xFF2D6A4F);        // Xanh rừng — nature science

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingState();
    if (_animal == null) return _buildErrorState();

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildImageHeader(),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleSection(),
                        _buildQuickStats(),
                        const SizedBox(height: 8),
                        _buildDividerRule(),
                        _buildMainContent(),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          _buildFloatingButtons(),
        ],
      ),
    );
  }

  // ── Loading ─────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: widget.category.gradient[0],
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Đang tải...',
              style: TextStyle(
                color: _inkMuted,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 64, color: _inkMuted),
              const SizedBox(height: 16),
              const Text(
                'Không tìm thấy thông tin',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Loài này chưa có dữ liệu trong hệ thống',
                style: TextStyle(fontSize: 13, color: _inkMuted),
              ),
              const SizedBox(height: 28),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Quay lại',
                  style: TextStyle(color: _accent, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Ảnh đầu trang ───────────────────────────────────────────
  Widget _buildImageHeader() {
    final imageUrl = _animal!['image_url'] ?? '';

    return SliverAppBar(
      expandedHeight: 420,
      pinned: true,
      elevation: 0,
      backgroundColor: _bg,
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
            // Gradient mờ dần xuống
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.55, 1.0],
                  colors: [
                    Colors.black.withOpacity(0.22),
                    Colors.transparent,
                    _bg,
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
              size: 100,
              color: Colors.white.withOpacity(0.35),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có hình ảnh',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Nút floating (back + share) ─────────────────────────────
  Widget _buildFloatingButtons() {
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
            // YÊU CẦU: bỏ tim, chỉ giữ nút chia sẻ
            _buildGlassButton(
              icon: Icons.ios_share_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chia sẻ...')),
                );
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
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  // ── Title section ────────────────────────────────────────────
  Widget _buildTitleSection() {
    final nameVi       = _animal!['name_vietnamese'] ?? 'Chưa có tên';
    final nameEn       = _animal!['name_english'] ?? '';
    final scientificName = _animal!['scientific_name'] ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category label nhỏ trên cùng
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.category.gradient[0].withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.category.nameVi.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: widget.category.gradient[0],
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tên tiếng Việt — to nhất
          Text(
            nameVi,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: _ink,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),

          if (nameEn.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              nameEn,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: widget.category.gradient[0],
                letterSpacing: 0.1,
              ),
            ),
          ],

          if (scientificName.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              scientificName,
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: _inkMuted,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Quick stats — 4 số ──────────────────────────────────────
  Widget _buildQuickStats() {
    final weightAvg  = _animal!['weight_avg_kg'] ?? 0;
    final heightAvg  = _animal!['height_avg_m'] ?? 0;
    final lifespanAvg = _animal!['lifespan_avg_years'] ?? 0;
    final maxSpeed   = _animal!['max_speed_kmh'] ?? 0;

    final stats = <Map<String, dynamic>>[];
    if (weightAvg > 0)   stats.add({'emoji': '⚖️', 'value': '${weightAvg.toStringAsFixed(0)} kg', 'label': 'Cân nặng'});
    if (heightAvg > 0)   stats.add({'emoji': '📏', 'value': '${heightAvg.toStringAsFixed(1)} m',  'label': 'Chiều cao'});
    if (lifespanAvg > 0) stats.add({'emoji': '🕰️', 'value': '$lifespanAvg năm',                  'label': 'Tuổi thọ'});
    if (maxSpeed > 0)    stats.add({'emoji': '💨', 'value': '$maxSpeed km/h',                     'label': 'Tốc độ tối đa'});

    if (stats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: stats.asMap().entries.map((entry) {
          final i    = entry.key;
          final stat = entry.value;
          final isLast = i == stats.length - 1;
          return Expanded(
            child: Row(
              children: [
                Expanded(child: _buildStatTile(stat['emoji'], stat['value'], stat['label'])),
                if (!isLast)
                  Container(width: 1, height: 40, color: _rule, margin: const EdgeInsets.symmetric(horizontal: 4)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatTile(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _rule),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: _inkMuted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Đường kẻ phân cách ──────────────────────────────────────
  Widget _buildDividerRule() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        children: [
          Container(width: 32, height: 2, color: _accent),
          const SizedBox(width: 6),
          Expanded(child: Container(height: 1, color: _rule)),
        ],
      ),
    );
  }

  // ── Main content sections ────────────────────────────────────
  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDescription(),
          _buildSectionGap(),
          _buildCharacteristics(),
          _buildSectionGap(),
          _buildPhysicalTraits(),
          _buildSectionGap(),
          _buildHabitat(),
          _buildSectionGap(),
          _buildConservation(),
          _buildSectionGap(),
          _buildTaxonomy(),
        ],
      ),
    );
  }

  Widget _buildSectionGap() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Container(height: 1, color: _rule),
  );

  // ── Tiêu đề mục — thiết kế tạp chí khoa học ────────────────
  Widget _buildSectionTitle(String title, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _ink,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ── Giới thiệu ──────────────────────────────────────────────
  Widget _buildDescription() {
    final description = _animal!['description_short'] ?? '';
    final funFact     = _animal!['fun_fact_vietnamese'] ?? '';
    final finalDesc   = description.isNotEmpty ? description : _generateDescription();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Giới thiệu', '📖'),
        const SizedBox(height: 14),

        if (finalDesc.isNotEmpty) ...[
          Text(
            finalDesc,
            style: const TextStyle(
              fontSize: 15,
              height: 1.75,
              color: _inkLight,
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (funFact.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Có thể bạn chưa biết',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        funFact,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF78350F),
                          height: 1.6,
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

  // ── Đặc điểm hành vi ────────────────────────────────────────
  Widget _buildCharacteristics() {
    final temperament    = _animal!['temperament'] ?? '';
    final socialStructure = _animal!['social_structure'] ?? '';
    final activityPattern = _animal!['activity_pattern'] ?? '';
    final dietType       = _animal!['diet_type'] ?? '';
    final dangerLevel    = _animal!['danger_to_humans'] ?? '';

    final traits = <Map<String, String>>[];
    if (temperament.isNotEmpty)     traits.add({'icon': '🎭', 'label': 'Tính cách',           'value': _translateValue('temperament', temperament)});
    if (socialStructure.isNotEmpty) traits.add({'icon': '👥', 'label': 'Cấu trúc xã hội',    'value': _translateValue('social', socialStructure)});
    if (activityPattern.isNotEmpty) traits.add({'icon': '🌓', 'label': 'Chu kỳ hoạt động',   'value': _translateValue('activity', activityPattern)});
    if (dietType.isNotEmpty)        traits.add({'icon': '🍽️', 'label': 'Chế độ ăn',          'value': _translateValue('diet', dietType)});
    if (dangerLevel.isNotEmpty)     traits.add({'icon': '⚠️', 'label': 'Mức độ nguy hiểm',   'value': _translateValue('danger', dangerLevel)});

    if (traits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Đặc điểm & Hành vi', '🔬'),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _rule),
          ),
          child: Column(
            children: traits.asMap().entries.map((entry) {
              final i     = entry.key;
              final trait = entry.value;
              final isLast = i == traits.length - 1;
              return _buildTableRow(
                icon: trait['icon']!,
                label: trait['label']!,
                value: trait['value']!,
                isLast: isLast,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Ngoại hình ──────────────────────────────────────────────
  Widget _buildPhysicalTraits() {
    final colors = (_animal!['primary_colors'] as List? ?? [])
        .map((c) => _translateValue('color', c.toString()))
        .join(', ');
    final patterns = (_animal!['patterns'] as List? ?? [])
        .map((p) => _translateValue('pattern', p.toString()))
        .join(', ');
    final furType      = _translateValue('fur', _animal!['fur_type'] ?? '');
    final hasClaws     = _animal!['has_claws'] ?? false;
    final hasSharpTeeth = _animal!['has_sharp_teeth'] ?? false;
    final hasTail      = _animal!['has_tail'] ?? false;
    final hasHorns     = _animal!['has_horns'] ?? false;

    final rows = <Map<String, String>>[];
    if (colors.isNotEmpty)   rows.add({'icon': '🎨', 'label': 'Màu sắc',    'value': colors});
    if (patterns.isNotEmpty) rows.add({'icon': '🦓', 'label': 'Hoa văn',    'value': patterns});
    if (furType.isNotEmpty)  rows.add({'icon': '🧥', 'label': 'Lông / da',  'value': furType});

    final bool hasFeatures = hasClaws || hasSharpTeeth || hasTail || hasHorns;
    final featureList = <String>[];
    if (hasClaws)      featureList.add('Móng vuốt sắc');
    if (hasSharpTeeth) featureList.add('Nanh/răng sắc');
    if (hasTail)       featureList.add('Có đuôi');
    if (hasHorns)      featureList.add('Có sừng');
    if (hasFeatures)   rows.add({'icon': '🦴', 'label': 'Đặc điểm cơ thể', 'value': featureList.join(' · ')});

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ngoại hình', '👁️'),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _rule),
          ),
          child: Column(
            children: rows.asMap().entries.map((entry) {
              final i    = entry.key;
              final row  = entry.value;
              return _buildTableRow(
                icon: row['icon']!,
                label: row['label']!,
                value: row['value']!,
                isLast: i == rows.length - 1,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Môi trường sống ─────────────────────────────────────────
  Widget _buildHabitat() {
    final habitat = _translateValue('habitat', _animal!['primary_habitat'] ?? '');
    final regions = (_animal!['geographic_regions'] as List? ?? []).join(', ');

    if (habitat.isEmpty) return const SizedBox.shrink();

    final rows = <Map<String, String>>[
      {'icon': '🌍', 'label': 'Môi trường', 'value': habitat},
      if (regions.isNotEmpty) {'icon': '📍', 'label': 'Khu vực phân bổ', 'value': regions},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Môi trường sống', '🌿'),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _rule),
          ),
          child: Column(
            children: rows.asMap().entries.map((e) => _buildTableRow(
              icon: e.value['icon']!,
              label: e.value['label']!,
              value: e.value['value']!,
              isLast: e.key == rows.length - 1,
            )).toList(),
          ),
        ),
      ],
    );
  }

  // ── Tình trạng bảo tồn ──────────────────────────────────────
  Widget _buildConservation() {
    final conservationStatus = _animal!['conservation_status'] ?? '';
    if (conservationStatus.isEmpty) return const SizedBox.shrink();

    final isEndangered = _animal!['is_endangered'] ?? false;
    final statusVi     = _translateValue('conservation', conservationStatus);

    final Color statusColor  = isEndangered ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final Color bgColor      = isEndangered ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final Color borderColor  = isEndangered ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC);
    final String statusIcon  = isEndangered ? '🔴' : '🟢';
    final String statusDesc  = isEndangered
        ? 'Loài này đang đối mặt với nguy cơ tuyệt chủng'
        : 'Quần thể ổn định, không bị đe dọa nghiêm trọng';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tình trạng bảo tồn', '🛡️'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Text(statusIcon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusVi,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusDesc,
                      style: TextStyle(
                        fontSize: 13,
                        color: statusColor.withOpacity(0.8),
                        height: 1.4,
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

  // ── Phân loại khoa học ──────────────────────────────────────
  Widget _buildTaxonomy() {
    final kingdom    = _animal!['kingdom'] ?? '';
    final phylum     = _animal!['phylum'] ?? '';
    final classValue = _animal!['class'] ?? '';
    final orderName  = _animal!['order_name'] ?? '';
    final family     = _animal!['family'] ?? '';
    final genus      = _animal!['genus'] ?? '';

    final items = <Map<String, String>>[];
    if (kingdom.isNotEmpty)    items.add({'icon': '🌐', 'label': 'Giới',    'value': kingdom});
    if (phylum.isNotEmpty)     items.add({'icon': '🔗', 'label': 'Ngành',   'value': phylum});
    if (classValue.isNotEmpty) items.add({'icon': '📦', 'label': 'Lớp',     'value': classValue});
    if (orderName.isNotEmpty)  items.add({'icon': '📂', 'label': 'Bộ',      'value': orderName});
    if (family.isNotEmpty)     items.add({'icon': '🏷️', 'label': 'Họ',     'value': family});
    if (genus.isNotEmpty)      items.add({'icon': '🔍', 'label': 'Chi',     'value': genus});

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Phân loại khoa học', '🔭'),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _rule),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i    = entry.key;
              final item = entry.value;
              return _buildTaxonomyRow(
                icon:   item['icon']!,
                rank:   item['label']!,
                name:   item['value']!,
                depth:  i,
                isLast: i == items.length - 1,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Nguồn: Hệ thống phân loại sinh vật học hiện đại',
            style: TextStyle(
              fontSize: 11,
              color: _inkMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // ── Table row — dùng chung nhiều mục ────────────────────────
  Widget _buildTableRow({
    required String icon,
    required String label,
    required String value,
    required bool isLast,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _inkMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _ink,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 46, color: _rule),
      ],
    );
  }

  // ── Taxonomy row — có thụt lề phân cấp ──────────────────────
  Widget _buildTaxonomyRow({
    required String icon,
    required String rank,
    required String name,
    required int depth,
    required bool isLast,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: 16.0 + depth * 4.0,
            right: 16,
            top: 12,
            bottom: 12,
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 10),
              Text(
                rank,
                style: TextStyle(
                  fontSize: 12,
                  color: _inkMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontStyle: depth >= 5 ? FontStyle.italic : FontStyle.normal,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 16.0 + (depth + 1) * 4.0, color: _rule),
      ],
    );
  }
}