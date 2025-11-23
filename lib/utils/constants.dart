class AppConstants {
  // App Info
  static const String appName = 'SampleFinder';
  
  // Supabase Configuration (to be set in environment or config)
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // Shared Preferences Keys
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyUserSession = 'user_session';
  
  // Validation
  static const int minPasswordLength = 8;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  
  // Points & Tiers
  static const Map<String, int> tierPointsThreshold = {
    'Bronze': 0,
    'Silver': 100,
    'Gold': 500,
    'Platinum': 1000,
  };
  
  // Rating
  static const int minRating = 1;
  static const int maxRating = 5;
}

