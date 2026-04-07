import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ═══════════════════════════════════════════════════════════════════
// CẤU HÌNH LOÀI — map đúng tên bảng trong DB
// ═══════════════════════════════════════════════════════════════════

class AnimalTypeConfig {
  final String key;         // key nội bộ
  final String dbTable;     // tên bảng thực trong Supabase
  final String animalType;  // giá trị của cột animal_type trong DB
  final String emoji;
  final String nameVi;
  final String nameEn;
  final List<QuestionConfig> questions;

  const AnimalTypeConfig({
    required this.key,
    required this.dbTable,
    required this.animalType,
    required this.emoji,
    required this.nameVi,
    required this.nameEn,
    required this.questions,
  });
}

// ── CẤU HÌNH MÈO — câu hỏi dựa hoàn toàn vào quan sát ──
const _catConfig = AnimalTypeConfig(
  key: 'cat',
  dbTable: 'cats',
  animalType: 'cat',
  emoji: '🐱',
  nameVi: 'Mèo',
  nameEn: 'Cat',
  questions: [
    // Q1: Màu lông — nhìn thấy ngay
    QuestionConfig(
      id: 'primary_colors',
      question: 'Lông màu gì?',
      emoji: '🎨',
      column: 'primary_colors',
      isArray: true,
      options: [
        OptionConfig(label: 'Trắng', emoji: '⚪', value: 'white'),
        OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
        OptionConfig(label: 'Cam / Vàng', emoji: '🟠', value: 'orange'),
        OptionConfig(label: 'Xám / Xanh', emoji: '🔘', value: 'gray'),
        OptionConfig(label: 'Nâu / Kem', emoji: '🟤', value: 'cream'),
      ],
    ),
    // Q2: Độ dài lông — nhìn thấy ngay
    QuestionConfig(
      id: 'coat_length',
      question: 'Lông dài hay ngắn?',
      emoji: '✂️',
      column: 'coat_length',
      options: [
        OptionConfig(label: 'Không lông', emoji: '🫥', value: 'hairless'),
        OptionConfig(label: 'Ngắn', emoji: '📏', value: 'short'),
        OptionConfig(label: 'Trung bình', emoji: '📐', value: 'medium'),
        OptionConfig(label: 'Dài / Rất dài', emoji: '🧶', value: 'long'),
      ],
    ),
    // Q3: Hoa văn — nhìn thấy ngay
    QuestionConfig(
      id: 'patterns',
      question: 'Có hoa văn không?',
      emoji: '🎭',
      column: 'patterns',
      isArray: true,
      options: [
        OptionConfig(label: 'Trơn (1 màu)', emoji: '⬜', value: 'solid'),
        OptionConfig(label: 'Vằn (tabby)', emoji: '🦓', value: 'tabby'),
        OptionConfig(label: 'Hai màu', emoji: '⬛', value: 'bicolor'),
        OptionConfig(label: 'Đốm', emoji: '🔵', value: 'spotted'),
        OptionConfig(label: 'Tam thể', emoji: '🌈', value: 'calico'),
      ],
    ),
    // Q4: Tai — nhìn thấy ngay
    QuestionConfig(
      id: 'has_floppy_ears',
      question: 'Tai như thế nào?',
      emoji: '👂',
      column: 'has_floppy_ears',
      isBool: true,
      options: [
        OptionConfig(label: 'Tai cụp / xệ', emoji: '🐱', value: true),
        OptionConfig(label: 'Tai dựng nhọn', emoji: '🦊', value: false),
      ],
    ),
    // Q5: Bông xù — nhìn thấy ngay
    QuestionConfig(
      id: 'is_fluffy',
      question: 'Lông có bông xù không?',
      emoji: '☁️',
      column: 'is_fluffy',
      isBool: true,
      options: [
        OptionConfig(label: 'Rất bông xù', emoji: '☁️', value: true),
        OptionConfig(label: 'Không xù', emoji: '🪶', value: false),
      ],
    ),
    // Q6: Kích thước cơ thể — nhìn thấy
    QuestionConfig(
      id: 'size_category',
      question: 'Con to hay nhỏ?',
      emoji: '📏',
      column: 'size_category',
      options: [
        OptionConfig(label: 'Rất nhỏ (< 3kg)', emoji: '🐭', value: 'small'),
        OptionConfig(label: 'Trung bình', emoji: '🐱', value: 'medium'),
        OptionConfig(label: 'To lớn (> 6kg)', emoji: '🦁', value: 'large'),
      ],
    ),
    // Q7: Đuôi — nhìn thấy
    QuestionConfig(
      id: 'has_long_tail',
      question: 'Đuôi dài hay ngắn?',
      emoji: '〰️',
      column: 'has_long_tail',
      isBool: true,
      options: [
        OptionConfig(label: 'Đuôi dài', emoji: '〰️', value: true),
        OptionConfig(label: 'Đuôi ngắn / cụt', emoji: '✂️', value: false),
      ],
    ),
  ],
);

