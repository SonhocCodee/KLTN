import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kltn_app/screen/IDENTIFY%20SCREEN/service/Identify_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Animal_detail/Animal detail screen.dart';
import '../language/Locale_provider.dart';
import '../home/animal_category_model.dart';
import 'widgets/identify_header.dart';
import 'widgets/identify_image_frame.dart';
import 'widgets/identify_action_buttons.dart';
import 'widgets/identify_result_section.dart';
import 'widgets/identify_loading_overlay.dart';

class IdentifyScreen extends StatelessWidget {
  const IdentifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IdentifyService()..loadModel(),
      child: const IdentifyView(),
    );
  }
}

class IdentifyView extends StatefulWidget {
  const IdentifyView({super.key});

  @override
  State<IdentifyView> createState() => _IdentifyViewState();
}

class _IdentifyViewState extends State<IdentifyView>
    with SingleTickerProviderStateMixin {
  late AnimationController _cardAnimCtrl;
  late Animation<double> _cardFadeAnim;
  late Animation<Offset> _cardSlideAnim;

  @override
  void initState() {
    super.initState();
    _cardAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardFadeAnim = CurvedAnimation(parent: _cardAnimCtrl, curve: Curves.easeOut);
    _cardSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardAnimCtrl, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _cardAnimCtrl.dispose();
    super.dispose();
  }

  void _onSearchDone() {
    _cardAnimCtrl.forward(from: 0);
  }

  void _openDetail(String? resultAnimalId, LocaleProvider t) {
    if (resultAnimalId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalDetailScreen(
          animalId: resultAnimalId,
          category: _buildCatCategory(t),
        ),
      ),
    );
  }

  AnimalCategory _buildCatCategory(LocaleProvider t) {
    return AnimalCategory.getById('cat') ??
        AnimalCategory(
          id: 'cat',
          nameVi: t.tr('Mèo'),
          nameEn: 'Cat',
          icon: Icons.pets,
          gradient: const [Color(0xFFEC4899), Color(0xFFDB2777)],
          imageAssetPath: 'assets/animals/cat.jpg',
          totalExpected: 73,
        );
  }

  void _openAnimalChat(IdentifyService identifyService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: identifyService,
        child: const AnimalChatSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<IdentifyService>();
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IdentifyHeader(service: service),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        IdentifyImageFrame(
                          selectedImage: service.selectedImage,
                          onClear: () {
                            service.clearImage();
                            _cardAnimCtrl.reset();
                          },
                        ),
                        const SizedBox(height: 24),
                        IdentifyActionButtons(
                          service: service,
                          onSearch: () => service.startSearching(_onSearchDone),
                        ),
                        const SizedBox(height: 24),
                        IdentifyResultSection(
                          service: service,
                          fadeAnim: _cardFadeAnim,
                          slideAnim: _cardSlideAnim,
                          onOpenDetail: () => _openDetail(service.resultAnimalId, t),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          IdentifyLoadingOverlay(service: service),

          // Nút chatbot nổi.
          Positioned(
            right: 18,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
            child: FloatingActionButton.extended(
              heroTag: 'animal_ai_chatbot',
              onPressed: () => _openAnimalChat(service),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: const Icon(Icons.smart_toy_rounded),
              label: Text(t.tr('Hỏi AI')),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// CHATBOT UI
// ════════════════════════════════════════════════════════════════

class AnimalChatSheet extends StatefulWidget {
  const AnimalChatSheet({super.key});

  @override
  State<AnimalChatSheet> createState() => _AnimalChatSheetState();
}

class _AnimalChatSheetState extends State<AnimalChatSheet> {
  final _chatService = GroqAnimalChatService();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<AnimalChatMessage> _messages = [];
  bool _isSending = false;
  bool _useCurrentImage = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final items = await AnimalChatStorage.load();
    if (!mounted) return;
    setState(() {
      _messages = items.isEmpty
          ? [
              AnimalChatMessage.assistant(
                'Xin chào! Mình là trợ lý AI động vật. Bạn có thể hỏi kiểu: “mèo lông dài màu trắng mắt xanh là giống gì?”, “hổ ăn gì?”, hoặc hỏi về ảnh đang chọn.',
              ),
            ]
          : items;
    });
  }

  Future<void> _saveHistory() async {
    await AnimalChatStorage.save(_messages);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 240,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _clearHistory() async {
    await AnimalChatStorage.clear();
    if (!mounted) return;
    setState(() {
      _messages = [
        AnimalChatMessage.assistant(
          'Đã xoá lịch sử. Bạn muốn tìm hoặc hỏi về con vật nào?',
        ),
      ];
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    final identifyService = context.read<IdentifyService>();
    final File? imageFile = _useCurrentImage ? identifyService.selectedImage : null;

    setState(() {
      _inputCtrl.clear();
      _isSending = true;
      _messages.add(AnimalChatMessage.user(text));
      _messages.add(AnimalChatMessage.assistant('Đang xử lý...', isLoading: true));
    });
    _scrollToBottom();

    try {
      final answer = await _chatService.ask(
        question: text,
        identifyService: identifyService,
        imageFile: imageFile,
        recentMessages: _messages.where((m) => !m.isLoading).toList(),
      );

      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.isLoading);
        _messages.add(AnimalChatMessage.assistant(answer));
        _isSending = false;
      });
      await _saveHistory();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.isLoading);
        _messages.add(AnimalChatMessage.assistant('Mình chưa xử lý được câu hỏi này. Lỗi: $e'));
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final identifyService = context.watch<IdentifyService>();
    final hasImage = identifyService.selectedImage != null;
    final hasResult = identifyService.resultNameVi != null || identifyService.resultNameEn != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.50,
      maxChildSize: 0.96,
      builder: (context, sheetScrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.16),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.smart_toy_rounded, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trợ lý động vật AI',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            'Groq Llama + dữ liệu Supabase',
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Xoá lịch sử',
                      onPressed: _clearHistory,
                      icon: const Icon(Icons.delete_sweep_rounded),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),

              if (hasImage || hasResult)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        if (hasImage)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              identifyService.selectedImage!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Icon(Icons.pets_rounded, color: cs.primary, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasResult
                                    ? 'Ngữ cảnh: ${identifyService.resultNameVi ?? identifyService.resultNameEn}'
                                    : 'Có ảnh hiện tại',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
                              ),
                              Text(
                                hasImage ? 'Có thể gửi ảnh này kèm câu hỏi cho Llama.' : 'AI sẽ dùng kết quả nhận diện làm ngữ cảnh.',
                                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        if (hasImage)
                          Switch.adaptive(
                            value: _useCurrentImage,
                            onChanged: _isSending ? null : (v) => setState(() => _useCurrentImage = v),
                          ),
                      ],
                    ),
                  ),
                ),

              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => AnimalChatBubble(message: _messages[i]),
                ),
              ),

              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 14,
                    right: 14,
                    bottom: 10,
                    top: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputCtrl,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: 'Hỏi: mèo lông dài màu trắng mắt xanh...',
                            filled: true,
                            fillColor: cs.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(color: cs.outlineVariant),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(color: cs.outlineVariant),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: FilledButton(
                          onPressed: _isSending ? null : _send,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: _isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AnimalChatBubble extends StatelessWidget {
  final AnimalChatMessage message;
  const AnimalChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = message.role == AnimalChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 18),
          ),
        ),
        child: message.isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 10),
                  Text(message.text, style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              )
            : SelectableText(
                message.text,
                style: TextStyle(
                  color: isUser ? cs.onPrimary : cs.onSurface,
                  height: 1.42,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// CHATBOT MODEL + STORAGE
// ════════════════════════════════════════════════════════════════

enum AnimalChatRole { user, assistant }

class AnimalChatMessage {
  final AnimalChatRole role;
  final String text;
  final DateTime createdAt;
  final bool isLoading;

  AnimalChatMessage({
    required this.role,
    required this.text,
    required this.createdAt,
    this.isLoading = false,
  });

  factory AnimalChatMessage.user(String text) => AnimalChatMessage(
        role: AnimalChatRole.user,
        text: text,
        createdAt: DateTime.now(),
      );

  factory AnimalChatMessage.assistant(String text, {bool isLoading = false}) =>
      AnimalChatMessage(
        role: AnimalChatRole.assistant,
        text: text,
        createdAt: DateTime.now(),
        isLoading: isLoading,
      );

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'text': text,
        'created_at': createdAt.toIso8601String(),
      };

  factory AnimalChatMessage.fromJson(Map<String, dynamic> json) => AnimalChatMessage(
        role: json['role'] == 'user' ? AnimalChatRole.user : AnimalChatRole.assistant,
        text: json['text']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class AnimalChatStorage {
  static const _key = 'animal_ai_chat_history_v1';

  static Future<List<AnimalChatMessage>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => AnimalChatMessage.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<AnimalChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = messages.where((m) => !m.isLoading).toList();
    final keepLast = clean.length > 80 ? clean.sublist(clean.length - 80) : clean;
    await prefs.setString(_key, jsonEncode(keepLast.map((e) => e.toJson()).toList()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class AnimalFeatureQuery {
  final String? animalType;
  final Map<String, dynamic> filters;
  final Map<String, dynamic> unsupportedFilters;
  final String? nameKeywordVi;
  final String? nameKeywordEn;

  const AnimalFeatureQuery({
    this.animalType,
    this.filters = const {},
    this.unsupportedFilters = const {},
    this.nameKeywordVi,
    this.nameKeywordEn,
  });
}

class RetrievedAnimalContext {
  final List<Map<String, dynamic>> animals;
  final AnimalFeatureQuery parsedQuery;
  final String sourceTable;

  const RetrievedAnimalContext({
    required this.animals,
    required this.parsedQuery,
    required this.sourceTable,
  });

  String toPromptText() {
    if (animals.isEmpty) {
      return 'Không tìm thấy bản ghi phù hợp trong database.';
    }
    final compact = animals.take(8).map((a) {
      return {
        'id': a['id'],
        'ten_viet': a['name_vietnamese'],
        'ten_anh': a['name_english'],
        'ten_khoa_hoc': a['scientific_name'],
        'loai': a['animal_type'],
        'mo_ta': a['description_short'],
        'moi_truong_song': a['primary_habitat'],
        'che_do_an': a['diet_type'],
        'kich_thuoc': a['relative_size'] ?? a['size_category'],
        'can_nang_kg': a['weight_avg_kg'],
        'tuoi_tho': a['lifespan_avg_years'],
        'mau_chinh': a['primary_colors'],
        'hoa_van': a['patterns'],
        'do_dai_long': a['coat_length'] ?? a['fur_type'],
        'duoi_dai': a['has_long_tail'],
        'tai_cup': a['has_floppy_ears'],
        'long_xu': a['is_fluffy'],
        'tinh_cach': a['temperament'],
        'bao_ton': a['conservation_status'],
        'diem_khop': a['_match_score'],
      };
    }).toList();

    return const JsonEncoder.withIndent('  ').convert({
      'bang_du_lieu': sourceTable,
      'bo_loc_hop_le': parsedQuery.filters,
      'dac_diem_chua_co_trong_db': parsedQuery.unsupportedFilters,
      'ket_qua': compact,
    });
  }
}

class GroqAnimalChatService {
  // Khuyến nghị chạy bằng: flutter run --dart-define=GROQ_API_KEY=gsk_xxx
  // Không nên hard-code key trong app production.
  static const String _groqApiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _groqModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  final SupabaseClient _db = Supabase.instance.client;

  Future<String> ask({
    required String question,
    required IdentifyService identifyService,
    File? imageFile,
    List<AnimalChatMessage> recentMessages = const [],
  }) async {
    if (_groqApiKey.isEmpty) {
      return 'Chưa cấu hình GROQ_API_KEY. Chạy app bằng:\nflutter run --dart-define=GROQ_API_KEY=gsk_xxx\n\nHoặc tốt hơn: gọi qua backend/Edge Function để không lộ API key.';
    }

    final retrieved = await _retrieveRelevantAnimals(question);
    final currentIdentifyContext = _buildIdentifyContext(identifyService);
    final historyText = _buildHistoryText(recentMessages);
    final imagePart = await _buildOptionalImagePart(imageFile);

    final prompt = '''
Bạn là trợ lý AI của ứng dụng từ điển động vật ZooTrek.
Nhiệm vụ: trả lời câu hỏi người dùng bằng tiếng Việt, dễ hiểu, ngắn gọn nhưng đủ ý.

QUY TẮC BẮT BUỘC:
1. Ưu tiên trả lời dựa trên DỮ LIỆU DATABASE được cung cấp.
2. Nếu database thiếu dữ liệu, được dùng kiến thức chung nhưng phải ghi rõ: “Thông tin tham khảo ngoài dữ liệu hệ thống”.
3. Không được tự bịa tên cột, không được nói chắc chắn khi dữ liệu không có.
4. Nếu câu hỏi là tìm loài theo đặc điểm, hãy nêu các loài/giống phù hợp nhất và nói rõ tiêu chí nào chưa có trong database.
5. Nếu có ảnh, hãy dùng ảnh như ngữ cảnh bổ sung, nhưng vẫn đối chiếu với dữ liệu database.
6. Nếu câu hỏi không liên quan đến động vật, hãy từ chối nhẹ nhàng.

LỊCH SỬ GẦN ĐÂY:
$historyText

NGỮ CẢNH NHẬN DIỆN ẢNH HIỆN TẠI:
$currentIdentifyContext

DỮ LIỆU DATABASE LIÊN QUAN:
${retrieved.toPromptText()}

CÂU HỎI NGƯỜI DÙNG:
$question
''';

    final userContent = imagePart == null
        ? prompt
        : [
            {'type': 'text', 'text': prompt},
            imagePart,
          ];

    final body = jsonEncode({
      'model': _groqModel,
      'messages': [
        {
          'role': 'system',
          'content': 'Bạn là trợ lý AI chuyên về động vật. Trả lời bằng tiếng Việt. Không bịa khi thiếu dữ liệu.',
        },
        {'role': 'user', 'content': userContent},
      ],
      'temperature': 0.2,
      'max_tokens': 650,
    });

    final res = await http
        .post(
          Uri.parse(_groqUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_groqApiKey',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 35));

    if (res.statusCode != 200) {
      return 'Groq API lỗi ${res.statusCode}. Nội dung: ${res.body}';
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      return 'AI không trả về nội dung.';
    }

    final text = choices.first['message']?['content']?.toString().trim();
    return (text == null || text.isEmpty) ? 'AI không trả về nội dung.' : text;
  }

  String _buildIdentifyContext(IdentifyService service) {
    final data = {
      'result_name_vi': service.resultNameVi,
      'result_name_en': service.resultNameEn,
      'confidence': service.resultConfidence,
      'animal_id': service.resultAnimalId,
      'ai_source': service.aiSource,
      'has_selected_image': service.selectedImage != null,
      'is_not_animal': service.isNotAnimal,
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  String _buildHistoryText(List<AnimalChatMessage> messages) {
    final clean = messages.where((m) => !m.isLoading).toList();
    final last = clean.length > 8 ? clean.sublist(clean.length - 8) : clean;
    if (last.isEmpty) return 'Chưa có lịch sử.';
    return last
        .map((m) => '${m.role == AnimalChatRole.user ? 'User' : 'Assistant'}: ${m.text}')
        .join('\n');
  }

  Future<Map<String, dynamic>?> _buildOptionalImagePart(File? imageFile) async {
    if (imageFile == null) return null;
    try {
      final bytes = await imageFile.readAsBytes();
      // Tránh gửi ảnh quá lớn làm chậm hoặc lỗi request.
      if (bytes.length > 3 * 1024 * 1024) return null;
      return {
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,${base64Encode(bytes)}'},
      };
    } catch (_) {
      return null;
    }
  }

  Future<RetrievedAnimalContext> _retrieveRelevantAnimals(String question) async {
    final parsed = _parseFeatureQuery(question);
    final table = _chooseTable(parsed);

    List<Map<String, dynamic>> rows = [];

    try {
      if (parsed.nameKeywordVi != null || parsed.nameKeywordEn != null) {
        rows = await _queryByName(parsed);
      }

      if (rows.isEmpty) {
        rows = await _queryBroad(table, parsed);
      }
    } catch (_) {
      // Fallback về bảng animals nếu cats/dogs lỗi hoặc bảng chưa có.
      try {
        rows = await _queryBroad('animals', parsed);
      } catch (_) {
        rows = [];
      }
    }

    final scored = _scoreRows(rows, parsed);
    return RetrievedAnimalContext(
      animals: scored.take(8).toList(),
      parsedQuery: parsed,
      sourceTable: table,
    );
  }

  String _chooseTable(AnimalFeatureQuery parsed) {
    if (parsed.animalType == 'cat') return 'cats';
    if (parsed.animalType == 'dog') return 'dogs';
    return 'animals';
  }

  Future<List<Map<String, dynamic>>> _queryByName(AnimalFeatureQuery parsed) async {
    final vi = parsed.nameKeywordVi;
    final en = parsed.nameKeywordEn;
    final parts = <String>[];
    if (vi != null) parts.add('name_vietnamese.ilike.%${_escapeIlike(vi)}%');
    if (en != null) parts.add('name_english.ilike.%${_escapeIlike(en)}%');

    if (parts.isEmpty) return [];

    final data = await _db
        .from('animals')
        .select('*')
        .or(parts.join(','))
        .limit(20);

    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<List<Map<String, dynamic>>> _queryBroad(String table, AnimalFeatureQuery parsed) async {
    dynamic query = _db.from(table).select('*');

    // Với bảng animals thì có animal_type. Với cats/dogs có thể không cần.
    if (table == 'animals' && parsed.animalType != null) {
      query = query.eq('animal_type', parsed.animalType);
    }

    final data = await query.limit(120);
    return List<Map<String, dynamic>>.from(data as List);
  }

  String _escapeIlike(String input) => input.replaceAll('%', '').replaceAll(',', ' ').trim();

  List<Map<String, dynamic>> _scoreRows(List<Map<String, dynamic>> rows, AnimalFeatureQuery parsed) {
    final filters = parsed.filters;
    final hasFilters = filters.isNotEmpty;

    final scored = rows.map((row) {
      var score = 0;

      if (parsed.nameKeywordVi != null && _containsText(row['name_vietnamese'], parsed.nameKeywordVi!)) score += 8;
      if (parsed.nameKeywordEn != null && _containsText(row['name_english'], parsed.nameKeywordEn!)) score += 8;

      if (parsed.animalType != null) {
        final rowType = row['animal_type']?.toString();
        if (rowType == null || rowType == parsed.animalType) score += 2;
      }

      for (final entry in filters.entries) {
        final key = entry.key;
        final expected = entry.value;
        final actual = row[key];

        if (_fieldMatches(actual, expected)) {
          if (key == 'primary_colors' || key == 'coat_length' || key == 'fur_type') {
            score += 3;
          } else {
            score += 2;
          }
        }
      }

      final copy = Map<String, dynamic>.from(row);
      copy['_match_score'] = score;
      return copy;
    }).where((row) {
      if (!hasFilters && parsed.nameKeywordVi == null && parsed.nameKeywordEn == null) return true;
      return (row['_match_score'] as int? ?? 0) > 0;
    }).toList();

    scored.sort((a, b) => (b['_match_score'] as int).compareTo(a['_match_score'] as int));
    return scored;
  }

  bool _fieldMatches(dynamic actual, dynamic expected) {
    if (actual == null || expected == null) return false;

    if (actual is List) {
      if (expected is List) {
        return expected.any((e) => actual.map((x) => x.toString().toLowerCase()).contains(e.toString().toLowerCase()));
      }
      return actual.map((x) => x.toString().toLowerCase()).contains(expected.toString().toLowerCase());
    }

    if (expected is List) {
      return expected.any((e) => actual.toString().toLowerCase() == e.toString().toLowerCase());
    }

    if (expected is bool) return actual == expected || actual.toString() == expected.toString();

    return actual.toString().toLowerCase() == expected.toString().toLowerCase();
  }

  bool _containsText(dynamic value, String keyword) {
    return _norm(value?.toString() ?? '').contains(_norm(keyword));
  }

  AnimalFeatureQuery _parseFeatureQuery(String input) {
    final q = _norm(input);
    String? animalType;
    String? nameVi;
    String? nameEn;

    for (final e in _nameHints.entries) {
      if (q.contains(_norm(e.key))) {
        animalType = e.value['animal_type'];
        nameVi = e.value['vi'];
        nameEn = e.value['en'];
        break;
      }
    }

    if (animalType == null) {
      if (_hasAny(q, ['meo', 'cat', 'mèo'])) animalType = 'cat';
      if (_hasAny(q, ['cho', 'dog', 'chó'])) animalType = 'dog';
      if (_hasAny(q, ['ho', 'tiger', 'hổ'])) animalType = 'tiger';
      if (_hasAny(q, ['su tu', 'lion', 'sư tử'])) animalType = 'lion';
      if (_hasAny(q, ['gau', 'bear', 'gấu'])) animalType = 'bear';
      if (_hasAny(q, ['ngua', 'horse', 'ngựa'])) animalType = 'horse';
      if (_hasAny(q, ['bo ', 'cow', 'cattle', 'bò'])) animalType = 'cattle';
      if (_hasAny(q, ['trau', 'buffalo', 'trâu'])) animalType = 'buffalo';
    }

    final filters = <String, dynamic>{};
    final unsupported = <String, dynamic>{};

    // Màu lông/màu cơ thể.
    final colors = <String>[];
    for (final e in _colorMap.entries) {
      if (_hasAny(q, e.value)) colors.add(e.key);
    }
    if (colors.isNotEmpty) filters['primary_colors'] = colors;

    // Lông dài/ngắn. Bảng cats/dogs thường có coat_length, bảng animals có thể chỉ có fur_type.
    if (_hasAny(q, ['long dai', 'long dài', 'fur long', 'long hair', 'long-haired', 'longhaired'])) {
      filters['coat_length'] = 'long';
    } else if (_hasAny(q, ['long ngan', 'lông ngắn', 'short hair', 'short-haired', 'shorthaired'])) {
      filters['coat_length'] = 'short';
    } else if (_hasAny(q, ['khong long', 'không lông', 'hairless'])) {
      filters['coat_length'] = 'hairless';
    }

    if (_hasAny(q, ['xu', 'xù', 'fluffy', 'bong xu', 'bông xù'])) filters['is_fluffy'] = true;
    if (_hasAny(q, ['duoi dai', 'đuôi dài', 'long tail'])) filters['has_long_tail'] = true;
    if (_hasAny(q, ['duoi ngan', 'đuôi ngắn', 'short tail', 'cut duoi', 'cụt đuôi'])) filters['has_long_tail'] = false;
    if (_hasAny(q, ['tai cup', 'tai cụp', 'floppy ears', 'folded ears'])) filters['has_floppy_ears'] = true;
    if (_hasAny(q, ['tai dung', 'tai dựng', 'pointy ears'])) filters['has_floppy_ears'] = false;

    if (_hasAny(q, ['an thit', 'ăn thịt', 'carnivore'])) filters['diet_type'] = 'carnivore';
    if (_hasAny(q, ['an co', 'ăn cỏ', 'herbivore'])) filters['diet_type'] = 'herbivore';
    if (_hasAny(q, ['an tap', 'ăn tạp', 'omnivore'])) filters['diet_type'] = 'omnivore';

    if (_hasAny(q, ['mat xanh', 'mắt xanh', 'blue eyes', 'blue eye'])) {
      unsupported['eye_colors'] = ['blue'];
    }
    if (_hasAny(q, ['duoi co long dai', 'đuôi có lông dài', 'long fur tail', 'bushy tail'])) {
      unsupported['tail_fur_length'] = 'long';
      filters['has_long_tail'] = true;
      filters['is_fluffy'] = true;
    }

    return AnimalFeatureQuery(
      animalType: animalType,
      filters: filters,
      unsupportedFilters: unsupported,
      nameKeywordVi: nameVi,
      nameKeywordEn: nameEn,
    );
  }

  bool _hasAny(String q, List<String> terms) {
    return terms.any((t) => q.contains(_norm(t)));
  }

  static const Map<String, Map<String, String>> _nameHints = {
    'hổ': {'animal_type': 'tiger', 'vi': 'Hổ', 'en': 'Tiger'},
    'tiger': {'animal_type': 'tiger', 'vi': 'Hổ', 'en': 'Tiger'},
    'sư tử': {'animal_type': 'lion', 'vi': 'Sư tử', 'en': 'Lion'},
    'lion': {'animal_type': 'lion', 'vi': 'Sư tử', 'en': 'Lion'},
    'gấu': {'animal_type': 'bear', 'vi': 'Gấu', 'en': 'Bear'},
    'bear': {'animal_type': 'bear', 'vi': 'Gấu', 'en': 'Bear'},
    'ngựa': {'animal_type': 'horse', 'vi': 'Ngựa', 'en': 'Horse'},
    'horse': {'animal_type': 'horse', 'vi': 'Ngựa', 'en': 'Horse'},
    'bò': {'animal_type': 'cattle', 'vi': 'Bò', 'en': 'Cattle'},
    'cattle': {'animal_type': 'cattle', 'vi': 'Bò', 'en': 'Cattle'},
    'trâu': {'animal_type': 'buffalo', 'vi': 'Trâu', 'en': 'Buffalo'},
    'buffalo': {'animal_type': 'buffalo', 'vi': 'Trâu', 'en': 'Buffalo'},
  };

  static const Map<String, List<String>> _colorMap = {
    'white': ['trang', 'trắng', 'white'],
    'black': ['den', 'đen', 'black'],
    'orange': ['cam', 'vang dam', 'vàng đậm', 'orange', 'ginger'],
    'gray': ['xam', 'xám', 'grey', 'gray'],
    'cream': ['kem', 'cream'],
    'brown': ['nau', 'nâu', 'brown'],
    'golden': ['vang', 'vàng', 'golden'],
  };

  String _norm(String s) {
    var v = s.toLowerCase().trim();
    const from = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to =   'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    for (var i = 0; i < from.length && i < to.length; i++) {
      v = v.replaceAll(from[i], to[i]);
    }
    v = v.replaceAll(RegExp(r'\s+'), ' ');
    return v;
  }
}
