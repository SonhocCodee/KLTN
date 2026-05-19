import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';
import 'animal_api_cache_service.dart';

class AnimalDetailSound extends StatefulWidget {
  final Map<String, dynamic> animal;

  const AnimalDetailSound({super.key, required this.animal});

  @override
  State<AnimalDetailSound> createState() => _AnimalDetailSoundState();
}

class _AnimalDetailSoundState extends State<AnimalDetailSound> {
  final AudioPlayer _player = AudioPlayer();
  final _cache = AnimalApiCacheService.instance;

  List<Map<String, dynamic>> _sounds = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _currentIndex = 0;
  bool _isPlaying = false;

  String get _animalId => widget.animal['id']?.toString() ?? '';

  static const _validContentTypes = {
    'audio/mp3',
    'audio/mpeg',
    'audio/wav',
    'audio/x-wav',
    'audio/mp4',
    'audio/ogg',
  };

  @override
  void initState() {
    super.initState();
    _fetchSounds();
    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _fetchSounds() async {
    // ── 1. Cache ─────────────────────────────────────────────────────────
    final cached = await _cache.getSounds(_animalId);
    if (cached != null) {
      setState(() {
        _sounds = cached;
        _isLoading = false;
        _hasError = cached.isEmpty;
      });
      return;
    }

    // ── 2. Gọi API ───────────────────────────────────────────────────────
    final scientificName =
        widget.animal['scientific_name'] ?? widget.animal['name'] ?? '';
    if (scientificName.isEmpty) {
      setState(() { _isLoading = false; _hasError = true; });
      return;
    }

    try {
      // Tìm taxon_id
      final taxonRes = await http.get(Uri.parse(
          'https://api.inaturalist.org/v1/taxa'
              '?q=${Uri.encodeComponent(scientificName)}&limit=1'));
      if (taxonRes.statusCode != 200) throw Exception('Taxon not found');

      final taxonData = jsonDecode(taxonRes.body);
      final taxonResults = taxonData['results'] as List?;
      if (taxonResults == null || taxonResults.isEmpty) throw Exception('No taxon');
      final taxonId = taxonResults[0]['id'];

      // Fetch 2 batch song song:
      // Batch A: research grade, sort by votes (tốt nhất trước)
      // Batch B: research grade, sort by faves (được like nhiều nhất)
      final responses = await Future.wait([
        http.get(Uri.parse(
            'https://api.inaturalist.org/v1/observations'
                '?taxon_id=$taxonId&sounds=true&quality_grade=research'
                '&per_page=30&order_by=votes&order=desc')),
        http.get(Uri.parse(
            'https://api.inaturalist.org/v1/observations'
                '?taxon_id=$taxonId&sounds=true&quality_grade=research'
                '&per_page=20&order_by=faves&order=desc')),
      ]);

      // Gộp observations, dedup theo ID
      final seenIds = <int>{};
      final allObs = <Map<String, dynamic>>[];

      for (final res in responses) {
        if (res.statusCode != 200) continue;
        final data = jsonDecode(res.body);
        for (final o in (data['results'] as List? ?? [])) {
          final id = o['id'] as int?;
          if (id != null && seenIds.add(id)) allObs.add(o);
        }
      }

      // ── 3. Chấm điểm và lọc ─────────────────────────────────────────
      final candidates = <Map<String, dynamic>>[];

      for (final o in allObs) {
        if (o['spam'] == true) continue;

        final numIdAgree = (o['num_identification_agreements'] ?? 0) as int;
        final numIdDisagree = (o['num_identification_disagreements'] ?? 0) as int;
        final faves = (o['faves_count'] ?? 0) as int;

        // Bỏ nếu có nhiều người không đồng ý hơn đồng ý
        if (numIdDisagree > numIdAgree) continue;

        // Tính score: faves * 3 + agreements * 2
        final score = faves * 3 + numIdAgree * 2;

        final soundList = o['sounds'] as List? ?? [];
        for (final s in soundList) {
          final url = (s['file_url'] ?? s['file'] ?? '') as String;
          if (url.isEmpty) continue;

          // Lọc content type — nếu field không có thì vẫn chấp nhận
          final contentType = (s['file_content_type'] ?? '') as String;
          if (contentType.isNotEmpty &&
              !_validContentTypes.contains(contentType.toLowerCase())) {
            continue;
          }

          candidates.add({
            'url': url,
            'attribution': s['attribution'] ?? 'iNaturalist',
            'observer': o['user']?['login'] ?? 'Unknown',
            'place': o['place_guess'] ?? '',
            'faves': faves,
            'num_id': numIdAgree,
            'score': score,
          });
        }
      }

      // Sort theo score giảm dần, lấy top 5
      candidates.sort((a, b) =>
          (b['score'] as int).compareTo(a['score'] as int));
      final top = candidates.take(5).toList();

      // Nếu vẫn rỗng, fallback không filter (lấy thẳng 3 cái đầu)
      if (top.isEmpty) {
        for (final o in allObs.take(10)) {
          for (final s in (o['sounds'] as List? ?? [])) {
            final url = (s['file_url'] ?? s['file'] ?? '') as String;
            if (url.isNotEmpty) {
              top.add({
                'url': url,
                'attribution': s['attribution'] ?? 'iNaturalist',
                'observer': o['user']?['login'] ?? 'Unknown',
                'place': o['place_guess'] ?? '',
                'faves': o['faves_count'] ?? 0,
                'num_id': o['num_identification_agreements'] ?? 0,
                'score': 0,
              });
            }
            if (top.length >= 3) break;
          }
          if (top.length >= 3) break;
        }
      }

      // ── 4. Lưu cache ─────────────────────────────────────────────────
      await _cache.saveSounds(_animalId, top);

      setState(() {
        _sounds = top;
        _isLoading = false;
        _hasError = top.isEmpty;
      });
    } catch (e) {
      debugPrint('Sound fetch error: $e');
      setState(() { _isLoading = false; _hasError = true; });
    }
  }

  Future<void> _togglePlay() async {
    if (_sounds.isEmpty) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      try {
        final url = _sounds[_currentIndex]['url'] as String;
        debugPrint('🔊 Audio URL: $url');
        if (_player.audioSource == null) await _player.setUrl(url);
        await _player.play();
      } catch (e) {
        debugPrint('Audio play error: $e');
      }
    }
  }

