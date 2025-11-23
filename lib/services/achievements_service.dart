import '../models/achievement_model.dart';
import '../models/user_achievement_model.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

class AchievementsService {
  // Get all achievements
  static Future<List<AchievementModel>> getAllAchievements() async {
    try {
      final response = await SupabaseService.client
          .from('achievements')
          .select()
          .order('points_reward', ascending: false);

      return response
          .map((item) => AchievementModel.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching achievements: $e');
      return [];
    }
  }

  // Get user's unlocked achievements
  static Future<List<UserAchievementModel>> getUserAchievements(
      String userId) async {
    try {
      final response = await SupabaseService.client
          .from('user_achievements')
          .select('*, achievements(*)')
          .eq('user_id', userId)
          .order('unlocked_at', ascending: false);

      return response
          .map((item) => UserAchievementModel.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching user achievements: $e');
      return [];
    }
  }

  // Check and unlock achievements based on user stats
  static Future<void> checkAndUnlockAchievements(String userId) async {
    try {
      // Get user stats
      final user = await SupabaseService.getUserProfile(userId);
      if (user == null) return;

      // Get check-ins count
      final checkInsResponse = await SupabaseService.client
          .from('check_ins')
          .select('id')
          .eq('user_id', userId);
      final checkInsCount = checkInsResponse.length;

      // Get reviews count
      final reviewsResponse = await SupabaseService.client
          .from('reviews')
          .select('id')
          .eq('user_id', userId);
      final reviewsCount = reviewsResponse.length;

      // Get all achievements
      final achievements = await getAllAchievements();

      // Check each achievement criteria
      for (var achievement in achievements) {
        // Check if already unlocked
        final existing = await SupabaseService.client
            .from('user_achievements')
            .select()
            .eq('user_id', userId)
            .eq('achievement_id', achievement.id)
            .maybeSingle();

        if (existing != null) continue; // Already unlocked

        // Parse criteria (e.g., "10 check-ins", "500 points")
        final criteria = achievement.criteria ?? '';
        bool shouldUnlock = false;

        if (criteria.contains('check-in')) {
          final match = RegExp(r'(\d+)').firstMatch(criteria);
          if (match != null) {
            final required = int.parse(match.group(1)!);
            shouldUnlock = checkInsCount >= required;
          }
        } else if (criteria.contains('review')) {
          final match = RegExp(r'(\d+)').firstMatch(criteria);
          if (match != null) {
            final required = int.parse(match.group(1)!);
            shouldUnlock = reviewsCount >= required;
          }
        } else if (criteria.contains('point')) {
          final match = RegExp(r'(\d+)').firstMatch(criteria);
          if (match != null) {
            final required = int.parse(match.group(1)!);
            shouldUnlock = user.points >= required;
          }
        }

        if (shouldUnlock) {
          // Unlock achievement
          await SupabaseService.client.from('user_achievements').insert({
            'user_id': userId,
            'achievement_id': achievement.id,
          });

          // Award points if specified
          if (achievement.pointsReward != null && achievement.pointsReward! > 0) {
            final newPoints = user.points + achievement.pointsReward!;
            await SupabaseService.client
                .from('users')
                .update({'points': newPoints})
                .eq('id', userId);
          }

          // Reload user profile
          await AuthService().loadUserProfile();
        }
      }
    } catch (e) {
      print('Error checking achievements: $e');
    }
  }

  // Get user progress stats
  static Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final checkInsResponse = await SupabaseService.client
          .from('check_ins')
          .select('id')
          .eq('user_id', userId);
      final checkInsCount = checkInsResponse.length;

      final reviewsResponse = await SupabaseService.client
          .from('reviews')
          .select('id')
          .eq('user_id', userId);
      final reviewsCount = reviewsResponse.length;

      final achievementsResponse = await SupabaseService.client
          .from('user_achievements')
          .select('id')
          .eq('user_id', userId);
      final achievementsCount = achievementsResponse.length;

      return {
        'checkIns': checkInsCount,
        'reviews': reviewsCount,
        'achievements': achievementsCount,
      };
    } catch (e) {
      print('Error fetching user stats: $e');
      return {'checkIns': 0, 'reviews': 0, 'achievements': 0};
    }
  }
}

