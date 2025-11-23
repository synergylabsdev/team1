class AppConstants {
  // App Info
  static const String appName = 'SampleFinder';

  // Supabase Configuration (to be set in environment or config)
  static const String supabaseUrl = 'https://dplndpkjeqnmnwtrpprg.supabase.co';
  static const String supabaseAnonKey =
      'sb_secret_dQDrD6q0lfP3i0srFVOdAQ_tw7XMFjR';
  
  // Deep Link Configuration
  static const String deepLinkScheme = 'samplefinder';
  static const String redirectUrl = 'samplefinder://auth-callback';

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
