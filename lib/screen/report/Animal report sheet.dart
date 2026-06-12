import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kltn_app/screen/report/service_rp.dart';

// Hàm mở bottom sheet report – gọi từ bất cứ đâu
void showAnimalReportSheet(
  BuildContext context, {
  required String animalId,
  required Map<String, dynamic> animal,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AnimalReportSheet(animalId: animalId, animal: animal),
  );
}

// Bottom Sheet chính
class AnimalReportSheet extends StatefulWidget {
  final String animalId;
  final Map<String, dynamic> animal;

  const AnimalReportSheet({
    super.key,
    required this.animalId,
    required this.animal,
  });

  @override
  State<AnimalReportSheet> createState() => _AnimalReportSheetState();
}

class _AnimalReportSheetState extends State<AnimalReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _service = AnimalReportService();

  // Reporter info
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Suggested fields
  late final TextEditingController _nameViCtrl;
  late final TextEditingController _nameEnCtrl;
  late final TextEditingController _sciNameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _funFactCtrl;
  late final TextEditingController _imageUrlCtrl;
  late final TextEditingController _noteCtrl;

  // Numeric fields
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _lifespanCtrl;
  late final TextEditingController _speedCtrl;

  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final a = widget.animal;
    _nameViCtrl = TextEditingController(text: a['name_vietnamese'] ?? '');
    _nameEnCtrl = TextEditingController(text: a['name_english'] ?? '');
    _sciNameCtrl = TextEditingController(text: a['scientific_name'] ?? '');
    _descCtrl = TextEditingController(text: a['description_short'] ?? '');
    _funFactCtrl = TextEditingController(text: a['fun_fact_vietnamese'] ?? '');
    _imageUrlCtrl = TextEditingController(text: a['image_url'] ?? '');
    _noteCtrl = TextEditingController();

    _weightCtrl = TextEditingController(
      text: a['weight_avg_kg'] != null ? '${a['weight_avg_kg']}' : '',
    );
    _heightCtrl = TextEditingController(
      text: a['height_avg_m'] != null ? '${a['height_avg_m']}' : '',
    );
    _lifespanCtrl = TextEditingController(
      text: a['lifespan_avg_years'] != null ? '${a['lifespan_avg_years']}' : '',
    );
    _speedCtrl = TextEditingController(
      text: a['max_speed_kmh'] != null ? '${a['max_speed_kmh']}' : '',
    );
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _emailCtrl,
      _nameViCtrl,
      _nameEnCtrl,
      _sciNameCtrl,
      _descCtrl,
      _funFactCtrl,
      _imageUrlCtrl,
      _noteCtrl,
      _weightCtrl,
      _heightCtrl,
      _lifespanCtrl,
      _speedCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final a = widget.animal;

      // Chỉ gửi những trường đã thay đổi so với dữ liệu gốc
      final suggestedFields = <String, dynamic>{};
      void addIfChanged(String key, String ctrl, dynamic original) {
        final trimmed = ctrl.trim();
        if (trimmed.isNotEmpty && trimmed != '$original') {
          suggestedFields[key] = trimmed;
        }
      }

      addIfChanged('weight_avg_kg', _weightCtrl.text, a['weight_avg_kg']);
      addIfChanged('height_avg_m', _heightCtrl.text, a['height_avg_m']);
      addIfChanged(
        'lifespan_avg_years',
        _lifespanCtrl.text,
        a['lifespan_avg_years'],
      );
      addIfChanged('max_speed_kmh', _speedCtrl.text, a['max_speed_kmh']);

      String? changedOrNull(TextEditingController c, String? original) {
        final v = c.text.trim();
        return (v.isNotEmpty && v != (original ?? '')) ? v : null;
      }

      await _service.submitReport(
        animalId: widget.animalId,
        reporterName: _nameCtrl.text.trim().isNotEmpty
            ? _nameCtrl.text.trim()
            : null,
        reporterEmail: _emailCtrl.text.trim().isNotEmpty
            ? _emailCtrl.text.trim()
            : null,
        suggestedNameVi: changedOrNull(_nameViCtrl, a['name_vietnamese']),
        suggestedNameEn: changedOrNull(_nameEnCtrl, a['name_english']),
        suggestedScientificName: changedOrNull(
          _sciNameCtrl,
          a['scientific_name'],
        ),
        suggestedDescription: changedOrNull(_descCtrl, a['description_short']),
        suggestedFunFact: changedOrNull(_funFactCtrl, a['fun_fact_vietnamese']),
        suggestedImageUrl: changedOrNull(_imageUrlCtrl, a['image_url']),
        suggestedFields: suggestedFields.isNotEmpty ? suggestedFields : null,
        note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
      );

      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gửi thất bại: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _submitted
            ? _buildSuccess(colorScheme)
            : _buildForm(colorScheme, scrollCtrl),
      ),
    );
  }

  // Màn hình thành công
  Widget _buildSuccess(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('✅', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Đã gửi báo cáo!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Cảm ơn bạn đã đóng góp. Chúng tôi sẽ xem xét và cập nhật thông tin sớm nhất.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  // Form chính
  Widget _buildForm(ColorScheme cs, ScrollController scrollCtrl) {
    return Form(
      key: _formKey,
      child: ListView(
        controller: scrollCtrl,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.flag_rounded, color: cs.error, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Báo cáo thông tin sai',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'Chỉnh sửa trực tiếp những gì bạn cho là không chính xác',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _sectionHeader('Thông tin của bạn (tùy chọn)', cs),
          const SizedBox(height: 12),
          _buildTextField(
            _nameCtrl,
            'Họ tên',
            Icons.person_outline_rounded,
            cs,
            required: false,
          ),
          const SizedBox(height: 10),
          _buildTextField(
            _emailCtrl,
            'Email liên hệ',
            Icons.email_outlined,
            cs,
            required: false,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 24),
          _sectionHeader('Tên & Phân loại', cs),
          const SizedBox(height: 12),
          _buildTextField(
            _nameViCtrl,
            'Tên tiếng Việt',
            Icons.translate_rounded,
            cs,
          ),
          const SizedBox(height: 10),
          _buildTextField(
            _nameEnCtrl,
            'Tên tiếng Anh',
            Icons.language_rounded,
            cs,
          ),
          const SizedBox(height: 10),
          _buildTextField(
            _sciNameCtrl,
            'Tên khoa học',
            Icons.biotech_rounded,
            cs,
          ),

          const SizedBox(height: 24),
          _sectionHeader('Chỉ số sinh học', cs),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _weightCtrl,
                  'Cân nặng (kg)',
                  Icons.monitor_weight_outlined,
                  cs,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  _heightCtrl,
                  'Chiều cao (m)',
                  Icons.height_rounded,
                  cs,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _lifespanCtrl,
                  'Tuổi thọ (năm)',
                  Icons.hourglass_empty_rounded,
                  cs,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  _speedCtrl,
                  'Tốc độ (km/h)',
                  Icons.speed_rounded,
                  cs,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _sectionHeader('Mô tả & Fun fact', cs),
          const SizedBox(height: 12),
          _buildTextField(
            _descCtrl,
            'Mô tả ngắn',
            Icons.description_outlined,
            cs,
            maxLines: 4,
          ),
          const SizedBox(height: 10),
          _buildTextField(
            _funFactCtrl,
            'Fun fact tiếng Việt',
            Icons.lightbulb_outline_rounded,
            cs,
            maxLines: 3,
          ),

          const SizedBox(height: 24),
          _sectionHeader('Hình ảnh', cs),
          const SizedBox(height: 12),
          _buildTextField(
            _imageUrlCtrl,
            'URL hình ảnh mới',
            Icons.image_outlined,
            cs,
            keyboardType: TextInputType.url,
          ),

          const SizedBox(height: 24),
          _sectionHeader('Ghi chú thêm', cs),
          const SizedBox(height: 12),
          _buildTextField(
            _noteCtrl,
            'Giải thích thêm hoặc nguồn tham khảo...',
            Icons.notes_rounded,
            cs,
            maxLines: 3,
            required: false,
          ),

          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_isSubmitting ? 'Đang gửi...' : 'Gửi báo cáo'),
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, ColorScheme cs) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: cs.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    ColorScheme cs, {
    int maxLines = 1,
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14, color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: cs.onSurfaceVariant),
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
                ? 'Vui lòng điền thông tin'
                : null
          : null,
    );
  }
}
