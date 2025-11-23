import '../models/favorite_model.dart';
import 'supabase_service.dart';

class FavoriteService {
  // Add brand to favorites
  static Future<FavoriteModel?> addFavorite(String brandId) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if already favorited
      final existing = await SupabaseService.client
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .eq('brand_id', brandId)
          .maybeSingle();

      if (existing != null) {
        return FavoriteModel.fromJson(existing);
      }

      final response = await SupabaseService.client
          .from('favorites')
          .insert({
            'user_id': user.id,
            'brand_id': brandId,
          })
          .select()
          .single();

      return FavoriteModel.fromJson(response);
    } catch (e) {
      print('Error adding favorite: $e');
      rethrow;
    }
  }

  // Remove brand from favorites
  static Future<void> removeFavorite(String brandId) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await SupabaseService.client
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('brand_id', brandId);
    } catch (e) {
      print('Error removing favorite: $e');
      rethrow;
    }
  }

  // Check if brand is favorited
  static Future<bool> isFavorited(String brandId) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        return false;
      }

      final response = await SupabaseService.client
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .eq('brand_id', brandId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Get user's favorite brands
  static Future<List<String>> getUserFavorites() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        return [];
      }

      final response = await SupabaseService.client
          .from('favorites')
          .select('brand_id')
          .eq('user_id', user.id);

      return response.map((item) => item['brand_id'] as String).toList();
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }
}

