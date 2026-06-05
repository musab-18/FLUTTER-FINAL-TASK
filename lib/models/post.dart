class Post {
  final String id;
  final String userId;
  final String userDisplayName;
  final String? userPhotoURL;
  final String content;
  final String? imageURL;
  final int likesCount;
  final int commentsCount;
  final int createdAt;
  bool isLiked; // UI state

  Post({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    this.userPhotoURL,
    required this.content,
    this.imageURL,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    this.isLiked = false,
  });

  factory Post.fromMap(Map<String, dynamic> data, String id) {
    return Post(
      id: id,
      userId: data['userId'] ?? '',
      userDisplayName: data['userDisplayName'] ?? '',
      userPhotoURL: data['userPhotoURL'],
      content: data['content'] ?? '',
      imageURL: data['imageURL'],
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      createdAt: data['createdAt'] ?? 0,
      isLiked: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userPhotoURL': userPhotoURL,
      'content': content,
      'imageURL': imageURL,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'createdAt': createdAt,
    };
  }
}
