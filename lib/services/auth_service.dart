import 'dart:async';
import '../models/user_profile.dart';

abstract class AuthService {
  UserProfile? get currentUser;
  Future<UserProfile?> signIn(String email, String password);
  Future<void> signOut();
  Stream<UserProfile?> get onAuthStateChanged;
}

class MockAuthService implements AuthService {
  final _controller = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;

  // Pre-configured mock students
  final List<UserProfile> _mockUsers = [
    UserProfile(
      uid: 'user_1',
      name: 'Ahmet Öz',
      studentId: '20220101001',
      email: 'ahmet@kampus.edu.tr',
      department: 'Bilgisayar Mühendisliği',
    ),
    UserProfile(
      uid: 'user_2',
      name: 'Ayşe Yılmaz',
      studentId: '20230202042',
      email: 'ayse@kampus.edu.tr',
      department: 'Endüstri Tasarımı',
    ),
    UserProfile(
      uid: 'user_3',
      name: 'Can Demir',
      studentId: '20210303077',
      email: 'can@kampus.edu.tr',
      department: 'Fizik Bölümü',
    ),
  ];

  MockAuthService() {
    // Start with Ahmet logged in as default
    _currentUser = _mockUsers[0];
    _controller.add(_currentUser);
  }

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Future<UserProfile?> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate network latency
    final matched = _mockUsers.firstWhere(
      (user) => user.email.toLowerCase() == email.trim().toLowerCase(),
      orElse: () => throw Exception('Kullanıcı bulunamadı.'),
    );
    _currentUser = matched;
    _controller.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Stream<UserProfile?> get onAuthStateChanged => _controller.stream;

  // Helper method for the prototype to swap users easily
  void switchUser(String uid) {
    final user = _mockUsers.firstWhere((u) => u.uid == uid, orElse: () => _mockUsers[0]);
    _currentUser = user;
    _controller.add(_currentUser);
  }

  List<UserProfile> get availableMockUsers => _mockUsers;
}
