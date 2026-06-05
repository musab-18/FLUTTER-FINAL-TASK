import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorUsername;
  final String? authorPhotoUrl;
  final String content;
  final String? imageUrl;
  final int likesCount;
  final int commentsCount;
  final List<String> likedBy;
  final DateTime createdAt;

  const PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorUsername,
    this.authorPhotoUrl,
    required this.content,
    this.imageUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    required this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorUsername: data['authorUsername'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'],
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'authorId': authorId,
        'authorName': authorName,
        'authorUsername': authorUsername,
        'authorPhotoUrl': authorPhotoUrl,
        'content': content,
        'imageUrl': imageUrl,
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'likedBy': likedBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool isLikedBy(String uid) => likedBy.contains(uid);

  PostModel copyWith({
    int? likesCount,
    int? commentsCount,
    List<String>? likedBy,
  }) {
    return PostModel(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorUsername: authorUsername,
      authorPhotoUrl: authorPhotoUrl,
      content: content,
      imageUrl: imageUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      likedBy: likedBy ?? this.likedBy,
      createdAt: createdAt,
    );
  }
}
