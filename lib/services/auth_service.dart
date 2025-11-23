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
        
        // If profile doesn't exist but user is authenticated, that's okay
        // We can still return success - profile might be created later
        if (_currentUser == null && response.session != null) {
          print('User authenticated but profile not found. User ID: ${response.user!.id}');
          // User is authenticated, profile might be missing - this is okay for now
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
    }
  }
}
