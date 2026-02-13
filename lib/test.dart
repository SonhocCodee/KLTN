import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ═══════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dnvlqnixommhjqwpflmw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudmxxbml4b21taGpxd3BmbG13Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzMzE1MDEsImV4cCI6MjA4NTkwNzUwMX0.sz5oI5lhecJ0DCJNByI3CIHFICHh2PBt5FHnrMfmDaE',
  );

  runApp(const AniQuestApp());
}

// ═══════════════════════════════════════════════════════
// APP
// ═══════════════════════════════════════════════════════

class AniQuestApp extends StatelessWidget {
  const AniQuestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AniQuest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0F0E17),
        fontFamily: 'Nunito',
        primaryColor: const Color(0xFFFF8906),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8906),
          brightness: Brightness.dark,
        ),
      ),
      home: const QuizPage(),
    );
  }
}

// ═══════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════

class QuizStep {
  final String id;
  final String question;
  final String emoji;
  final QuizType type;
  final String? column;
  final bool isArrayMatch;
  final bool isBooleanColumns;
  final bool hasSearch;
  final String? searchPlaceholder;
  final List<QuizOption> options;

  QuizStep({
    required this.id,
    required this.question,
    required this.emoji,
    required this.type,
    this.column,
    this.isArrayMatch = false,
    this.isBooleanColumns = false,
    this.hasSearch = false,
    this.searchPlaceholder,
    required this.options,
  });
}

enum QuizType { single, multi }

class QuizOption {
  final String emoji;
  final String label;
  final dynamic value;
  final Map<String, dynamic>? filter;
  final String? column;

  QuizOption({
    required this.emoji,
    required this.label,
    this.value,
    this.filter,
    this.column,
  });
}

class Animal {
  final String id;
  final String nameVietnamese;
  final String nameEnglish;
  final String? scientificName;
  final String? imageUrl;
  final String? descriptionShort;
  final Map<String, dynamic> rawData;

  Animal({
    required this.id,
    required this.nameVietnamese,
    required this.nameEnglish,
    this.scientificName,
    this.imageUrl,
    this.descriptionShort,
    required this.rawData,
  });

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'],
      nameVietnamese: json['name_vietnamese'] ?? json['name_english'],
      nameEnglish: json['name_english'],
      scientificName: json['scientific_name'],
      imageUrl: json['image_url'],
      descriptionShort: json['description_short'],
      rawData: json,
    );
  }
}

// ═══════════════════════════════════════════════════════
// QUIZ DATA
// ═══════════════════════════════════════════════════════