// ── CẤU HÌNH CHÓ — câu hỏi quan sát được ──
const _dogConfig = AnimalTypeConfig(
  key: 'dog',
  dbTable: 'dogs',
  animalType: 'dog',
  emoji: '🐶',
  nameVi: 'Chó',
  nameEn: 'Dog',
  questions: [
    // Q1: Kích thước — quan sát rõ nhất
    QuestionConfig(
      id: 'size_category',
      question: 'Con to hay nhỏ?',
      emoji: '📏',
      column: 'size_category',
      options: [
        OptionConfig(label: 'Rất nhỏ (< 5kg)', emoji: '🐾', value: 'small'),
        OptionConfig(label: 'Vừa (5–20kg)', emoji: '🐕', value: 'medium'),
        OptionConfig(label: 'To (20–40kg)', emoji: '🦮', value: 'large'),
        OptionConfig(label: 'Khổng lồ (> 40kg)', emoji: '🐻', value: 'giant'),
      ],
    ),
    // Q2: Màu lông
    QuestionConfig(
      id: 'primary_colors',
      question: 'Lông màu gì?',
      emoji: '🎨',
      column: 'primary_colors',
      isArray: true,
      options: [
        OptionConfig(label: 'Trắng', emoji: '⚪', value: 'white'),
        OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
        OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
        OptionConfig(label: 'Vàng / Vàng đậm', emoji: '🟡', value: 'golden'),
        OptionConfig(label: 'Xám', emoji: '🔘', value: 'gray'),
      ],
    ),
    // Q3: Độ dài lông
    QuestionConfig(
      id: 'coat_length',
      question: 'Lông ngắn hay dài?',
      emoji: '✂️',
      column: 'coat_length',
      options: [
        OptionConfig(label: 'Ngắn sát', emoji: '📏', value: 'short'),
        OptionConfig(label: 'Trung bình', emoji: '📐', value: 'medium'),
        OptionConfig(label: 'Dài', emoji: '🧶', value: 'long'),
      ],
    ),
    // Q4: Tai
    QuestionConfig(
      id: 'has_floppy_ears',
      question: 'Tai như thế nào?',
      emoji: '👂',
      column: 'has_floppy_ears',
      isBool: true,
      options: [
        OptionConfig(label: 'Tai cụp / xệ', emoji: '🐶', value: true),
        OptionConfig(label: 'Tai dựng nhọn', emoji: '🦊', value: false),
      ],
    ),
    // Q5: Hoa văn / đốm
    QuestionConfig(
      id: 'patterns',
      question: 'Lông có hoa văn không?',
      emoji: '🎭',
      column: 'patterns',
      isArray: true,
      options: [
        OptionConfig(label: 'Trơn (1 màu)', emoji: '⬜', value: 'solid'),
        OptionConfig(label: 'Hai màu', emoji: '⬛', value: 'bicolor'),
        OptionConfig(label: 'Đốm / vá', emoji: '🔵', value: 'spotted'),
        OptionConfig(label: 'Vằn', emoji: '🦓', value: 'brindle'),
      ],
    ),
    // Q6: Bờm / mane
    QuestionConfig(
      id: 'has_mane',
      question: 'Có bờm lông quanh cổ không?',
      emoji: '🦁',
      column: 'has_mane',
      isBool: true,
      options: [
        OptionConfig(label: 'Có bờm lông dày', emoji: '🦁', value: true),
        OptionConfig(label: 'Không có', emoji: '🐕', value: false),
      ],
    ),
  ],
);

