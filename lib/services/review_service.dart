import '../models/review_model.dart';
import 'supabase_service.dart';
import 'auth_service.dart';
import 'achievements_service.dart';

class ReviewService {
  // Pre-defined review tags
  static const List<String> reviewTags = [
    'Staff',
    'Sample',
    'Swag',
    'Presentation',
    'Location',
    'Timing',
    'Product Quality',
    'Overall Experience',
  ];

  // Submit a review
  static Future<ReviewModel?> submitReview({
    required String eventId,
    required String brandId,
    required int rating,
    required List<String> tags,
    String? comment,
    int pointsReward = 10,
  }) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user already reviewed this event
      final existing = await SupabaseService.client
          .from('reviews')
          .select()
          .eq('user_id', user.id)
          .eq('event_id', eventId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('You have already reviewed this event');
      }

      // Create review
      final response = await SupabaseService.client
          .from('reviews')
          .insert({
            'user_id': user.id,
            'event_id': eventId,
            'brand_id': brandId,
            'rating': rating,
            'tags': tags,
            'comment': comment,
            'points_earned': pointsReward,
          })
          .select()
          .single();

      // Award points
      final currentUser = await SupabaseService.getUserProfile(user.id);
      if (currentUser != null) {
        final newPoints = currentUser.points + pointsReward;
        await SupabaseService.client
            .from('users')
            .update({'points': newPoints})
            .eq('id', user.id);

        // Reload user profile
        await AuthService().loadUserProfile();
        
        // Check and unlock achievements
        await AchievementsService.checkAndUnlockAchievements(user.id);
      }

      return ReviewModel.fromJson(response);
    } catch (e) {
      print('Error submitting review: $e');
      rethrow;
    }
  }

  // Get reviews for an event
  static Future<List<ReviewModel>> getEventReviews(String eventId) async {
    try {
      final response = await SupabaseService.client
          .from('reviews')
          .select('*, users(first_name, last_name, username)')
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      return response.map((item) => ReviewModel.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  // Get user's reviews
  static Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('reviews')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map((item) => ReviewModel.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching user reviews: $e');
      return [];
    }
  }
}