final List<QuizStep> quizFlow = [
  QuizStep(
    id: 'animal_type',
    question: 'Bạn đang tìm loài gì?',
    emoji: '🐾',
    type: QuizType.single,
    hasSearch: true,
    searchPlaceholder: 'Gõ để tìm (VD: mèo, chó...)',
    options: [
      QuizOption(
        emoji: '🐱',
        label: 'Mèo',
        filter: {'family': 'Felidae', 'primary_habitat': 'domestic'},
      ),
      QuizOption(
        emoji: '🐶',
        label: 'Chó',
        filter: {'family': 'Canidae', 'primary_habitat': 'domestic'},
      ),
      QuizOption(
        emoji: '🐔',
        label: 'Gà',
        filter: {'order_name': 'Galliformes'},
      ),
      QuizOption(
        emoji: '🦆',
        label: 'Vịt',
        filter: {'family': 'Anatidae'},
      ),
      QuizOption(
        emoji: '🐭',
        label: 'Chuột',
        filter: {'order_name': 'Rodentia'},
      ),
      QuizOption(
        emoji: '🐦',
        label: 'Chim',
        filter: {'class': 'Aves'},
      ),
      QuizOption(
        emoji: '🐟',
        label: 'Cá',
        filter: {'class': 'Actinopterygii'},
      ),
      QuizOption(
        emoji: '🐯',
        label: 'Thú hoang',
        filter: {'class': 'Mammalia'},
      ),
    ],
  ),
  QuizStep(
    id: 'size',
    question: 'Kích thước như thế nào?',
    emoji: '📏',
    type: QuizType.single,
    column: 'relative_size',
    options: [
      QuizOption(emoji: '🐭', label: 'Rất nhỏ', value: 'tiny'),
      QuizOption(emoji: '🐱', label: 'Bằng mèo', value: 'cat_sized'),
      QuizOption(emoji: '🐕', label: 'Bằng chó', value: 'dog_sized'),
      QuizOption(emoji: '🧍', label: 'Bằng người', value: 'human_sized'),
      QuizOption(emoji: '🐘', label: 'Rất lớn', value: 'elephant_sized'),
    ],
  ),
  QuizStep(
    id: 'colors',
    question: 'Màu sắc chủ đạo?',
    emoji: '🎨',
    type: QuizType.multi,
    column: 'primary_colors',
    isArrayMatch: true,
    options: [
      QuizOption(emoji: '🟤', label: 'Nâu', value: 'brown'),
      QuizOption(emoji: '⚪', label: 'Trắng', value: 'white'),
      QuizOption(emoji: '⚫', label: 'Đen', value: 'black'),
      QuizOption(emoji: '🟠', label: 'Cam/Vàng', value: ['orange', 'yellow']),
      QuizOption(emoji: '🔵', label: 'Xám/Xanh', value: ['gray', 'blue']),
      QuizOption(emoji: '🌈', label: 'Nhiều màu', value: 'multicolor'),
    ],
  ),
  QuizStep(
    id: 'features',
    question: 'Đặc điểm nổi bật?',
    emoji: '✨',
    type: QuizType.multi,
    isBooleanColumns: true,
    options: [
      QuizOption(emoji: '🔵', label: 'Có đốm', column: 'has_spots', value: true),
      QuizOption(emoji: '🦓', label: 'Có vằn', column: 'has_stripes', value: true),
      QuizOption(emoji: '🧶', label: 'Lông xù', column: 'is_fluffy', value: true),
      QuizOption(emoji: '👂', label: 'Tai cụp', column: 'has_floppy_ears', value: true),
      QuizOption(emoji: '👂', label: 'Tai nhọn', column: 'has_pointy_ears', value: true),
      QuizOption(emoji: '🦁', label: 'Có bờm', column: 'has_mane', value: true),
    ],
  ),
  QuizStep(
    id: 'sound',
    question: 'Tiếng kêu như thế nào?',
    emoji: '🔊',
    type: QuizType.single,
    column: 'typical_sounds',
    isArrayMatch: true,
    options: [
      QuizOption(emoji: '🐱', label: 'Meow', value: 'meow'),
      QuizOption(emoji: '🐶', label: 'Gâu gâu', value: 'bark'),
      QuizOption(emoji: '🐔', label: 'Cục tác', value: 'cluck'),
      QuizOption(emoji: '🦁', label: 'Gầm', value: 'roar'),
      QuizOption(emoji: '🤐', label: 'Im lặng', value: null),
    ],
  ),
];

// ═══════════════════════════════════════════════════════
// QUIZ PAGE
// ═══════════════════════════════════════════════════════

class QuizPage extends StatefulWidget {
  const QuizPage({Key? key}) : super(key: key);

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with SingleTickerProviderStateMixin {
  int currentStep = 0;
  Map<String, dynamic> filters = {};
  List<Animal> results = [];
  bool isLoading = false;
  String searchQuery = '';

  Set<int> selectedIndices = {};
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  // FETCH RESULTS
  // ═══════════════════════════════════════════════════════

  Future<void> fetchResults() async {
    setState(() => isLoading = true);

    try {
      var query = Supabase.instance.client.from('animals').select();

      // Apply filters
      for (var entry in filters.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value == null) {
          query = query.isFilter(key, null);
        } else if (value is Map<String, dynamic>) {
          // First step filters (nested)
          for (var subEntry in value.entries) {
            query = query.eq(subEntry.key, subEntry.value);
          }
        } else if (value is List) {
          // Array contains
          query = query.contains(key, value);
        } else if (value is bool) {
          query = query.eq(key, value);
        } else {
          query = query.eq(key, value);
        }
      }

      final data = await query.limit(100);

      results = (data as List).map((json) => Animal.fromJson(json)).toList();

      print('Found ${results.length} results');

    } catch (e) {
      print('Error fetching: $e');
      results = [];
    }

    setState(() => isLoading = false);
  }

