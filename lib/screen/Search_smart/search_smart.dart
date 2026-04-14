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
  final String key;
  final String dbTable;
  final String animalType;
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

// ── CẤU HÌNH MÈO ──
const _catConfig = AnimalTypeConfig(
  key: 'cat',
  dbTable: 'cats',
  animalType: 'cat',
  emoji: '🐱',
  nameVi: 'Mèo',
  nameEn: 'Cat',
  questions: [
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

// ── CẤU HÌNH CHÓ ──
const _dogConfig = AnimalTypeConfig(
  key: 'dog',
  dbTable: 'dogs',
  animalType: 'dog',
  emoji: '🐶',
  nameVi: 'Chó',
  nameEn: 'Dog',
  questions: [
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
  final bool isArray;
  final bool isBool;
  final bool isRange;
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
  AnimalTypeConfig? _selectedConfig;
  int _questionIndex = 0;
  bool _isLoading = false;
  bool _showResults = false;

  // Bộ lọc tích lũy — chỉ thêm filter đã được xác nhận có kết quả
  final Map<String, dynamic> _filters = {};
  List<Map<String, dynamic>> _results = [];

  // Các index câu hỏi đã thực sự được hỏi (skip những câu chỉ có 1 option hợp lệ)
  final List<int> _askedQuestionIndices = [];

  final _client = Supabase.instance.client;

  List<QuestionConfig> get _questions => _selectedConfig?.questions ?? [];

  void _reset() {
    setState(() {
      _selectedConfig = null;
      _questionIndex = 0;
      _filters.clear();
      _results.clear();
      _askedQuestionIndices.clear();
      _isLoading = false;
      _showResults = false;
    });
  }

  Future<void> _selectAnimalType(AnimalTypeConfig config) async {
    setState(() {
      _selectedConfig = config;
      _questionIndex = 0;
      _filters.clear();
      _results.clear();
      _askedQuestionIndices.clear();
      _showResults = false;
      _isLoading = true;
    });
    await _fetchResults(_filters);
    setState(() => _isLoading = false);

    // Sau khi load xong, kiểm tra câu hỏi đầu tiên có hữu ích không
    await _advanceToNextUsefulQuestion();
  }

  // ── Thử apply filter với 1 option cụ thể, trả về số kết quả ──
  Future<int> _countResultsWithFilter(
      Map<String, dynamic> baseFilters, QuestionConfig q, dynamic value) async {
    if (_selectedConfig == null) return 0;
    final testFilters = Map<String, dynamic>.from(baseFilters);
    testFilters[q.column] = value;
    try {
      final data = await _buildQuery(testFilters).limit(50);
      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  // ── Kiểm tra options nào của câu hỏi hiện tại còn có kết quả ──
  Future<List<OptionConfig>> _getValidOptions(QuestionConfig q) async {
    final validOpts = <OptionConfig>[];
    for (final opt in q.options) {
      final count = await _countResultsWithFilter(_filters, q, opt.value);
      if (count > 0) {
        validOpts.add(opt);
      }
    }
    return validOpts;
  }

  // ── Tiến đến câu hỏi tiếp theo thực sự có ích ──
  // Bỏ qua câu nào mà tất cả options đều dẫn đến cùng tập kết quả (không phân biệt được)
  // hoặc chỉ có đúng 1 option có kết quả → tự động apply luôn, không hỏi
  Future<void> _advanceToNextUsefulQuestion() async {
    if (_selectedConfig == null) return;

    while (_questionIndex < _questions.length) {
      // Dừng lại nếu kết quả đã đủ nhỏ (≤ 3 loài → hiện kết quả)
      if (_results.length <= 3) {
        setState(() => _showResults = true);
        return;
      }

      final q = _questions[_questionIndex];

      // Lấy danh sách option còn có kết quả
      final validOpts = await _getValidOptions(q);

      if (validOpts.isEmpty) {
        // Không option nào có kết quả với filter hiện tại → skip câu này
        setState(() => _questionIndex++);
        continue;
      }

      if (validOpts.length == 1) {
        // Chỉ 1 option hợp lệ → tự động apply, không hỏi người dùng
        setState(() {
          _filters[q.column] = validOpts.first.value;
          _questionIndex++;
          _isLoading = true;
        });
        await _fetchResults(_filters);
        setState(() => _isLoading = false);
        continue;
      }

      // Câu hỏi này có ≥ 2 option hợp lệ → hiển thị để hỏi
      // Lưu lại valid options để UI dùng
      _currentValidOptions = validOpts;
      setState(() {}); // trigger rebuild
      return;
    }

    // Hết câu hỏi → hiện kết quả
    setState(() => _showResults = true);
  }

  // Cache valid options cho câu hỏi hiện tại
  List<OptionConfig> _currentValidOptions = [];

  // ── Người dùng chọn đáp án ──
  Future<void> _answer(QuestionConfig q, dynamic value) async {
    HapticFeedback.lightImpact();
    setState(() {
      _filters[q.column] = value;
      _questionIndex++;
      _currentValidOptions = [];
      _isLoading = true;
    });

    await _fetchResults(_filters);
    setState(() => _isLoading = false);

    // Tiếp tục tìm câu hỏi hữu ích tiếp theo
    await _advanceToNextUsefulQuestion();
  }

  // ── Bỏ qua câu hỏi (không thêm filter) ──
  Future<void> _skip() async {
    HapticFeedback.selectionClick();
    setState(() {
      _questionIndex++;
      _currentValidOptions = [];
    });
    await _advanceToNextUsefulQuestion();
  }

  // ── Xây dựng query Supabase với bộ filter ──
  dynamic _buildQuery(Map<String, dynamic> filters) {
    final config = _selectedConfig!;
    var query = _client
        .from(config.dbTable)
        .select('id, name_vietnamese, name_english, scientific_name, image_url, description_short, animal_type');

    if (config.dbTable == 'animals') {
      query = query.eq('animal_type', config.animalType) as dynamic;
    }

    for (final entry in filters.entries) {
      final col = entry.key;
      final val = entry.value;
      final qConfig = _questions.firstWhere(
            (q) => q.column == col,
        orElse: () => _questions.first,
      );

      if (qConfig.isArray) {
        query = query.contains(col, [val]) as dynamic;
      } else if (qConfig.isBool || val is bool) {
        query = query.eq(col, val) as dynamic;
      } else if (qConfig.isRange && val is int) {
        query = query.gte(col, val - 1).lte(col, val + 1) as dynamic;
      } else {
        query = query.eq(col, val) as dynamic;
      }
    }

    return query;
  }

  Future<void> _fetchResults(Map<String, dynamic> filters) async {
    if (_selectedConfig == null) return;
    try {
      final data = await _buildQuery(filters).limit(50);
      setState(() {
        _results = List<Map<String, dynamic>>.from(data as List);
      });
    } catch (e) {
      debugPrint('❌ _fetchResults error: $e');
      setState(() => _results = []);
    }
  }

  // ════════════════════════════════════════════════════════════
  // BUILD — Apple iOS White Style
  // ════════════════════════════════════════════════════════════

  // Màu sắc Apple-style
  static const _bg = Color(0xFFF2F2F7);           // iOS systemGroupedBackground
  static const _surface = Colors.white;
  static const _primary = Color(0xFF007AFF);       // iOS Blue
  static const _label = Color(0xFF000000);         // iOS label
  static const _secondaryLabel = Color(0xFF6C6C70);
  static const _separator = Color(0xFFD1D1D6);
  static const _fill = Color(0xFFE5E5EA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_selectedConfig == null) return _buildTypeSelection();
    if (_isLoading) return _buildLoading();
    if (_showResults) return _buildResults();
    if (_questionIndex >= _questions.length) return _buildResults();
    return _buildQuestion();
  }

  // ── BƯỚC 0: Chọn loài ──
  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header iOS-style large title
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tìm động vật',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: _label,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(duration: 350.ms),
              const SizedBox(height: 4),
              const Text(
                'Chọn loài bạn muốn khám phá',
                style: TextStyle(
                  fontSize: 16,
                  color: _secondaryLabel,
                  fontWeight: FontWeight.w400,
                ),
              ).animate().fadeIn(delay: 100.ms),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemCount: allAnimalTypes.length,
            itemBuilder: (context, i) => _buildTypeCard(allAnimalTypes[i], i),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard(AnimalTypeConfig config, int index) {
    return GestureDetector(
      onTap: () => _selectAnimalType(config),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(config.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              config.nameVi,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _label,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              config.nameEn,
              style: const TextStyle(
                fontSize: 13,
                color: _secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (60 * index).ms, duration: 350.ms)
        .scale(begin: const Offset(0.92, 0.92), delay: (60 * index).ms);
  }

  // ── LOADING ──
  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoActivityIndicator(radius: 16),
          SizedBox(height: 16),
          Text(
            'Đang tìm kiếm...',
            style: TextStyle(color: _secondaryLabel, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ── CÂU HỎI ──
  Widget _buildQuestion() {
    if (_questionIndex >= _questions.length) {
      return _buildResults();
    }
    final q = _questions[_questionIndex];
    final displayOptions = _currentValidOptions.isNotEmpty
        ? _currentValidOptions
        : q.options;

    // Đếm số câu đã hỏi thực tế (có filter)
    final answeredCount = _filters.length;
    final totalQ = _questions.length;
    final progress = (answeredCount) / totalQ.toDouble();

    return Column(
      children: [
        // iOS Navigation Bar style
        _buildNavBar(
          leading: GestureDetector(
            onTap: () {
              if (_filters.isNotEmpty) {
                // Xoá filter cuối và quay lại
                final lastKey = _filters.keys.last;
                setState(() {
                  _filters.remove(lastKey);
                  _currentValidOptions = [];
                  // Tìm lại index câu hỏi tương ứng
                  final prevIdx = _questions.indexWhere((q) => q.column == lastKey);
                  if (prevIdx >= 0) _questionIndex = prevIdx;
                });
                _fetchResults(_filters).then((_) => _advanceToNextUsefulQuestion());
              } else {
                _reset();
              }
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.back, color: _primary, size: 22),
                Text('Quay lại',
                    style: TextStyle(color: _primary, fontSize: 17)),
              ],
            ),
          ),
          title: Text(
            '${_selectedConfig!.nameVi} ${_selectedConfig!.emoji}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: _label,
            ),
          ),
          trailing: _results.isNotEmpty
              ? GestureDetector(
            onTap: () => setState(() => _showResults = true),
            child: Text(
              'Xem ${_results.length}',
              style: const TextStyle(color: _primary, fontSize: 17),
            ),
          )
              : const SizedBox.shrink(),
        ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: _fill,
                  valueColor: const AlwaysStoppedAnimation(_primary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_results.length} kết quả đang khớp',
                style: const TextStyle(
                    fontSize: 13, color: _secondaryLabel),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Câu hỏi
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Text(q.emoji, style: const TextStyle(fontSize: 44))
                  .animate()
                  .scale(begin: const Offset(0.7, 0.7), duration: 300.ms),
              const SizedBox(height: 12),
              Text(
                q.question,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _label,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.15),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Options
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // iOS grouped list style
                Container(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: displayOptions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final opt = entry.value;
                      final isLast = i == displayOptions.length - 1;
                      return _buildOptionRow(q, opt, isLast, i);
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // Bỏ qua — iOS tertiary style
                GestureDetector(
                  onTap: _skip,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Không chắc, bỏ qua',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _secondaryLabel,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
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

  Widget _buildOptionRow(QuestionConfig q, OptionConfig opt, bool isLast, int index) {
    return GestureDetector(
      onTap: () => _answer(q, opt.value),
      child: Column(
        children: [
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(opt.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    opt.label,
                    style: const TextStyle(
                      fontSize: 17,
                      color: _label,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const Icon(CupertinoIcons.chevron_forward,
                    color: _separator, size: 16),
              ],
            ),
          ),
          if (!isLast)
            const Divider(
              height: 1,
              indent: 58,
              color: _separator,
            ),
        ],
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
  }

  // ── KẾT QUẢ ──
  Widget _buildResults() {
    return Column(
      children: [
        _buildNavBar(
          leading: GestureDetector(
            onTap: _reset,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.house, color: _primary, size: 20),
                SizedBox(width: 4),
                Text('Trang chủ',
                    style: TextStyle(color: _primary, fontSize: 17)),
              ],
            ),
          ),
          title: Text(
            _results.isEmpty
                ? 'Không tìm thấy'
                : '${_results.length} kết quả',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: _label,
            ),
          ),
          trailing: _results.isNotEmpty
              ? GestureDetector(
            onTap: () => _selectAnimalType(_selectedConfig!),
            child: const Text(
              'Tìm lại',
              style: TextStyle(color: _primary, fontSize: 17),
            ),
          )
              : const SizedBox.shrink(),
        ),

        if (_results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Text(
                  'Chọn một con để xem chi tiết',
                  style: const TextStyle(
                      color: _secondaryLabel, fontSize: 13),
                ),
              ],
            ),
          ),

        Expanded(
          child: _results.isEmpty
              ? _buildNoResults()
              : GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            physics: const BouncingScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
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
          const Text('🔍', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _label,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thử tìm lại với ít tiêu chí hơn',
            style: TextStyle(color: _secondaryLabel, fontSize: 16),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => _selectAnimalType(_selectedConfig!),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Tìm lại từ đầu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
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
                        fontWeight: FontWeight.w600,
                        color: _label,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (animal['scientific_name'] != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        animal['scientific_name'],
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: _secondaryLabel,
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
        .scale(begin: const Offset(0.88, 0.88), delay: (50 * index).ms);
  }

  Widget _emojiPlaceholder() {
    return Container(
      color: _fill,
      child: Center(
        child: Text(
          _selectedConfig?.emoji ?? '🐾',
          style: const TextStyle(fontSize: 48),
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

  // ── iOS Navigation Bar helper ──
  Widget _buildNavBar({
    required Widget leading,
    required Widget title,
    required Widget trailing,
  }) {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          leading,
          Expanded(child: Center(child: title)),
          trailing,
        ],
      ),
    );
  }
}