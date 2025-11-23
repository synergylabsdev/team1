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

      if (response.user != null) {
        await loadUserProfile();
        return _currentUser;
      }
      return null;
    } catch (e) {
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
        await loadUserProfile();
        return _currentUser;
      }
      return null;
    } catch (e) {
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