// ── CẤU HÌNH THÚ HOANG — query bảng "animals" theo animal_type ──
AnimalTypeConfig _makeWildConfig({
  required String key,
  required String animalType,
  required String emoji,
  required String nameVi,
  required String nameEn,
  required List<QuestionConfig> questions,
}) => AnimalTypeConfig(
  key: key,
  dbTable: 'animals',
  animalType: animalType,
  emoji: emoji,
  nameVi: nameVi,
  nameEn: nameEn,
  questions: questions,
);

// Danh sách tất cả loài
final List<AnimalTypeConfig> allAnimalTypes = [
  _catConfig,
  _dogConfig,
  _makeWildConfig(
    key: 'buffalo',
    animalType: 'buffalo',
    emoji: '🐃',
    nameVi: 'Trâu',
    nameEn: 'Buffalo',
    questions: const [
      QuestionConfig(
        id: 'primary_colors',
        question: 'Màu da / lông?',
        emoji: '🎨',
        column: 'primary_colors',
        isArray: true,
        options: [
          OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
          OptionConfig(label: 'Xám', emoji: '🔘', value: 'gray'),
          OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
        ],
      ),
      QuestionConfig(
        id: 'has_horns',
        question: 'Có sừng không?',
        emoji: '🦬',
        column: 'has_horns',
        isBool: true,
        options: [
          OptionConfig(label: 'Có sừng cong lớn', emoji: '🦬', value: true),
          OptionConfig(label: 'Không có sừng', emoji: '❌', value: false),
        ],
      ),
      QuestionConfig(
        id: 'relative_size',
        question: 'To bằng cỡ nào?',
        emoji: '📏',
        column: 'relative_size',
        options: [
          OptionConfig(label: 'Bằng bò', emoji: '🐃', value: 'large'),
          OptionConfig(label: 'To hơn bò nhiều', emoji: '🦬', value: 'elephant_sized'),
        ],
      ),
    ],
  ),
  _makeWildConfig(
    key: 'cattle',
    animalType: 'cattle',
    emoji: '🐄',
    nameVi: 'Bò',
    nameEn: 'Cattle',
    questions: const [
      QuestionConfig(
        id: 'primary_colors',
        question: 'Màu lông / da?',
        emoji: '🎨',
        column: 'primary_colors',
        isArray: true,
        options: [
          OptionConfig(label: 'Trắng', emoji: '⚪', value: 'white'),
          OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
          OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
          OptionConfig(label: 'Đỏ nâu', emoji: '🔴', value: 'red'),
        ],
      ),
      QuestionConfig(
        id: 'has_horns',
        question: 'Có sừng không?',
        emoji: '🐮',
        column: 'has_horns',
        isBool: true,
        options: [
          OptionConfig(label: 'Có sừng', emoji: '🐮', value: true),
          OptionConfig(label: 'Không sừng', emoji: '❌', value: false),
        ],
      ),
      QuestionConfig(
        id: 'patterns',
        question: 'Có đốm không?',
        emoji: '🎭',
        column: 'patterns',
        isArray: true,
        options: [
          OptionConfig(label: 'Trơn (1 màu)', emoji: '⬜', value: 'solid'),
          OptionConfig(label: 'Có đốm', emoji: '⚫', value: 'spotted'),
        ],
      ),
    ],
  ),
  _makeWildConfig(
    key: 'horse',
    animalType: 'horse',
    emoji: '🐴',
    nameVi: 'Ngựa',
    nameEn: 'Horse',
    questions: const [
      QuestionConfig(
        id: 'primary_colors',
        question: 'Màu lông?',
        emoji: '🎨',
        column: 'primary_colors',
        isArray: true,
        options: [
          OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
          OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
          OptionConfig(label: 'Trắng', emoji: '⚪', value: 'white'),
          OptionConfig(label: 'Xám', emoji: '🔘', value: 'gray'),
        ],
      ),
      QuestionConfig(
        id: 'patterns',
        question: 'Lông có đốm / hoa văn không?',
        emoji: '🎭',
        column: 'patterns',
        isArray: true,
        options: [
          OptionConfig(label: 'Trơn (1 màu)', emoji: '⬜', value: 'solid'),
          OptionConfig(label: 'Có đốm lớn', emoji: '⚫', value: 'pinto'),
          OptionConfig(label: 'Có vằn nhỏ', emoji: '🦓', value: 'striped'),
        ],
      ),
      QuestionConfig(
        id: 'has_mane',
        question: 'Bờm có dài rậm không?',
        emoji: '🦄',
        column: 'has_mane',
        isBool: true,
        options: [
          OptionConfig(label: 'Có bờm dài rậm', emoji: '🦄', value: true),
          OptionConfig(label: 'Bờm ngắn / cạo', emoji: '✂️', value: false),
        ],
      ),
      QuestionConfig(
        id: 'relative_size',
        question: 'To hay nhỏ?',
        emoji: '📏',
        column: 'relative_size',
        options: [
          OptionConfig(label: 'Nhỏ (Pony)', emoji: '🐴', value: 'large'),
          OptionConfig(label: 'To (ngựa đua)', emoji: '🏇', value: 'elephant_sized'),
        ],
      ),
    ],
  ),
  _makeWildConfig(
    key: 'bear',
    animalType: 'bear',
    emoji: '🐻',
    nameVi: 'Gấu',
    nameEn: 'Bear',
    questions: const [
      QuestionConfig(
        id: 'primary_colors',
        question: 'Màu lông?',
        emoji: '🎨',
        column: 'primary_colors',
        isArray: true,
        options: [
          OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
          OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
          OptionConfig(label: 'Trắng / Kem', emoji: '⚪', value: 'white'),
          OptionConfig(label: 'Đen + trắng', emoji: '◑', value: 'black_white'),
        ],
      ),
      QuestionConfig(
        id: 'relative_size',
        question: 'Con to cỡ nào?',
        emoji: '📏',
        column: 'relative_size',
        options: [
          OptionConfig(label: 'Bằng người lớn', emoji: '🐻', value: 'large'),
          OptionConfig(label: 'To hơn, rất nặng', emoji: '🦬', value: 'elephant_sized'),
        ],
      ),
      QuestionConfig(
        id: 'primary_habitat',
        question: 'Sống ở đâu?',
        emoji: '🌍',
        column: 'primary_habitat',
        options: [
          OptionConfig(label: 'Rừng lá rộng', emoji: '🌲', value: 'forest'),
          OptionConfig(label: 'Bắc Cực / tuyết', emoji: '❄️', value: 'arctic'),
          OptionConfig(label: 'Rừng nhiệt đới', emoji: '🌴', value: 'tropical_forest'),
          OptionConfig(label: 'Núi cao', emoji: '⛰️', value: 'mountain'),
        ],
      ),
    ],
  ),
  _makeWildConfig(
    key: 'lion',
    animalType: 'lion',
    emoji: '🦁',
    nameVi: 'Sư tử',
    nameEn: 'Lion',
    questions: const [
      QuestionConfig(
        id: 'has_mane',
        question: 'Có bờm quanh đầu không?',
        emoji: '🦁',
        column: 'has_mane',
        isBool: true,
        options: [
          OptionConfig(label: 'Có bờm dày (đực)', emoji: '🦁', value: true),
          OptionConfig(label: 'Không bờm (cái)', emoji: '🐆', value: false),
        ],
      ),
      QuestionConfig(
        id: 'primary_colors',
        question: 'Màu lông?',
        emoji: '🎨',
        column: 'primary_colors',
        isArray: true,
        options: [
          OptionConfig(label: 'Vàng / Vàng nhạt', emoji: '🟡', value: 'tan'),
          OptionConfig(label: 'Nâu vàng', emoji: '🟤', value: 'brown'),
          OptionConfig(label: 'Trắng (hiếm)', emoji: '⚪', value: 'white'),
        ],
      ),
      QuestionConfig(
        id: 'primary_habitat',
        question: 'Sống ở môi trường nào?',
        emoji: '🌍',
        column: 'primary_habitat',
        options: [
          OptionConfig(label: 'Đồng cỏ savanna', emoji: '🌾', value: 'savanna'),
          OptionConfig(label: 'Bụi rậm / rừng thưa', emoji: '🌿', value: 'shrubland'),
        ],
      ),
    ],
  ),
];

