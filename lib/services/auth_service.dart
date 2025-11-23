import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  bool _isOnboardingCompleted = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isOnboardingCompleted => _isOnboardingCompleted;

  Future<void> initialize() async {
    await _loadOnboardingStatus();
    if (SupabaseService.isAuthenticated) {
      await loadUserProfile();
    }
  }

  Future<void> _loadOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isOnboardingCompleted =
        prefs.getBool(AppConstants.keyOnboardingCompleted) ?? false;
  }

  Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingCompleted, true);
    _isOnboardingCompleted = true;
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    try {
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        username: username,
      );

      // With auto-confirmation enabled, user is immediately confirmed and session is available
      if (response.user != null) {
        // Wait a bit for the profile insert to complete
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Try to load the profile, with retries
        int retries = 3;
        while (retries > 0 && _currentUser == null) {
          await loadUserProfile();
          if (_currentUser != null) {
            break;
          }
          await Future.delayed(const Duration(milliseconds: 300));
          retries--;
        }
        
        print('SignUp completed. User ID: ${response.user!.id}, Session: ${response.session != null}, Profile loaded: ${_currentUser != null}');
      }
      
      // Return the loaded user if available
      return _currentUser;
    } catch (e) {
      print('SignUp error: $e');
      rethrow;
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Check if user is confirmed
        if (response.user!.emailConfirmedAt == null && 
            response.user!.confirmedAt == null) {
          print('Warning: User email not confirmed');
          // Even if not confirmed, try to load profile if session exists
        }
        
        // Load user profile
        await loadUserProfile();
        
        // If profile doesn't exist but user is authenticated, create it
        if (_currentUser == null && response.session != null) {
          print('User authenticated but profile not found. Creating profile for User ID: ${response.user!.id}');
          
          // Get user metadata from auth
          final userMetadata = response.user!.userMetadata;
          final firstName = userMetadata?['first_name'] as String? ?? '';
          final lastName = userMetadata?['last_name'] as String? ?? '';
          final username = userMetadata?['username'] as String? ?? email.split('@')[0];
          
          // Create user profile in users table
          try {
            await SupabaseService.client.from('users').insert({
              'id': response.user!.id,
              'first_name': firstName,
              'last_name': lastName,
              'username': username,
              'email': email,
              'points': 0,
              'tier_status': 'Bronze',
            });
            
            // Reload profile after creation
            await loadUserProfile();
            print('User profile created successfully');
          } catch (e) {
            print('Error creating user profile during sign in: $e');
            // If insert fails (e.g., user already exists), try to load again
            await loadUserProfile();
          }
        }
        
        return _currentUser;
      }
      return null;
    } catch (e) {
      print('SignIn error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
    _currentUser = null;
  }

  Future<void> resetPassword(String email) async {
    await SupabaseService.resetPassword(email);
  }

  Future<void> loadUserProfile() async {
    final user = SupabaseService.currentUser;
    if (user != null) {
      _currentUser = await SupabaseService.getUserProfile(user.id);
      if (_currentUser == null) {
        print('Warning: User profile not found for user ID: ${user.id}');
      }
    }
  }

  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? phone,
    DateTime? dob,
    String? profilePicture,
  }) async {
    final authUser = SupabaseService.currentUser;
    if (authUser == null) {
      throw Exception('User not authenticated');
    }

    // First, ensure user exists in users table
    if (_currentUser == null) {
      // Try to load profile first
      await loadUserProfile();
      
      // If still null, create the user profile
      if (_currentUser == null) {
        final userMetadata = authUser.userMetadata;
        final existingFirstName = firstName ?? userMetadata?['first_name'] as String? ?? '';
        final existingLastName = lastName ?? userMetadata?['last_name'] as String? ?? '';
        final existingUsername = username ?? userMetadata?['username'] as String? ?? authUser.email?.split('@')[0] ?? '';
        
        try {
          await SupabaseService.client.from('users').insert({
            'id': authUser.id,
            'first_name': existingFirstName,
            'last_name': existingLastName,
            'username': existingUsername,
            'email': authUser.email ?? '',
            'points': 0,
            'tier_status': 'Bronze',
          });
          
          // Reload profile after creation
          await loadUserProfile();
          print('User profile created during update');
        } catch (e) {
          print('Error creating user profile during update: $e');
          // If insert fails, try to load again (might have been created by another process)
          await loadUserProfile();
        }
      }
    }

    // Now update the profile
    if (_currentUser != null) {
      _currentUser = await SupabaseService.updateUserProfile(
        userId: _currentUser!.id,
        firstName: firstName,
        lastName: lastName,
        username: username,
        phone: phone,
        dob: dob,
        profilePicture: profilePicture,
      );
    } else {
      // If we still don't have a current user, try to update directly using auth user ID
      _currentUser = await SupabaseService.updateUserProfile(
        userId: authUser.id,
        firstName: firstName,
        lastName: lastName,
        username: username,
        phone: phone,
        dob: dob,
        profilePicture: profilePicture,
      );
    }
  }
}