  // ═══════════════════════════════════════════════════════
  // SELECT OPTION
  // ═══════════════════════════════════════════════════════

  void selectOption(int index) {
    final step = quizFlow[currentStep];
    final option = step.options[index];

    setState(() {
      if (step.type == QuizType.single) {
        selectedIndices = {index};

        // Save filter
        if (option.filter != null) {
          filters.addAll(option.filter!);
        } else if (step.column != null) {
          filters[step.column!] = option.value;
        }
      } else {
        // Multi-select
        if (selectedIndices.contains(index)) {
          selectedIndices.remove(index);
        } else {
          selectedIndices.add(index);
        }

        // Update filters
        if (step.isBooleanColumns) {
          // Clear previous boolean columns
          for (var opt in step.options) {
            if (opt.column != null) {
              filters.remove(opt.column);
            }
          }

          // Add selected
          for (var idx in selectedIndices) {
            final opt = step.options[idx];
            if (opt.column != null) {
              filters[opt.column!] = opt.value;
            }
          }
        } else if (step.isArrayMatch) {
          List<dynamic> values = [];
          for (var idx in selectedIndices) {
            final val = step.options[idx].value;
            if (val is List) {
              values.addAll(val);
            } else {
              values.add(val);
            }
          }

          if (values.isNotEmpty && step.column != null) {
            filters[step.column!] = values;
          } else if (step.column != null) {
            filters.remove(step.column);
          }
        }
      }
    });

    print('Filters: $filters');
  }

  // ═══════════════════════════════════════════════════════
  // NEXT STEP
  // ═══════════════════════════════════════════════════════

  Future<void> nextStep() async {
    await fetchResults();

    if (results.length <= 10 && results.isNotEmpty) {
      // Show results
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsPage(
            results: results,
            onReset: reset,
            onBack: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    } else if (currentStep < quizFlow.length - 1) {
      setState(() {
        currentStep++;
        selectedIndices.clear();
        searchQuery = '';
      });
      _animController.reset();
      _animController.forward();
    } else {
      // Last step
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsPage(
            results: results,
            onReset: reset,
            onBack: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════
  // GO BACK
  // ═══════════════════════════════════════════════════════

  void goBack() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
        selectedIndices.clear();
        searchQuery = '';
      });
      _animController.reset();
      _animController.forward();
    }
  }

  // ═══════════════════════════════════════════════════════
  // RESET
  // ═══════════════════════════════════════════════════════

