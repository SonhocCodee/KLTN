import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Auth/auth_service.dart';

class FavoriteService {
  final _supabase = Supabase.instance.client;

  String? get _userId => AuthService.isGuest ? null : _supabase.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final uid = _userId;
    if (uid == null) {
      debugPrint('[FavoriteService] getFavorites: chưa đăng nhập');
      return [];
    }
    try {
      final res = await _supabase
          .from('favorite_animals')
          .select('animal_id, created_at')
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      debugPrint('[FavoriteService] getFavorites uid=$uid → ${res.length} rows: $res');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('[FavoriteService] getFavorites ERROR: $e');
      return [];
    }
  }

  Future<Set<String>> getFavoriteIds() async {
    final list = await getFavorites();
    return {for (final row in list) row['animal_id'] as String};
  }

  Future<bool> isFavorite(String animalId) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final res = await _supabase
          .from('favorite_animals')
          .select('id')
          .eq('user_id', uid)
          .eq('animal_id', animalId)
          .maybeSingle();
      debugPrint('[FavoriteService] isFavorite($animalId) → ${res != null}');
      return res != null;
    } catch (e) {
      debugPrint('[FavoriteService] isFavorite ERROR: $e');
      return false;
    }
  }

  Future<bool> addFavorite(String animalId) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final inserted = await _supabase
          .from('favorite_animals')
          .insert({'user_id': uid, 'animal_id': animalId})
          .select();
      debugPrint('[FavoriteService] addFavorite($animalId) → inserted: $inserted');
      return true;
    } catch (e) {
      debugPrint('[FavoriteService] addFavorite ERROR: $e');
      return false;
    }
  }

  Future<bool> removeFavorite(String animalId) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      await _supabase
          .from('favorite_animals')
          .delete()
          .eq('user_id', uid)
          .eq('animal_id', animalId);
      debugPrint('[FavoriteService] removeFavorite($animalId) ✓');
      return true;
    } catch (e) {
      debugPrint('[FavoriteService] removeFavorite ERROR: $e');
      return false;
    }
  }

  Future<bool> toggleFavorite(String animalId) async {
    final already = await isFavorite(animalId);
    if (already) {
      await removeFavorite(animalId);
      return false;
    } else {
      await addFavorite(animalId);
      return true;
    }
  }
}