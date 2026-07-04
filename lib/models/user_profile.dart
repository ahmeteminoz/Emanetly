class UserProfile {
  final String uid;
  final String name;
  final String studentId;
  final String email;
  final String department;
  final String? avatarUrl;

  UserProfile({
    required this.uid,
    required this.name,
    required this.studentId,
    required this.email,
    required this.department,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'studentId': studentId,
      'email': email,
      'department': department,
      'avatarUrl': avatarUrl,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      studentId: map['studentId'] ?? '',
      email: map['email'] ?? '',
      department: map['department'] ?? '',
      avatarUrl: map['avatarUrl'],
    );
  }
}