// ═══════════════════════════════════════════════════════════════════
// MODEL CÂU HỎI & LỰA CHỌN
// ═══════════════════════════════════════════════════════════════════

class QuestionConfig {
  final String id;
  final String question;
  final String emoji;
  final String column;
  final List<OptionConfig> options;
  final bool isArray;   // cột PostgreSQL ARRAY (primary_colors, patterns...)
  final bool isBool;    // cột boolean
  final bool isRange;   // dùng slider 1-5
  final String? minLabel;
  final String? maxLabel;

  const QuestionConfig({
    required this.id,
    required this.question,
    required this.emoji,
    required this.column,
    this.options = const [],
    this.isArray = false,
    this.isBool = false,
    this.isRange = false,
    this.minLabel,
    this.maxLabel,
  });
}

class OptionConfig {
  final String label;
  final String emoji;
  final dynamic value;

  const OptionConfig({
    required this.label,
    required this.emoji,
    required this.value,
  });
}

// ═══════════════════════════════════════════════════════════════════
// SMART QUIZ PAGE
// ═══════════════════════════════════════════════════════════════════

class SmartQuizPage extends StatefulWidget {
  const SmartQuizPage({Key? key}) : super(key: key);

  @override
  State<SmartQuizPage> createState() => _SmartQuizPageState();
}

