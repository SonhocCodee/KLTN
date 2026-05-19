import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../language/Locale_provider.dart';
import 'animal_api_cache_service.dart';

class AnimalDistributionMap extends StatefulWidget {
  final Map<String, dynamic> animal;

  const AnimalDistributionMap({super.key, required this.animal});

  @override
  State<AnimalDistributionMap> createState() => _AnimalDistributionMapState();
}

class _AnimalDistributionMapState extends State<AnimalDistributionMap> {
  final _cache = AnimalApiCacheService.instance;

  List<LatLng> _points = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _totalCount = 0;

  String get _animalId => widget.animal['id']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _fetchDistribution();
  }

  Future<void> _fetchDistribution() async {
    final cached = await _cache.getMap(_animalId);
    if (cached != null) {
      setState(() {
        _points = cached.points.map((p) => LatLng(p['lat']!, p['lng']!)).toList();
        _totalCount = cached.count;
        _isLoading = false;
        _hasError = cached.points.isEmpty;
      });
      return;
    }

    final scientificName = widget.animal['scientific_name'] ?? widget.animal['name'] ?? '';
    if (scientificName.isEmpty) {
      setState(() { _isLoading = false; _hasError = true; });
      return;
    }

    try {
      final matchRes = await http.get(Uri.parse('https://api.gbif.org/v1/species/match?name=${Uri.encodeComponent(scientificName)}&verbose=false'));
      if (matchRes.statusCode != 200) throw Exception('GBIF match failed');

      final matchData = jsonDecode(matchRes.body);
      final taxonKey = matchData['usageKey'] ?? matchData['speciesKey'];
      if (taxonKey == null) throw Exception('No taxon key');

      final countRes = await http.get(Uri.parse('https://api.gbif.org/v1/occurrence/search?taxonKey=$taxonKey&limit=0&hasCoordinate=true'));
      final countData = jsonDecode(countRes.body);
      final count = countData['count'] ?? 0;

      final occRes = await http.get(Uri.parse('https://api.gbif.org/v1/occurrence/search?taxonKey=$taxonKey&hasCoordinate=true&limit=300'));
      if (occRes.statusCode != 200) throw Exception('GBIF occurrence failed');

      final occData = jsonDecode(occRes.body);
      final results = occData['results'] as List? ?? [];

      final points = <LatLng>[];
      final cachePoints = <Map<String, double>>[];

      for (final r in results) {
        final lat = r['decimalLatitude'];
        final lng = r['decimalLongitude'];
        if (lat != null && lng != null) {
          points.add(LatLng(lat.toDouble(), lng.toDouble()));
          cachePoints.add({'lat': lat.toDouble(), 'lng': lng.toDouble()});
        }
      }

      await _cache.saveMap(_animalId, cachePoints, count);

      setState(() {
        _points = points;
        _totalCount = count;
        _isLoading = false;
        _hasError = points.isEmpty;
      });
    } catch (e) {
      setState(() { _isLoading = false; _hasError = true; });
    }
  }

  LatLng _computeCenter() {
    if (_points.isEmpty) return const LatLng(20, 0);
    double latSum = 0, lngSum = 0;
    for (final p in _points) { latSum += p.latitude; lngSum += p.longitude; }
    return LatLng(latSum / _points.length, lngSum / _points.length);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = context.watch<LocaleProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.map_rounded, color: colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(t.tr('Phân bố địa lý'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
          if (_totalCount > 0) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: colorScheme.primaryContainer.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
              child: Text('${_formatCount(_totalCount)} ${t.tr('ghi nhận')}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.primary)),
            ),
          ],
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildContent(colorScheme, t),
        ),
        if (!_isLoading && !_hasError && _points.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.7), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('${t.tr('Hiển thị')} ${_points.length} ${t.tr('điểm')} · ${t.tr('Nguồn:')} GBIF', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant.withOpacity(0.7))),
          ]),
        ],
      ],
    );
  }

  Widget _buildContent(ColorScheme cs, LocaleProvider t) {
    if (_isLoading) {
      return Container(
        height: 220,
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_hasError || _points.isEmpty) {
      return Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cs.surfaceContainerHighest.withOpacity(0.4), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(Icons.location_off_rounded, color: cs.onSurfaceVariant, size: 20),
          const SizedBox(width: 10),
          Text(t.tr('Không có dữ liệu phân bố'), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
        ]),
      );
    }

    return SizedBox(
      height: 280,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: _computeCenter(),
          initialZoom: 2.5,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.doubleTapZoom),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.example.kltn_app',
          ),
          CircleLayer(
            circles: _points.map((p) => CircleMarker(
              point: p,
              radius: 4,
              color: cs.primary.withOpacity(0.55),
              borderColor: cs.primary.withOpacity(0.85),
              borderStrokeWidth: 1,
              useRadiusInMeter: false,
            )).toList(),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}K';
    return count.toString();
  }
}