  Future<void> _selectSound(int index) async {
    if (index == _currentIndex && _isPlaying) {
      await _player.pause();
      return;
    }
    await _player.stop();
    setState(() => _currentIndex = index);
    try {
      await _player.setUrl(_sounds[index]['url'] as String);
      await _player.play();
    } catch (e) {
      debugPrint('Audio select error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.volume_up_rounded, color: colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(t.tr('Âm thanh loài'),
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface)),
        ]),
        const SizedBox(height: 14),
        if (_isLoading)
          _buildLoadingState(colorScheme)
        else if (_hasError || _sounds.isEmpty)
          _buildEmptyState(colorScheme, t)
        else
          _buildSoundPlayer(colorScheme, t),
      ],
    );
  }

  Widget _buildLoadingState(ColorScheme cs) => Container(
    height: 90,
    decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16)),
    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );

  Widget _buildEmptyState(ColorScheme cs, LocaleProvider t) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      Icon(Icons.music_off_rounded, color: cs.onSurfaceVariant, size: 20),
      const SizedBox(width: 10),
      Text(t.tr('Chưa có âm thanh cho loài này'),
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
    ]),
  );

  Widget _buildSoundPlayer(ColorScheme cs, LocaleProvider t) {
    final current = _sounds[_currentIndex];
    final faves = current['faves'] as int? ?? 0;

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withOpacity(0.2), width: 1),
        ),
        child: Row(children: [
          GestureDetector(
            onTap: _togglePlay,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: cs.primary.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4))],
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: cs.onPrimary, size: 28,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('${t.tr('Ghi âm')} ${_currentIndex + 1}/${_sounds.length}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
                if (faves > 0) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.favorite, color: Colors.red.shade300, size: 12),
                  const SizedBox(width: 2),
                  Text('$faves', style: TextStyle(fontSize: 11, color: Colors.red.shade300)),
                ],
              ]),
              const SizedBox(height: 2),
              Text(current['observer'] as String,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if ((current['place'] as String).isNotEmpty)
                Text(current['place'] as String,
                    style: TextStyle(fontSize: 12,
                        color: cs.onSurfaceVariant.withOpacity(0.7)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
          Icon(Icons.graphic_eq_rounded,
              color: _isPlaying
                  ? cs.primary
                  : cs.onSurfaceVariant.withOpacity(0.4),
              size: 28),
        ]),
      ),

      if (_sounds.length > 1) ...[
        const SizedBox(height: 10),
        ...List.generate(_sounds.length, (i) {
          final isActive = i == _currentIndex;
          final itemFaves = _sounds[i]['faves'] as int? ?? 0;
          return GestureDetector(
            onTap: () => _selectSound(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? cs.primary.withOpacity(0.1)
                    : cs.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: isActive
                    ? Border.all(color: cs.primary.withOpacity(0.4), width: 1)
                    : null,
              ),
              child: Row(children: [
                Icon(
                  isActive && _isPlaying
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                  color: isActive ? cs.primary : cs.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  '${_sounds[i]['observer']} · ${_sounds[i]['place']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isActive ? cs.primary : cs.onSurfaceVariant,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                )),
                if (itemFaves > 0) ...[
                  Icon(Icons.favorite, color: Colors.red.shade300, size: 11),
                  const SizedBox(width: 3),
                  Text('$itemFaves',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ]),
            ),
          );
        }),
      ],

      const SizedBox(height: 6),
      Text('${t.tr('Nguồn:')} iNaturalist · ${current['attribution']}',
          style: TextStyle(
              fontSize: 11, color: cs.onSurfaceVariant.withOpacity(0.6))),
    ]);
  }
}