class _SmartQuizPageState extends State<SmartQuizPage> {
  // State chính
  AnimalTypeConfig? _selectedConfig;
  int _questionIndex = 0;
  bool _isLoading = false;
  bool _showResults = false;

  // Bộ lọc tích lũy — key là tên cột, value là giá trị cần lọc
  final Map<String, dynamic> _filters = {};
  List<Map<String, dynamic>> _results = [];

  final _client = Supabase.instance.client;

  List<QuestionConfig> get _questions => _selectedConfig?.questions ?? [];
  bool get _hasMoreQuestions => _questionIndex < _questions.length;

  // ── reset toàn bộ state ──
  void _reset() {
    setState(() {
      _selectedConfig = null;
      _questionIndex = 0;
      _filters.clear();
      _results.clear();
      _isLoading = false;
      _showResults = false;
    });
  }

  // ── chọn loài → fetch lần đầu, chuyển sang Q1 ──
  Future<void> _selectAnimalType(AnimalTypeConfig config) async {
    setState(() {
      _selectedConfig = config;
      _questionIndex = 0;
      _filters.clear();
      _results.clear();
      _showResults = false;
      _isLoading = true;
    });
    await _fetchResults();
    setState(() => _isLoading = false);
  }

  // ── người dùng chọn 1 đáp án ──
  Future<void> _answer(QuestionConfig q, dynamic value) async {
    HapticFeedback.lightImpact();

    // Lưu filter
    setState(() {
      _filters[q.column] = value;
      _isLoading = true;
    });

    await _fetchResults();

    setState(() {
      _isLoading = false;
      // Hiện kết quả nếu còn ≤ 5 hoặc đã hết câu hỏi
      if (_results.length <= 5 || _questionIndex >= _questions.length - 1) {
        _showResults = true;
      } else {
        _questionIndex++;
      }
    });
  }

