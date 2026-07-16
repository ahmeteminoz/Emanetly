class UserReview {
  final String authorName;
  final String rating;
  final String comment;
  final String dateText;

  UserReview({
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.dateText,
  });

  Map<String, dynamic> toMap() {
    return {
      'authorName': authorName,
      'rating': rating,
      'comment': comment,
      'dateText': dateText,
    };
  }

  factory UserReview.fromMap(Map<String, dynamic> map) {
    return UserReview(
      authorName: map['authorName'] ?? '',
      rating: map['rating'] ?? '',
      comment: map['comment'] ?? '',
      dateText: map['dateText'] ?? '',
    );
  }
}

class UserProfile {
  final String uid;
  final String name;
  final String username;
  final String studentId;
  final String email;
  final String department;
  final String? avatarUrl;
  final String bio;
  
  // Extended Trust Dashboard metrics
  final int trustScore;
  final double averageRating;
  final int reviewCount;
  final int successfulBorrows;
  final int successfulLends;
  final double onTimeReturnRate;
  final String avgResponseTime;
  final int lateReturnsCount;
  final List<String> verificationBadges;
  final List<String> userBadges;
  final List<UserReview> reviews;
  final List<String> favoriteItemIds;

  UserProfile({
    required this.uid,
    required this.name,
    required this.username,
    required this.studentId,
    required this.email,
    required this.department,
    this.avatarUrl,
    required this.bio,
    required this.trustScore,
    required this.averageRating,
    required this.reviewCount,
    required this.successfulBorrows,
    required this.successfulLends,
    required this.onTimeReturnRate,
    required this.avgResponseTime,
    required this.lateReturnsCount,
    required this.verificationBadges,
    required this.userBadges,
    required this.reviews,
    this.favoriteItemIds = const [],
  });

  UserProfile copyWith({
    String? uid,
    String? name,
    String? username,
    String? studentId,
    String? email,
    String? department,
    String? avatarUrl,
    String? bio,
    int? trustScore,
    double? averageRating,
    int? reviewCount,
    int? successfulBorrows,
    int? successfulLends,
    double? onTimeReturnRate,
    String? avgResponseTime,
    int? lateReturnsCount,
    List<String>? verificationBadges,
    List<String>? userBadges,
    List<UserReview>? reviews,
    List<String>? favoriteItemIds,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      username: username ?? this.username,
      studentId: studentId ?? this.studentId,
      email: email ?? this.email,
      department: department ?? this.department,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      trustScore: trustScore ?? this.trustScore,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      successfulBorrows: successfulBorrows ?? this.successfulBorrows,
      successfulLends: successfulLends ?? this.successfulLends,
      onTimeReturnRate: onTimeReturnRate ?? this.onTimeReturnRate,
      avgResponseTime: avgResponseTime ?? this.avgResponseTime,
      lateReturnsCount: lateReturnsCount ?? this.lateReturnsCount,
      verificationBadges: verificationBadges ?? this.verificationBadges,
      userBadges: userBadges ?? this.userBadges,
      reviews: reviews ?? this.reviews,
      favoriteItemIds: favoriteItemIds ?? this.favoriteItemIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'username': username,
      'studentId': studentId,
      'email': email,
      'department': department,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'trustScore': trustScore,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'successfulBorrows': successfulBorrows,
      'successfulLends': successfulLends,
      'onTimeReturnRate': onTimeReturnRate,
      'avgResponseTime': avgResponseTime,
      'lateReturnsCount': lateReturnsCount,
      'verificationBadges': verificationBadges,
      'userBadges': userBadges,
      'reviews': reviews.map((r) => r.toMap()).toList(),
      'favoriteItemIds': favoriteItemIds,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      studentId: map['studentId'] ?? '',
      email: map['email'] ?? '',
      department: map['department'] ?? '',
      avatarUrl: map['avatarUrl'],
      bio: map['bio'] ?? '',
      trustScore: map['trustScore'] ?? 100,
      averageRating: (map['averageRating'] ?? 5.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      successfulBorrows: map['successfulBorrows'] ?? 0,
      successfulLends: map['successfulLends'] ?? 0,
      onTimeReturnRate: (map['onTimeReturnRate'] ?? 100.0).toDouble(),
      avgResponseTime: map['avgResponseTime'] ?? '',
      lateReturnsCount: map['lateReturnsCount'] ?? 0,
      verificationBadges: List<String>.from(map['verificationBadges'] ?? []),
      userBadges: List<String>.from(map['userBadges'] ?? []),
      reviews: (map['reviews'] as List<dynamic>?)
              ?.map((x) => UserReview.fromMap(x as Map<String, dynamic>))
              .toList() ??
          [],
      favoriteItemIds: List<String>.from(map['favoriteItemIds'] ?? []),
    );
  }
}
