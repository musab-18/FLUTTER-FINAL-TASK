class AppConstants {
  // App Info
  static const String appName = 'Social Connect';
  static const String appVersion = '1.0.0';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String notificationsCollection = 'notifications';
  static const String likesCollection = 'likes';

  // Storage Paths
  static const String profilePicsPath = 'profile_pictures';
  static const String postImagesPath = 'post_images';

  // Pagination
  static const int postsPerPage = 10;
  static const int commentsPerPage = 20;

  // Validation
  static const int maxBioLength = 150;
  static const int maxPostLength = 500;
  static const int minPasswordLength = 6;
  static const int maxUsernameLength = 30;

  // Durations
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
}