  void reset() {
    setState(() {
      currentStep = 0;
      filters.clear();
      results.clear();
      selectedIndices.clear();
      searchQuery = '';
    });
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final step = quizFlow[currentStep];
    final progress = (currentStep + 1) / quizFlow.length;

    // Filter options by search
    final filteredOptions = step.hasSearch && searchQuery.isNotEmpty
        ? step.options.where((opt) =>
        opt.label.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList()
        : step.options;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.5, -0.5),
            radius: 1.5,
            colors: [
              Color(0xFF1A1926),
              Color(0xFF0F0E17),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFF8906), Color(0xFFF25F4C), Color(0xFFE53170)],
                      ).createShader(bounds),
                      child: const Text(
                        '🐾 AniQuest',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Khám phá động vật qua câu hỏi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF1A1926),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFFF8906)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bước ${currentStep + 1}/${quizFlow.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Question Card
              Expanded(
                child: isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF8906),
                  ),
                )
                    : FadeTransition(
                  opacity: _animController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(_animController),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question Title
                          Row(
                            children: [
                              Text(
                                step.emoji,
                                style: const TextStyle(fontSize: 40),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  step.question,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          // Search (if enabled)
                          if (step.hasSearch) ...[
                            TextField(
                              onChanged: (value) {
                                setState(() => searchQuery = value);
                              },
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: step.searchPlaceholder,
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Color(0xFFFF8906),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF1A1926),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Options Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: filteredOptions.length,
                            itemBuilder: (context, index) {
                              final optionIndex = step.options.indexOf(filteredOptions[index]);
                              final option = filteredOptions[index];
                              final isSelected = selectedIndices.contains(optionIndex);

                              return GestureDetector(
                                onTap: () => selectOption(optionIndex),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFF8906).withOpacity(0.2)
                                        : const Color(0xFF1A1926),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFFF8906)
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              option.emoji,
                                              style: const TextStyle(fontSize: 40),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              option.label,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF00F5D4),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Color(0xFF0F0E17),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 30),

                          // Buttons
                          Row(
                            children: [
                              if (currentStep > 0)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: goBack,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: const BorderSide(
                                        color: Color(0xFFFF8906),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      '← Quay lại',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFF8906),
                                      ),
                                    ),
                                  ),
                                ),
                              if (currentStep > 0) const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: selectedIndices.isEmpty &&
                                      step.type == QuizType.single
                                      ? null
                                      : nextStep,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: const Color(0xFFFF8906),
                                    disabledBackgroundColor:
                                    const Color(0xFF1A1926),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    currentStep < quizFlow.length - 1
                                        ? 'Tiếp tục →'
                                        : 'Xem kết quả 🎯',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// RESULTS PAGE
// ═══════════════════════════════════════════════════════

class ResultsPage extends StatelessWidget {
  final List<Animal> results;
  final VoidCallback onReset;
  final VoidCallback onBack;

  const ResultsPage({
    Key? key,
    required this.results,
    required this.onReset,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.5, -0.5),
            radius: 1.5,
            colors: [
              Color(0xFF1A1926),
              Color(0xFF0F0E17),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          '🎯',
                          style: TextStyle(fontSize: 40),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            'Tìm thấy ${results.length} kết quả',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nhấn vào con vật để xem chi tiết',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Results
              Expanded(
                child: results.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '🔍',
                        style: TextStyle(fontSize: 80),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Không tìm thấy kết quả\nphù hợp',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
                    : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: results.length > 10 ? 10 : results.length,
                  itemBuilder: (context, index) {
                    final animal = results[index];
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AnimalDetailDialog(animal: animal),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF16141F),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFF8906).withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18),
                              ),
                              child: animal.imageUrl != null
                                  ? Image.network(
                                animal.imageUrl!,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 140,
                                  color: const Color(0xFF1A1926),
                                  child: const Icon(
                                    Icons.pets,
                                    size: 50,
                                    color: Color(0xFFFF8906),
                                  ),
                                ),
                              )
                                  : Container(
                                height: 140,
                                color: const Color(0xFF1A1926),
                                child: const Icon(
                                  Icons.pets,
                                  size: 50,
                                  color: Color(0xFFFF8906),
                                ),
                              ),
                            ),

                            // Content
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    animal.nameVietnamese,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (animal.scientificName != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      animal.scientificName!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.white.withOpacity(0.6),
                                        fontFamily: 'monospace',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF8906),
                                          Color(0xFFF25F4C)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${85 + (index * 2)}% khớp',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onBack,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFFFF8906)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          '← Lọc thêm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF8906),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onReset,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFFFF8906),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          '🔄 Tìm lại',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
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
}

// ═══════════════════════════════════════════════════════
// ANIMAL DETAIL DIALOG
// ═══════════════════════════════════════════════════════

class AnimalDetailDialog extends StatelessWidget {
  final Animal animal;

  const AnimalDetailDialog({Key? key, required this.animal}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF16141F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎉',
              style: TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 16),
            Text(
              'Đây có phải là ${animal.nameVietnamese}?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (animal.scientificName != null) ...[
              const SizedBox(height: 8),
              Text(
                animal.scientificName!,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFFF8906)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '❌ Không phải',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF8906),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Show success
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => const SuccessDialog(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFFFF8906),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '✅ Đúng rồi!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// SUCCESS DIALOG
// ═══════════════════════════════════════════════════════

class SuccessDialog extends StatelessWidget {
  const SuccessDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    return Dialog(
      backgroundColor: const Color(0xFF16141F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎊',
              style: TextStyle(fontSize: 80),
            ),
            SizedBox(height: 20),
            Text(
              'Tuyệt vời!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Bạn đã tìm đúng!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}