  // ── người dùng bỏ qua câu hỏi ──
  void _skip() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_results.length <= 5 || _questionIndex >= _questions.length - 1) {
        _showResults = true;
      } else {
        _questionIndex++;
      }
    });
  }

  // ── query Supabase theo bảng đúng ──
  Future<void> _fetchResults() async {
    if (_selectedConfig == null) return;
    final config = _selectedConfig!;

    try {
      var query = _client
          .from(config.dbTable)
          .select('id, name_vietnamese, name_english, scientific_name, image_url, description_short, animal_type');

      // Với bảng animals (thú hoang): thêm filter theo animal_type
      if (config.dbTable == 'animals') {
        query = query.eq('animal_type', config.animalType) as dynamic;
      }

      // Áp dụng các filter đã tích lũy
      for (final entry in _filters.entries) {
        final col = entry.key;
        final val = entry.value;
        final qConfig = _questions.firstWhere(
              (q) => q.column == col,
          orElse: () => _questions.first,
        );

        if (qConfig.isArray) {
          // Dùng contains để check array: giá trị nằm trong mảng PostgreSQL
          query = query.contains(col, [val]) as dynamic;
        } else if (qConfig.isBool || val is bool) {
          query = query.eq(col, val) as dynamic;
        } else if (qConfig.isRange && val is int) {
          // Range: lấy ±1 quanh giá trị chọn
          query = query
              .gte(col, val - 1)
              .lte(col, val + 1) as dynamic;
        } else {
          query = query.eq(col, val) as dynamic;
        }
      }

      final data = await (query as dynamic).limit(50);
      setState(() {
        _results = List<Map<String, dynamic>>.from(data as List);
      });
    } catch (e) {
      debugPrint('❌ _fetchResults error: $e');
      setState(() => _results = []);
    }
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedConfig == null) return _buildTypeSelection();
    if (_isLoading) return _buildLoading();
    if (_showResults) return _buildResults();
    if (!_hasMoreQuestions) return _buildResults(); // hết câu → hiện kết quả
    return _buildQuestion();
  }

  // ── BƯỚC 0: Chọn loài ──
  Widget _buildTypeSelection() {
    return Column(
      children: [
        const SizedBox(height: 40),

        // Tiêu đề
        const Text('🐾', style: TextStyle(fontSize: 52))
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.6, 0.6)),

        const SizedBox(height: 12),

        Text(
          'Tìm động vật',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF6B6B)],
              ).createShader(const Rect.fromLTWH(0, 0, 280, 60)),
          ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 6),

        Text(
          'Chọn loài bạn muốn khám phá',
          style: TextStyle(
              fontSize: 15, color: Colors.white.withOpacity(0.6)),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 32),

        // Grid loài
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.05,
            ),
            itemCount: allAnimalTypes.length,
            itemBuilder: (context, i) {
              final config = allAnimalTypes[i];
              return _buildTypeCard(config, i);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard(AnimalTypeConfig config, int index) {
    return GestureDetector(
      onTap: () => _selectAnimalType(config),
      child: _GlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(config.emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 10),
            Text(
              config.nameVi,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            Text(
              config.nameEn,
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withOpacity(0.55)),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (80 * index).ms, duration: 400.ms)
        .scale(begin: const Offset(0.85, 0.85), delay: (80 * index).ms);
  }

  // ── LOADING ──
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFFFD700)),
          const SizedBox(height: 20),
          Text('Đang tìm kiếm...',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 16)),
        ],
      ),
    );
  }

  // ── CÂU HỎI ──
  Widget _buildQuestion() {
    final q = _questions[_questionIndex];
    final total = _questions.length;
    final progress = (_questionIndex + 1) / (total + 1);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _GlassIconButton(
                icon: Icons.arrow_back_ios_new,
                onTap: () {
                  if (_questionIndex > 0) {
                    // Xoá filter của câu trước và quay lại
                    final prevQ = _questions[_questionIndex - 1];
                    setState(() {
                      _filters.remove(prevQ.column);
                      _questionIndex--;
                    });
                    _fetchResults();
                  } else {
                    _reset();
                  }
                },
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedConfig!.nameVi} ${_selectedConfig!.emoji}',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    Text(
                      '${_results.length} kết quả · Câu ${_questionIndex + 1}/$total',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.55)),
                    ),
                  ],
                ),
              ),
              // Nút xem kết quả sớm
              if (_results.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _showResults = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.4)),
                    ),
                    child: const Text('Xem ngay',
                        style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
        ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor:
              const AlwaysStoppedAnimation(Color(0xFFFFD700)),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Câu hỏi
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(q.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  q.question,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),

        const SizedBox(height: 32),

        // Options / Slider
        Expanded(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                if (q.isRange)
                  _buildRangeQuestion(q)
                else
                  ..._buildOptionsList(q),

                const SizedBox(height: 16),

                // Nút bỏ qua
                GestureDetector(
                  onTap: _skip,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      'Bỏ qua câu này  ⏭',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOptionsList(QuestionConfig q) {
    return q.options.asMap().entries.map((entry) {
      final i = entry.key;
      final opt = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: GestureDetector(
          onTap: () => _answer(q, opt.value),
          child: _GlassCard(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Text(opt.emoji,
                    style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    opt.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.4),
                    size: 18),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (80 * i).ms).slideX(begin: 0.25),
      );
    }).toList();
  }

  Widget _buildRangeQuestion(QuestionConfig q) {
    return _GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(q.minLabel ?? '1',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6))),
              Text(q.maxLabel ?? '5',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6))),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final val = i + 1;
              return GestureDetector(
                onTap: () => _answer(q, val),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Center(
                    child: Text(
                      '$val',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── KẾT QUẢ ──
  Widget _buildResults() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _GlassIconButton(
                  icon: Icons.home_outlined, onTap: _reset),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _results.isEmpty
                      ? 'Không tìm thấy kết quả 😢'
                      : '🎯  ${_results.length} kết quả phù hợp',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              // Nút làm lại từ đầu
              _GlassIconButton(
                icon: Icons.refresh,
                onTap: () => _selectAnimalType(_selectedConfig!),
              ),
            ],
          ),
        ),

        // Sub-text
        if (_results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Chọn một con để xem chi tiết',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
          ),

        const SizedBox(height: 12),

        // Danh sách
        Expanded(
          child: _results.isEmpty
              ? _buildNoResults()
              : GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            physics: const BouncingScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
            itemCount: _results.length,
            itemBuilder: (context, i) =>
                _buildResultCard(_results[i], i),
          ),
        ),
      ],
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😢', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy kết quả phù hợp',
            style: TextStyle(
                color: Colors.white.withOpacity(0.7), fontSize: 18),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _selectAnimalType(_selectedConfig!),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.5)),
              ),
              child: const Text(
                'Tìm lại từ đầu',
                style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> animal, int index) {
    return GestureDetector(
      onTap: () => _showDetail(animal),
      child: _GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
                child: animal['image_url'] != null
                    ? Image.network(
                  animal['image_url'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => _emojiPlaceholder(),
                )
                    : _emojiPlaceholder(),
              ),
            ),

            // Tên
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      animal['name_vietnamese'] ??
                          animal['name_english'] ??
                          '—',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (animal['scientific_name'] != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        animal['scientific_name'],
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withOpacity(0.55),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (50 * index).ms, duration: 350.ms)
        .scale(begin: const Offset(0.85, 0.85), delay: (50 * index).ms);
  }

  Widget _emojiPlaceholder() {
    return Container(
      color: Colors.white.withOpacity(0.06),
      child: Center(
        child: Text(
          _selectedConfig?.emoji ?? '🐾',
          style: const TextStyle(fontSize: 52),
        ),
      ),
    );
  }

  void _showDetail(Map<String, dynamic> animal) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
            animal['name_vietnamese'] ?? animal['name_english'] ?? ''),
        content: Column(
          children: [
            if (animal['scientific_name'] != null) ...[
              const SizedBox(height: 6),
              Text(
                animal['scientific_name'],
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            if (animal['description_short'] != null) ...[
              const SizedBox(height: 10),
              Text(animal['description_short']),
            ],
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Đóng'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.14),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withOpacity(0.2), width: 1.2),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withOpacity(0.2), width: 1.2),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}