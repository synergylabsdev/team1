import '../models/check_in_model.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

class CheckInService {
  // Check in to an event
  static Future<CheckInModel?> checkIn({
    required String eventId,
    String? barcodeUsed,
    int pointsEarned = 10, // Default points
  }) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user already checked in
      final existingCheckIn = await SupabaseService.client
          .from('check_ins')
          .select()
          .eq('user_id', user.id)
          .eq('event_id', eventId)
          .maybeSingle();

      if (existingCheckIn != null) {
        throw Exception('You have already checked in to this event');
      }

      // Create check-in
      final response = await SupabaseService.client
          .from('check_ins')
          .insert({
            'user_id': user.id,
            'event_id': eventId,
            'points_earned': pointsEarned,
            'barcode_used': barcodeUsed,
          })
          .select()
          .single();

      // Update user points
      final currentUser = AuthService().currentUser;
      if (currentUser != null) {
        final newPoints = currentUser.points + pointsEarned;
        await SupabaseService.client
            .from('users')
            .update({'points': newPoints})
            .eq('id', user.id);

        // Reload user profile
        await AuthService().loadUserProfile();
      }

      return CheckInModel.fromJson(response);
    } catch (e) {
      print('Error checking in: $e');
      rethrow;
    }
  }

  // Get user's check-ins
  static Future<List<CheckInModel>> getUserCheckIns(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('check_ins')
          .select()
          .eq('user_id', userId)
          .order('check_in_time', ascending: false);

      return response.map((item) => CheckInModel.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching check-ins: $e');
      return [];
    }
  }

  // Check if user has checked in to event
  static Future<bool> hasCheckedIn(String userId, String eventId) async {
    try {
      final response = await SupabaseService.client
          .from('check_ins')
          .select()
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}

