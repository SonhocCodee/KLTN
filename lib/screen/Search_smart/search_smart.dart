import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AniQuestSmartApp());
}

// ═══════════════════════════════════════════════════════════════
// APP
// ═══════════════════════════════════════════════════════════════

class AniQuestSmartApp extends StatelessWidget {
  const AniQuestSmartApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AniQuest Smart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        fontFamily: '.SF Pro Display',
      ),
      home: const SplashScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SPLASH SCREEN - Initialize Supabase
// ═══════════════════════════════════════════════════════════════

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Supabase.initialize(
        url: 'https://dnvlqnixommhjqwpflmw.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudmxxbml4b21taGpxd3BmbG13Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDMzMTUwMSwiZXhwIjoyMDg1OTA3NTAxfQ.W2cxnWC-DJoE9GRdUWMZU3-e27VFVA05BTJotZHfR54',
      );

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SmartQuizPage()),
        );
      }
    } catch (e) {
      print('Init error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🐾',
                style: TextStyle(fontSize: 100),
              ),
              const SizedBox(height: 20),
              Text(
                'AniQuest Smart',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF6B6B)],
                    ).createShader(const Rect.fromLTWH(0, 0, 300, 70)),
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: Color(0xFFFFD700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ANIMAL TYPE CONFIG
// ═══════════════════════════════════════════════════════════════

class AnimalTypeConfig {
  final String type;
  final String emoji;
  final String nameVi;
  final String nameEn;
  final String traitsTable;
  final List<QuestionConfig> questions;

  AnimalTypeConfig({
    required this.type,
    required this.emoji,
    required this.nameVi,
    required this.nameEn,
    required this.traitsTable,
    required this.questions,
  });

  static final Map<String, AnimalTypeConfig> configs = {
    'cat': AnimalTypeConfig(
      type: 'cat',
      emoji: '🐱',
      nameVi: 'Mèo',
      nameEn: 'Cat',
      traitsTable: 'cat_traits',
      questions: [
        QuestionConfig(
          id: 'primary_colors',
          question: 'Màu lông chủ đạo?',
          emoji: '🎨',
          column: 'primary_colors',
          type: QuestionType.animal,
          isArray: true,
          options: [
            OptionConfig(label: 'Trắng', emoji: '⚪', value: 'white'),
            OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
            OptionConfig(label: 'Cam', emoji: '🟠', value: 'orange'),
            OptionConfig(label: 'Xám', emoji: '🔵', value: 'gray'),
            OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
          ],
        ),
        QuestionConfig(
          id: 'coat_length',
          question: 'Độ dài lông?',
          emoji: '✂️',
          column: 'coat_length',
          type: QuestionType.traits,
          options: [
            OptionConfig(label: 'Không lông', emoji: '🫥', value: 'hairless'),
            OptionConfig(label: 'Ngắn', emoji: '📏', value: 'short'),
            OptionConfig(label: 'Trung bình', emoji: '📐', value: 'medium'),
            OptionConfig(label: 'Dài', emoji: '🦁', value: 'long'),
            OptionConfig(label: 'Rất dài', emoji: '🧶', value: 'extra_long'),
          ],
        ),
        QuestionConfig(
          id: 'patterns',
          question: 'Có hoa văn không?',
          emoji: '🎭',
          column: 'patterns',
          type: QuestionType.animal,
          isArray: true,
          options: [
            OptionConfig(label: 'Trơn', emoji: '⬜', value: 'solid'),
            OptionConfig(label: 'Có vằn', emoji: '🦓', value: 'tabby'),
            OptionConfig(label: 'Hai màu', emoji: '🔲', value: 'bicolor'),
            OptionConfig(label: 'Đốm', emoji: '🔵', value: 'spotted'),
          ],
        ),
        QuestionConfig(
          id: 'relative_size',
          question: 'Kích thước?',
          emoji: '📏',
          column: 'relative_size',
          type: QuestionType.animal,
          options: [
            OptionConfig(label: 'Nhỏ', emoji: '🐭', value: 'tiny'),
            OptionConfig(label: 'Bằng mèo', emoji: '🐱', value: 'cat_sized'),
            OptionConfig(label: 'Lớn', emoji: '🦁', value: 'dog_sized'),
          ],
        ),
      ],
    ),
    'dog': AnimalTypeConfig(
      type: 'dog',
      emoji: '🐶',
      nameVi: 'Chó',
      nameEn: 'Dog',
      traitsTable: 'dog_traits',
      questions: [
        QuestionConfig(
          id: 'primary_colors',
          question: 'Màu lông chủ đạo?',
          emoji: '🎨',
          column: 'primary_colors',
          type: QuestionType.animal,
          isArray: true,
          options: [
            OptionConfig(label: 'Trắng', emoji: '⚪', value: 'white'),
            OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
            OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
            OptionConfig(label: 'Vàng', emoji: '🟡', value: 'golden'),
            OptionConfig(label: 'Xám', emoji: '🔵', value: 'gray'),
          ],
        ),
        QuestionConfig(
          id: 'ear_type',
          question: 'Loại tai?',
          emoji: '👂',
          column: 'has_floppy_ears',
          type: QuestionType.traits,
          options: [
            OptionConfig(label: 'Tai cụp', emoji: '🐶', value: true, boolColumn: 'has_floppy_ears'),
            OptionConfig(label: 'Tai dựng', emoji: '🐕', value: true, boolColumn: 'has_pointy_ears'),
          ],
        ),
        QuestionConfig(
          id: 'coat_length',
          question: 'Độ dài lông?',
          emoji: '✂️',
          column: 'coat_length',
          type: QuestionType.traits,
          options: [
            OptionConfig(label: 'Ngắn', emoji: '📏', value: 'short'),
            OptionConfig(label: 'Trung bình', emoji: '📐', value: 'medium'),
            OptionConfig(label: 'Dài', emoji: '🦁', value: 'long'),
          ],
        ),
        QuestionConfig(
          id: 'relative_size',
          question: 'Kích thước?',
          emoji: '📏',
          column: 'relative_size',
          type: QuestionType.animal,
          options: [
            OptionConfig(label: 'Nhỏ', emoji: '🐭', value: 'tiny'),
            OptionConfig(label: 'Trung bình', emoji: '🐕', value: 'dog_sized'),
            OptionConfig(label: 'Lớn', emoji: '🦮', value: 'large'),
          ],
        ),
      ],
    ),
    'buffalo': AnimalTypeConfig(
      type: 'buffalo',
      emoji: '🐃',
      nameVi: 'Trâu',
      nameEn: 'Buffalo',
      traitsTable: 'buffalo_traits',
      questions: [
        QuestionConfig(
          id: 'primary_colors',
          question: 'Màu da chủ đạo?',
          emoji: '🎨',
          column: 'primary_colors',
          type: QuestionType.animal,
          isArray: true,
          options: [
            OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
            OptionConfig(label: 'Xám', emoji: '🔵', value: 'gray'),
            OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
          ],
        ),
        QuestionConfig(
          id: 'has_horns',
          question: 'Có sừng không?',
          emoji: '🦬',
          column: 'has_horns',
          type: QuestionType.animal,
          options: [
            OptionConfig(label: 'Có sừng lớn', emoji: '🦬', value: true),
            OptionConfig(label: 'Không sừng', emoji: '❌', value: false),
          ],
        ),
        QuestionConfig(
          id: 'relative_size',
          question: 'Kích thước?',
          emoji: '📏',
          column: 'relative_size',
          type: QuestionType.animal,
          options: [
            OptionConfig(label: 'Trung bình', emoji: '🐃', value: 'large'),
            OptionConfig(label: 'Rất lớn', emoji: '🦬', value: 'elephant_sized'),
          ],
        ),
      ],
    ),
    'cattle': AnimalTypeConfig(
      type: 'cattle',
      emoji: '🐄',
      nameVi: 'Bò',
      nameEn: 'Cattle',
      traitsTable: 'cattle_traits',
      questions: [
        QuestionConfig(
          id: 'primary_colors',
          question: 'Màu da chủ đạo?',
          emoji: '🎨',
          column: 'primary_colors',
          type: QuestionType.animal,
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
          type: QuestionType.animal,
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
          type: QuestionType.animal,
          isArray: true,
          options: [
            OptionConfig(label: 'Trơn', emoji: '⬜', value: 'solid'),
            OptionConfig(label: 'Có đốm', emoji: '🔵', value: 'spotted'),
          ],
        ),
      ],
    ),
    'horse': AnimalTypeConfig(
      type: 'horse',
      emoji: '🐴',
      nameVi: 'Ngựa',
      nameEn: 'Horse',
      traitsTable: 'horse_traits',
      questions: [
        QuestionConfig(
          id: 'primary_colors',
          question: 'Màu lông chủ đạo?',
          emoji: '🎨',
          column: 'primary_colors',
          type: QuestionType.animal,
          isArray: true,
          options: [
            OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
            OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
            OptionConfig(label: 'Trắng', emoji: '⚪', value: 'white'),
            OptionConfig(label: 'Xám', emoji: '🔵', value: 'gray'),
          ],
        ),
        QuestionConfig(
          id: 'has_mane',
          question: 'Có bờm dài?',
          emoji: '🦄',
          column: 'has_mane',
          type: QuestionType.animal,
          options: [
            OptionConfig(label: 'Có', emoji: '✅', value: true),
            OptionConfig(label: 'Không', emoji: '❌', value: false),
          ],
        ),
        QuestionConfig(
          id: 'patterns',
          question: 'Có đốm/hoa văn không?',
          emoji: '🎭',
          column: 'patterns',
          type: QuestionType.animal,
          isArray: true,
          options: [
            OptionConfig(label: 'Trơn', emoji: '⬜', value: 'solid'),
            OptionConfig(label: 'Có đốm', emoji: '🔵', value: 'spotted'),
            OptionConfig(label: 'Vằn', emoji: '🦓', value: 'pinto'),
          ],
        ),
      ],
    ),
    'bear': AnimalTypeConfig(
      type: 'bear',
      emoji: '🐻',
      nameVi: 'Gấu',
      nameEn: 'Bear',
      traitsTable: 'bear_traits',
      questions: [
        QuestionConfig(
          id: 'primary_colors',
          question: 'Màu lông chủ đạo?',
          emoji: '🎨',
          column: 'primary_colors',
          type: QuestionType.animal,
          isArray: true,
          options: [
            OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
            OptionConfig(label: 'Đen', emoji: '⚫', value: 'black'),
            OptionConfig(label: 'Trắng', emoji: '⚪', value: 'white'),
            OptionConfig(label: 'Vàng', emoji: '🟡', value: 'yellow'),
          ],
        ),
        QuestionConfig(
          id: 'relative_size',
          question: 'Kích thước?',
          emoji: '📏',
          column: 'relative_size',
          type: QuestionType.animal,
          options: [
            OptionConfig(label: 'Trung bình', emoji: '🐻', value: 'large'),
            OptionConfig(label: 'Rất lớn', emoji: '🦬', value: 'elephant_sized'),
          ],
        ),
      ],
    ),
    'lion': AnimalTypeConfig(
      type: 'lion',
      emoji: '🦁',
      nameVi: 'Sư tử',
      nameEn: 'Lion',
      traitsTable: 'lion_traits',
      questions: [
        QuestionConfig(
          id: 'has_mane',
          question: 'Có bờm không?',
          emoji: '🦁',
          column: 'has_mane',
          type: QuestionType.traits,
          options: [
            OptionConfig(label: 'Có bờm (đực)', emoji: '🦁', value: true),
            OptionConfig(label: 'Không bờm (cái)', emoji: '🐆', value: false),
          ],
        ),
        QuestionConfig(
          id: 'primary_colors',
          question: 'Màu lông chủ đạo?',
          emoji: '🎨',
          column: 'primary_colors',
          type: QuestionType.animal,
          isArray: true,
          options: [
            OptionConfig(label: 'Vàng', emoji: '🟡', value: 'tan'),
            OptionConfig(label: 'Nâu', emoji: '🟤', value: 'brown'),
            OptionConfig(label: 'Trắng', emoji: '⚪', value: 'white'),
          ],
        ),
      ],
    ),
  };
}

class QuestionConfig {
  final String id;
  final String question;
  final String emoji;
  final String column;
  final QuestionType type;
  final List<OptionConfig> options;
  final bool isRange;
  final bool isArray; // NEW: for array columns like primary_colors
  final String? minLabel;
  final String? maxLabel;

  QuestionConfig({
    required this.id,
    required this.question,
    required this.emoji,
    required this.column,
    required this.type,
    this.options = const [],
    this.isRange = false,
    this.isArray = false, // NEW
    this.minLabel,
    this.maxLabel,
  });
}

enum QuestionType { animal, traits }

class OptionConfig {
  final String label;
  final String emoji;
  final dynamic value;
  final String? boolColumn;

  OptionConfig({
    required this.label,
    required this.emoji,
    required this.value,
    this.boolColumn,
  });
}

// ═══════════════════════════════════════════════════════════════
// SMART QUIZ PAGE
// ═══════════════════════════════════════════════════════════════

class SmartQuizPage extends StatefulWidget {
  const SmartQuizPage({Key? key}) : super(key: key);

  @override
  State<SmartQuizPage> createState() => _SmartQuizPageState();
}

class _SmartQuizPageState extends State<SmartQuizPage> {
  String? selectedAnimalType;
  int currentQuestionIndex = 0;
  Map<String, dynamic> animalFilters = {};
  Map<String, dynamic> traitsFilters = {};
  List<Map<String, dynamic>> currentResults = [];
  bool isLoading = false;
  bool showResults = false;

  AnimalTypeConfig? get currentConfig =>
      selectedAnimalType != null ? AnimalTypeConfig.configs[selectedAnimalType] : null;

  List<QuestionConfig> get questions => currentConfig?.questions ?? [];

  @override
  Widget build(BuildContext context) {
    if (selectedAnimalType == null) {
      return _buildAnimalTypeSelection();
    }

    if (showResults) {
      return _buildResults();
    }

    if (currentQuestionIndex >= questions.length) {
      return _buildNoMoreQuestions();
    }

    return _buildQuestionPage();
  }

  // ═══════════════════════════════════════════════════════════════
  // ANIMAL TYPE SELECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAnimalTypeSelection() {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Title
                Text(
                  'AniQuest Smart',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFF6B6B)],
                      ).createShader(const Rect.fromLTWH(0, 0, 300, 70)),
                  ),
                ).animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.3, end: 0),

                const SizedBox(height: 10),

                Text(
                  'Chọn loài động vật',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ).animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms),

                const SizedBox(height: 40),

                // Animal Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: AnimalTypeConfig.configs.length,
                    itemBuilder: (context, index) {
                      final entry = AnimalTypeConfig.configs.entries.elementAt(index);
                      final config = entry.value;

                      return _buildAnimalTypeCard(config, index)
                          .animate()
                          .fadeIn(delay: (100 * index).ms, duration: 500.ms)
                          .scale(begin: const Offset(0.8, 0.8), delay: (100 * index).ms);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalTypeCard(AnimalTypeConfig config, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAnimalType = config.type;
          animalFilters['animal_type'] = config.type;
        });
        _fetchResults();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  config.emoji,
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 12),
                Text(
                  config.nameVi,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  config.nameEn,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // QUESTION PAGE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildQuestionPage() {
    final question = questions[currentQuestionIndex];

    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () {
                          if (currentQuestionIndex > 0) {
                            setState(() => currentQuestionIndex--);
                          } else {
                            setState(() => selectedAnimalType = null);
                          }
                        },
                        child: _buildGlassButton(
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Progress
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${currentConfig?.nameVi} ${currentConfig?.emoji}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${currentResults.length} kết quả',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (currentQuestionIndex + 1) / (questions.length + 1),
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Question
                Expanded(
                  child: isLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFD700),
                    ),
                  )
                      : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Question Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              question.emoji,
                              style: const TextStyle(fontSize: 48),
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: Text(
                                question.question,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ).animate()
                            .fadeIn(duration: 600.ms)
                            .scale(begin: const Offset(0.9, 0.9)),

                        const SizedBox(height: 40),

                        // Options
                        if (question.isRange)
                          _buildRangeSlider(question)
                        else
                          _buildOptions(question),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(QuestionConfig question) {
    return Column(
      children: question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () => _selectOption(question, option),
            child: _buildOptionCard(option),
          ),
        ).animate()
            .fadeIn(delay: (100 * index).ms, duration: 500.ms)
            .slideX(begin: 0.3, delay: (100 * index).ms);
      }).toList(),
    );
  }

  Widget _buildOptionCard(OptionConfig option) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Text(
                option.emoji,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  option.label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeSlider(QuestionConfig question) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        question.minLabel ?? 'Min',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        question.maxLabel ?? 'Max',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _selectRangeValue(question, value),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$value',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // RESULTS PAGE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildResults() {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedAnimalType = null;
                            currentQuestionIndex = 0;
                            animalFilters.clear();
                            traitsFilters.clear();
                            currentResults.clear();
                            showResults = false;
                          });
                        },
                        child: _buildGlassButton(
                          child: const Icon(Icons.home, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          '🎯 Tìm thấy ${currentResults.length} kết quả',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Results Grid
                Expanded(
                  child: currentResults.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('😢', style: TextStyle(fontSize: 80)),
                        const SizedBox(height: 20),
                        Text(
                          'Không tìm thấy kết quả',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                      : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: currentResults.length,
                    itemBuilder: (context, index) {
                      return _buildResultCard(currentResults[index], index);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> animal, int index) {
    return GestureDetector(
      onTap: () => _showAnimalDetail(animal),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                    child: animal['image_url'] != null
                        ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: Image.network(
                        animal['image_url'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            currentConfig?.emoji ?? '🐾',
                            style: const TextStyle(fontSize: 60),
                          ),
                        ),
                      ),
                    )
                        : Center(
                      child: Text(
                        currentConfig?.emoji ?? '🐾',
                        style: const TextStyle(fontSize: 60),
                      ),
                    ),
                  ),
                ),

                // Info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          animal['name_vietnamese'] ?? animal['name_english'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (animal['scientific_name'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            animal['scientific_name'],
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withOpacity(0.6),
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
        ),
      ),
    ).animate()
        .fadeIn(delay: (50 * index).ms, duration: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), delay: (50 * index).ms);
  }

  Widget _buildNoMoreQuestions() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: Center(
          child: Text(
            'Hết câu hỏi!',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LOGIC
  // ═══════════════════════════════════════════════════════════════

  Future<void> _fetchResults() async {
    setState(() => isLoading = true);

    try {
      const supabaseUrl = 'https://dnvlqnixommhjqwpflmw.supabase.co';
      String url = '$supabaseUrl/rest/v1/animals?select=*';

      // Separate array filters and normal filters
      Map<String, dynamic> arrayFilters = {};
      Map<String, dynamic> normalFilters = {};

      for (var entry in animalFilters.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value == null) continue;

        final question = questions.firstWhere(
              (q) => q.column == key && q.type == QuestionType.animal,
          orElse: () => questions.first,
        );

        if (question.isArray) {
          arrayFilters[key] = value;
          print('🔵 Array filter: $key = $value'); // Debug
        } else {
          normalFilters[key] = value;
          print('🟢 Normal filter: $key = $value'); // Debug
        }
      }

      // Add normal filters to URL
      for (var entry in normalFilters.entries) {
        url += '&${entry.key}=eq.${entry.value}';
      }

      print('🌐 Query URL: $url');

      const apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudmxxbml4b21taGpxd3BmbG13Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDMzMTUwMSwiZXhwIjoyMDg1OTA3NTAxfQ.W2cxnWC-DJoE9GRdUWMZU3-e27VFVA05BTJotZHfR54';

      final animalResponse = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (animalResponse.statusCode != 200) {
        print('❌ Animal query error: ${animalResponse.body}');
        setState(() {
          currentResults = [];
          isLoading = false;
        });
        return;
      }

      var animalResults = json.decode(animalResponse.body) as List;

      print('📊 Fetched ${animalResults.length} animals from DB');

      // Debug: Check first animal structure
      if (animalResults.isNotEmpty) {
        final first = animalResults[0];
        print('🔍 First animal primary_colors type: ${first['primary_colors'].runtimeType}');
        print('🔍 First animal primary_colors value: ${first['primary_colors']}');
      }

      // Client-side filtering for array columns
      if (arrayFilters.isNotEmpty) {
        print('🔄 Applying client-side array filters...');
        animalResults = animalResults.where((animal) {
          for (var entry in arrayFilters.entries) {
            final key = entry.key;
            final value = entry.value;

            final arrayValue = animal[key];

            print('  🔍 Checking $key: $arrayValue (type: ${arrayValue.runtimeType})');

            // Check if array contains value
            if (arrayValue is List) {
              if (!arrayValue.contains(value)) {
                print('    ❌ List does not contain $value');
                return false;
              }
              print('    ✅ List contains $value');
            } else if (arrayValue is String) {
              // If it's text instead of array, check if contains
              if (!arrayValue.toLowerCase().contains(value.toString().toLowerCase())) {
                print('    ❌ String does not contain $value');
                return false;
              }
              print('    ✅ String contains $value');
            } else {
              print('    ⚠️ Unknown type, skipping');
              return false;
            }
          }
          return true;
        }).toList();

        print('✅ After filtering: ${animalResults.length} animals');
      }

      if (animalResults.isEmpty) {
        setState(() {
          currentResults = [];
          isLoading = false;
        });
        return;
      }

      // If no traits filters, return animals
      if (traitsFilters.isEmpty) {
        setState(() {
          currentResults = List<Map<String, dynamic>>.from(animalResults);
          isLoading = false;
        });
        return;
      }

      // Query traits table
      final animalIds = animalResults.map((a) => a['id'] as String).toList();

      print('🔍 Querying traits for ${animalIds.length} animals...');

      var traitsQuery = Supabase.instance.client
          .from(currentConfig!.traitsTable)
          .select('*')
          .inFilter('animal_id', animalIds);

      for (var entry in traitsFilters.entries) {
        traitsQuery = traitsQuery.eq(entry.key, entry.value);
      }

      final traitsResults = await traitsQuery;
      final matchedIds = traitsResults.map((t) => t['animal_id']).toSet();

      final filteredAnimals = animalResults
          .where((a) => matchedIds.contains(a['id']))
          .toList();

      print('✅ Final results: ${filteredAnimals.length} animals');

      setState(() {
        currentResults = List<Map<String, dynamic>>.from(filteredAnimals);
        isLoading = false;
      });

      // Auto show results if <= 10
      if (currentResults.length <= 10 && currentResults.isNotEmpty) {
        setState(() => showResults = true);
      }

    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        currentResults = [];
        isLoading = false;
      });
    }
  }

  void _selectOption(QuestionConfig question, OptionConfig option) {
    if (question.type == QuestionType.traits) {
      traitsFilters[option.boolColumn ?? question.column] = option.value;
    } else {
      animalFilters[question.column] = option.value;
    }

    _nextQuestion();
  }

  void _selectRangeValue(QuestionConfig question, int value) {
    if (question.type == QuestionType.traits) {
      traitsFilters[question.column] = value;
    } else {
      animalFilters[question.column] = value;
    }

    _nextQuestion();
  }

  Future<void> _nextQuestion() async {
    await _fetchResults();

    if (currentResults.length <= 10 && currentResults.isNotEmpty) {
      setState(() => showResults = true);
    } else if (currentQuestionIndex < questions.length - 1) {
      setState(() => currentQuestionIndex++);
    } else {
      setState(() => showResults = true);
    }
  }

  void _showAnimalDetail(Map<String, dynamic> animal) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(animal['name_vietnamese'] ?? animal['name_english'] ?? ''),
        content: Column(
          children: [
            if (animal['scientific_name'] != null)
              Text(
                animal['scientific_name'],
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 10),
            if (animal['description_short'] != null)
              Text(animal['description_short']),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Đóng'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}