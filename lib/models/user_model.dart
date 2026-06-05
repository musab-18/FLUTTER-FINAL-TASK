class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String bio;
  final int postsCount;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.bio = '',
    this.postsCount = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Unknown User',
      photoURL: data['photoURL'],
      bio: data['bio'] ?? '',
      postsCount: data['postsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'bio': bio,
      'postsCount': postsCount,
    };
  }
}
