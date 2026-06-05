import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String username;
  final String bio;
  final String? photoUrl;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final DateTime createdAt;
  final String? fcmToken;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.username,
    required this.bio,
    this.photoUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    required this.createdAt,
    this.fcmToken,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      username: data['username'] ?? '',
      bio: data['bio'] ?? '',
      photoUrl: data['photoUrl'],
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      postsCount: data['postsCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken: data['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'username': username,
        'bio': bio,
        'photoUrl': photoUrl,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'postsCount': postsCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'fcmToken': fcmToken,
      };

  UserModel copyWith({
    String? displayName,
    String? username,
    String? bio,
    String? photoUrl,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      createdAt: createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
