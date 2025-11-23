import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import '../models/user_model.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return _client!;
  }

  // Authentication Methods
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
      },
    );

    if (response.user != null) {
      try {
        // Create user profile in users table
        await client.from('users').insert({
          'id': response.user!.id,
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
          'email': email,
          'points': 0,
          'tier_status': 'Bronze',
        });
      } catch (e) {
        // If profile creation fails, log but don't fail the signup
        // The user is already created in auth, profile can be created later
        print('Error creating user profile: $e');
        rethrow;
      }
    }

    return response;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  static User? get currentUser => client.auth.currentUser;

  static bool get isAuthenticated => currentUser != null;

  // User Profile Methods
  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error loading user profile for $userId: $e');
      return null;
    }
  }

  static Future<UserModel?> updateUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? username,
    String? phone,
    DateTime? dob,
    String? profilePicture,
  }) async {
    final updateData = <String, dynamic>{};
    if (firstName != null) updateData['first_name'] = firstName;
    if (lastName != null) updateData['last_name'] = lastName;
    if (username != null) updateData['username'] = username;
    if (phone != null) updateData['phone'] = phone;
    if (dob != null) updateData['dob'] = dob.toIso8601String();
    if (profilePicture != null) updateData['profile_picture'] = profilePicture;
    updateData['updated_at'] = DateTime.now().toIso8601String();

    final response = await client
        .from('users')
        .update(updateData)
        .eq('id', userId)
        .select()
        .single();

    return UserModel.fromJson(response);
  }
}
