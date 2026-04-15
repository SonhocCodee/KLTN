import 'package:supabase_flutter/supabase_flutter.dart';

class AnimalSuggestion {
  final String id;
  final String nameVi;
  final String nameEn;
  final String animalType;
  final String? imageUrl;

  AnimalSuggestion({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.animalType,
    this.imageUrl,
  });

  factory AnimalSuggestion.fromMap(Map<String, dynamic> map) {
    return AnimalSuggestion(
      id: map['id'] ?? '',
      nameVi: map['name_vietnamese'] ?? '',
      nameEn: map['name_english'] ?? '',
      animalType: map['animal_type'] ?? '',
      imageUrl: map['image_url'],
    );
  }

  String get typeEmoji {
    switch (animalType.toLowerCase()) {
      case 'cat': return '🐱';
      case 'dog': return '🐶';
      case 'bird': return '🦜';
      case 'fish': return '🐟';
      case 'buffalo': return '🐃';
      case 'cattle': return '🐄';
      case 'horse': return '🐴';
      case 'bear': return '🐻';
      case 'lion': return '🦁';
      default: return '🐾';
    }
  }

  String get typeLabel {
    switch (animalType.toLowerCase()) {
      case 'cat': return 'Mèo';
      case 'dog': return 'Chó';
      case 'bird': return 'Chim';
      case 'fish': return 'Cá';
      case 'buffalo': return 'Trâu';
      case 'cattle': return 'Bò';
      case 'horse': return 'Ngựa';
      case 'bear': return 'Gấu';
      case 'lion': return 'Sư tử';
      default: return animalType;
    }
  }
}

class AnimalSearchService {
  final _client = Supabase.instance.client;

  Future<List<AnimalSuggestion>> search(String query) async {
    if (query.trim().length < 2) return [];

    final q = query.trim();

    try {
      final data = await _client
          .from('animals')
          .select('id, name_vietnamese, name_english, animal_type, image_url')
          .or('name_vietnamese.ilike.%$q%,name_english.ilike.%$q%')
          .order('name_vietnamese')
          .limit(8);

      final results = (data as List)
          .map((e) => AnimalSuggestion.fromMap(e as Map<String, dynamic>))
          .toList();

      final qLower = q.toLowerCase();
      results.sort((a, b) {
        final aScore = a.nameVi.toLowerCase().startsWith(qLower) ? 0
            : a.nameEn.toLowerCase().startsWith(qLower) ? 1 : 2;
        final bScore = b.nameVi.toLowerCase().startsWith(qLower) ? 0
            : b.nameEn.toLowerCase().startsWith(qLower) ? 1 : 2;
        if (aScore != bScore) return aScore - bScore;
        return a.nameVi.compareTo(b.nameVi);
      });

      return results;
    } catch (_) {
      return [];
    }
  }
}