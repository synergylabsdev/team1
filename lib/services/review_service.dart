import '../models/review_model.dart';
import '../models/tag_model.dart';
import 'supabase_service.dart';
import 'auth_service.dart';
import 'achievements_service.dart';

class ReviewService {
  // Get all available tags from database
  static Future<List<TagModel>> getAllTags() async {
    try {
      final response = await SupabaseService.client
          .from('tags')
          .select('*')
          .order('name', ascending: true);

      return response.map((item) => TagModel.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching tags: $e');
      return [];
    }
  }

  // Get tag IDs from tag names
  static Future<List<String>> getTagIdsFromNames(List<String> tagNames) async {
    try {
      final tags = await getAllTags();
      final tagMap = {for (var tag in tags) tag.name: tag.id};
      return tagNames
          .map((name) => tagMap[name])
          .where((id) => id != null)
          .cast<String>()
          .toList();
    } catch (e) {
      print('Error getting tag IDs: $e');
      return [];
    }
  }

  // Submit a review
  static Future<ReviewModel?> submitReview({
    required String eventId,
    required String brandId,
    required int rating,
    required List<String> tagNames, // Changed from tags to tagNames
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

      // Get tag IDs from tag names
      final tagIds = await getTagIdsFromNames(tagNames);
      if (tagIds.isEmpty && tagNames.isNotEmpty) {
        throw Exception('Invalid tags selected');
      }

      // Create review (without tags column)
      final response = await SupabaseService.client
          .from('reviews')
          .insert({
            'user_id': user.id,
            'event_id': eventId,
            'brand_id': brandId,
            'rating': rating,
            'comment': comment,
            'points_earned': pointsReward,
          })
          .select()
          .single();

      final reviewId = response['id'] as String;

      // Create review_tags entries
      if (tagIds.isNotEmpty) {
        final reviewTagsData = tagIds.map((tagId) => {
          'review_id': reviewId,
          'tags_id': tagId,
        }).toList();

        await SupabaseService.client
            .from('review_tags')
            .insert(reviewTagsData);
      }

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

  // Get reviews for an event with tags
  static Future<List<ReviewModel>> getEventReviews(String eventId) async {
    try {
      final response = await SupabaseService.client
          .from('reviews')
          .select('*, users(first_name, last_name, username), review_tags(tags(*))')
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      return response.map((item) => _parseReviewWithTags(item)).toList();
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  // Get user's reviews with tags
  static Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('reviews')
          .select('*, review_tags(tags(*))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map((item) => _parseReviewWithTags(item)).toList();
    } catch (e) {
      print('Error fetching user reviews: $e');
      return [];
    }
  }

  // Parse review JSON with tags from join
  static ReviewModel _parseReviewWithTags(Map<String, dynamic> json) {
    // Extract tags from review_tags join
    List<String> tagNames = [];
    if (json['review_tags'] != null) {
      final reviewTags = json['review_tags'] as List;
      for (var rt in reviewTags) {
        if (rt['tags'] != null && rt['tags']['name'] != null) {
          tagNames.add(rt['tags']['name'] as String);
        }
      }
    }

    // Remove the joined data from json before parsing
    final reviewJson = Map<String, dynamic>.from(json);
    reviewJson.remove('review_tags');
    reviewJson['tags'] = tagNames; // Add tags as array for model compatibility

    return ReviewModel.fromJson(reviewJson);
  }
}

