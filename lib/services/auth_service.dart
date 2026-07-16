import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

abstract class AuthService {
  UserProfile? get currentUser;
  Future<UserProfile?> signIn(String email, String password);
  Future<UserProfile?> signUp(String email, String password, String name);
  Future<void> signOut();
  Stream<UserProfile?> get onAuthStateChanged;

  // Firebase Auth additions
  Future<void> sendEmailVerification();
  bool get isEmailVerified;
  Future<void> reloadUser();
  Future<void> sendPasswordResetEmail(String email);

  // Unified mock management
  List<UserProfile> get availableMockUsers;
  void addReviewToUser(String targetUserId, UserReview review);
  Future<UserProfile?> getUserProfile(String uid);
}

class MockAuthService implements AuthService {
  final _controller = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;

  // Pre-configured mock students with extended trust data
  final List<UserProfile> _mockUsers = [
    UserProfile(
      uid: 'user_1',
      name: 'Ahmet Öz',
      username: '@ahmetoz',
      studentId: '20220101001',
      email: 'ahmet@kampus.edu.tr',
      department: 'Bilgisayar Mühendisliği',
      bio: 'Bilgisayar Mühendisliği 3. sınıf öğrencisi. Kampüste yardımlaşmayı ve sürdürülebilirliği destekliyorum.',
      trustScore: 94,
      averageRating: 4.8,
      reviewCount: 12,
      successfulBorrows: 8,
      successfulLends: 5,
      onTimeReturnRate: 100.0,
      avgResponseTime: '12 dk',
      lateReturnsCount: 0,
      verificationBadges: ['E-posta doğrulandı', 'Telefon doğrulandı', 'Öğrenci profili'],
      userBadges: ['Güvenilir ödünç veren', 'Zamanında iade', 'Hızlı yanıt'],
      reviews: [
        UserReview(
          authorName: 'Ayşe Yılmaz',
          rating: '5.0',
          comment: 'HDMI dönüştürücüyü zamanında ve sorunsuz teslim etti.',
          dateText: '2 gün önce',
        ),
        UserReview(
          authorName: 'Can Demir',
          rating: '4.8',
          comment: 'İletişimi hızlıydı, buluşma noktasına zamanında geldi.',
          dateText: '1 hafta önce',
        ),
        UserReview(
          authorName: 'Melis Kaya',
          rating: '4.5',
          comment: 'Güvenilir öğrenci. Eşyayı temiz kullandı.',
          dateText: '3 hafta önce',
        ),
      ],
    ),
    UserProfile(
      uid: 'user_2',
      name: 'Ayşe Yılmaz',
      username: '@ayseyilmaz',
      studentId: '20220202002',
      email: 'ayse@kampus.edu.tr',
      department: 'Endüstriyel Tasarım',
      bio: 'Tasarım öğrencisiyim. Çizim aletleri ve prototip malzemeleri paylaşabilirim.',
      trustScore: 98,
      averageRating: 4.9,
      reviewCount: 8,
      successfulBorrows: 4,
      successfulLends: 9,
      onTimeReturnRate: 100.0,
      avgResponseTime: '8 dk',
      lateReturnsCount: 0,
      verificationBadges: ['E-posta doğrulandı', 'Öğrenci profili'],
      userBadges: ['Hızlı İletişim', 'Cömert Paylaşım'],
      reviews: [
        UserReview(
          authorName: 'Ahmet Öz',
          rating: '5.0',
          comment: 'T cetvelini temiz bir şekilde iade etti. Teşekkürler!',
          dateText: '3 gün önce',
        ),
      ],
    ),
    UserProfile(
      uid: 'user_3',
      name: 'Can Demir',
      username: '@candemir',
      studentId: '20210303003',
      email: 'can@kampus.edu.tr',
      department: 'Elektrik-Elektronik Mühendisliği',
      bio: 'Elektronik kitleri ve ölçüm aletleri konusunda destek olabilirim.',
      trustScore: 90,
      averageRating: 4.7,
      reviewCount: 15,
      successfulBorrows: 10,
      successfulLends: 6,
      onTimeReturnRate: 95.0,
      avgResponseTime: '15 dk',
      lateReturnsCount: 1,
      verificationBadges: ['E-posta doğrulandı', 'Telefon doğrulandı'],
      userBadges: ['Teknoloji Uzmanı', 'Aktif Paylaşımcı'],
      reviews: [
        UserReview(
          authorName: 'Ahmet Öz',
          rating: '4.5',
          comment: 'Arduino setini ödünç aldım, çok yardımcı oldu.',
          dateText: '5 gün önce',
        ),
      ],
    ),
  ];

  MockAuthService() {
    // Start session as Ahmet Öz by default in mock mode
    _currentUser = _mockUsers[0];
    _controller.add(_currentUser);
  }

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Future<UserProfile?> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final matched = _mockUsers.firstWhere(
      (user) => user.email.toLowerCase() == email.trim().toLowerCase(),
      orElse: () => throw Exception('Kullanıcı bulunamadı.'),
    );
    _currentUser = matched;
    _controller.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<UserProfile?> signUp(String email, String password, String name) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newUser = UserProfile(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      username: '@${email.split('@')[0]}',
      studentId: '20220${DateTime.now().millisecondsSinceEpoch % 100000}',
      email: email,
      department: 'Kampüs Üyesi',
      bio: 'Emanetly ailesine katıldı.',
      trustScore: 100,
      averageRating: 5.0,
      reviewCount: 0,
      successfulBorrows: 0,
      successfulLends: 0,
      onTimeReturnRate: 100.0,
      avgResponseTime: 'Hızlı',
      lateReturnsCount: 0,
      verificationBadges: ['E-posta doğrulandı'],
      userBadges: ['Yeni Üye'],
      reviews: [],
    );
    _mockUsers.add(newUser);
    _currentUser = newUser;
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

  @override
  Future<void> sendEmailVerification() async {
    // Mock action
  }

  @override
  bool get isEmailVerified => true; // Mock is always verified

  @override
  Future<void> reloadUser() async {
    // Mock reload
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // Mock action
  }

  // Helper method for the prototype to swap users easily
  void switchUser(String uid) {
    final user = _mockUsers.firstWhere((u) => u.uid == uid, orElse: () => _mockUsers[0]);
    _currentUser = user;
    _controller.add(_currentUser);
  }

  @override
  List<UserProfile> get availableMockUsers => _mockUsers;

  @override
  void addReviewToUser(String targetUserId, UserReview review) {
    final index = _mockUsers.indexWhere((u) => u.uid == targetUserId);
    if (index != -1) {
      final user = _mockUsers[index];
      
      // Calculate new reviews list
      final updatedReviews = List<UserReview>.from(user.reviews)..add(review);
      
      // Calculate new average rating
      double totalRating = 0.0;
      for (final r in updatedReviews) {
        totalRating += double.tryParse(r.rating) ?? 5.0;
      }
      final double newAvg = updatedReviews.isEmpty ? 5.0 : (totalRating / updatedReviews.length);

      // Calculate new trust score dynamically (base 90 + rating weight)
      int newTrustScore = (newAvg * 20).round();
      if (newTrustScore > 100) newTrustScore = 100;
      if (newTrustScore < 0) newTrustScore = 0;

      // Update in memory list
      _mockUsers[index] = UserProfile(
        uid: user.uid,
        name: user.name,
        username: user.username,
        studentId: user.studentId,
        email: user.email,
        department: user.department,
        avatarUrl: user.avatarUrl,
        bio: user.bio,
        trustScore: newTrustScore,
        averageRating: double.parse(newAvg.toStringAsFixed(1)),
        reviewCount: updatedReviews.length,
        successfulBorrows: user.successfulBorrows + (review.comment.contains('iade') ? 1 : 0),
        successfulLends: user.successfulLends,
        onTimeReturnRate: user.onTimeReturnRate,
        avgResponseTime: user.avgResponseTime,
        lateReturnsCount: user.lateReturnsCount,
        verificationBadges: user.verificationBadges,
        userBadges: user.userBadges,
        reviews: updatedReviews,
      );

      // If this is also the current user, notify auth stream
      if (_currentUser?.uid == targetUserId) {
        _currentUser = _mockUsers[index];
        _controller.add(_currentUser);
      }
    }
  }

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    return _mockUsers.firstWhere((u) => u.uid == uid, orElse: () => _mockUsers[0]);
  }
}

class FirebaseAuthService implements AuthService {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final StreamController<UserProfile?> _controller = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;
  
  // Mutable cache list to support interactive evaluation in real-auth sessions
  final List<UserProfile> _mappedMockUsers = [
    UserProfile(
      uid: 'user_1',
      name: 'Ahmet Öz',
      username: '@ahmetoz',
      studentId: '20220101001',
      email: 'ahmet@kampus.edu.tr',
      department: 'Bilgisayar Mühendisliği',
      bio: 'Bilgisayar Mühendisliği 3. sınıf öğrencisi. Kampüste yardımlaşmayı ve sürdürülebilirliği destekliyorum.',
      trustScore: 94,
      averageRating: 4.8,
      reviewCount: 12,
      successfulBorrows: 8,
      successfulLends: 5,
      onTimeReturnRate: 100.0,
      avgResponseTime: '12 dk',
      lateReturnsCount: 0,
      verificationBadges: ['E-posta doğrulandı', 'Telefon doğrulandı', 'Öğrenci profili'],
      userBadges: ['Güvenilir ödünç veren', 'Zamanında iade', 'Hızlı yanıt'],
      reviews: [],
    ),
    UserProfile(
      uid: 'user_2',
      name: 'Ayşe Yılmaz',
      username: '@ayseyilmaz',
      studentId: '20220202002',
      email: 'ayse@kampus.edu.tr',
      department: 'Endüstriyel Tasarım',
      bio: 'Tasarım öğrencisiyim. Çizim aletleri ve prototip malzemeleri paylaşabilirim.',
      trustScore: 98,
      averageRating: 4.9,
      reviewCount: 8,
      successfulBorrows: 4,
      successfulLends: 9,
      onTimeReturnRate: 100.0,
      avgResponseTime: '8 dk',
      lateReturnsCount: 0,
      verificationBadges: ['E-posta doğrulandı', 'Öğrenci profili'],
      userBadges: ['Hızlı İletişim', 'Cömert Paylaşım'],
      reviews: [],
    ),
    UserProfile(
      uid: 'user_3',
      name: 'Can Demir',
      username: '@candemir',
      studentId: '20210303003',
      email: 'can@kampus.edu.tr',
      department: 'Elektrik-Elektronik Mühendisliği',
      bio: 'Elektronik kitleri ve ölçüm aletleri konusunda destek olabilirim.',
      trustScore: 90,
      averageRating: 4.7,
      reviewCount: 15,
      successfulBorrows: 10,
      successfulLends: 6,
      onTimeReturnRate: 95.0,
      avgResponseTime: '15 dk',
      lateReturnsCount: 1,
      verificationBadges: ['E-posta doğrulandı', 'Telefon doğrulandı'],
      userBadges: ['Teknoloji Uzmanı', 'Aktif Paylaşımcı'],
      reviews: [],
    ),
  ];

  FirebaseAuthService() {
    _firebaseAuth.authStateChanges().listen((fb.User? user) async {
      if (user == null) {
        _currentUser = null;
        _controller.add(null);
      } else {
        _loadUserProfileFromFirestore(user);
      }
    });
  }

  Future<void> _loadUserProfileFromFirestore(fb.User user) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    try {
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        _currentUser = UserProfile.fromMap(doc.data()!);
      } else {
        // Document doesn't exist on Firestore yet, let's create a default profile
        final defaultProfile = _mapFirebaseUser(user);
        await docRef.set(defaultProfile.toMap());
        _currentUser = defaultProfile;
      }
      _controller.add(_currentUser);
    } catch (e) {
      print('Emanetly: Error loading user profile from Firestore: $e');
      // Offline fallback: map user from in-memory template
      _currentUser = _mapFirebaseUser(user);
      _controller.add(_currentUser);
    }
  }

  UserProfile _mapFirebaseUser(fb.User user) {
    final String email = user.email ?? '';
    final mockMatches = _mappedMockUsers.where((u) => u.email.toLowerCase() == email.toLowerCase());
    if (mockMatches.isNotEmpty) {
      final matched = mockMatches.first;
      return UserProfile(
        uid: user.uid,
        name: user.displayName ?? matched.name,
        username: matched.username,
        studentId: matched.studentId,
        email: email,
        department: matched.department,
        avatarUrl: matched.avatarUrl,
        bio: matched.bio,
        trustScore: matched.trustScore,
        averageRating: matched.averageRating,
        reviewCount: matched.reviewCount,
        successfulBorrows: matched.successfulBorrows,
        successfulLends: matched.successfulLends,
        onTimeReturnRate: matched.onTimeReturnRate,
        avgResponseTime: matched.avgResponseTime,
        lateReturnsCount: matched.lateReturnsCount,
        verificationBadges: matched.verificationBadges,
        userBadges: matched.userBadges,
        reviews: matched.reviews,
      );
    }

    return UserProfile(
      uid: user.uid,
      name: user.displayName ?? email.split('@')[0],
      username: '@${email.split('@')[0]}',
      studentId: '10000000000',
      email: email,
      department: 'Kampüs Üyesi',
      bio: 'Emanetly ailesine yeni katıldı.',
      trustScore: 100,
      averageRating: 5.0,
      reviewCount: 0,
      successfulBorrows: 0,
      successfulLends: 0,
      onTimeReturnRate: 100.0,
      avgResponseTime: 'Yüksek',
      lateReturnsCount: 0,
      verificationBadges: ['E-posta doğrulandı'],
      userBadges: ['Yeni Üye'],
      reviews: [],
    );
  }

  @override
  UserProfile? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      // Async loading fallback trigger
      if (_currentUser == null || _currentUser!.uid != user.uid) {
        _currentUser = _mapFirebaseUser(user);
        _loadUserProfileFromFirestore(user);
      }
    } else {
      _currentUser = null;
    }
    return _currentUser;
  }

  @override
  Future<UserProfile?> signIn(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (credential.user != null) {
      await _loadUserProfileFromFirestore(credential.user!);
      return _currentUser;
    }
    return null;
  }

  @override
  Future<UserProfile?> signUp(String email, String password, String name) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (credential.user != null) {
      await credential.user!.updateDisplayName(name.trim());
      await credential.user!.reload();
      final freshUser = _firebaseAuth.currentUser ?? credential.user!;
      
      // Write profile directly to Firestore on registration success
      final defaultProfile = _mapFirebaseUser(freshUser);
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(freshUser.uid)
            .set(defaultProfile.toMap());
      } catch (e) {
        print('Emanetly: Error writing user profile on signUp: $e');
      }
      
      _currentUser = defaultProfile;
      _controller.add(_currentUser);
      return _currentUser;
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
  }

  @override
  Stream<UserProfile?> get onAuthStateChanged => _controller.stream;

  @override
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  @override
  bool get isEmailVerified {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return user.emailVerified;
    }
    return false;
  }

  @override
  Future<void> reloadUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  List<UserProfile> get availableMockUsers => _mappedMockUsers;

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    // Check local cache list first
    final cached = _mappedMockUsers.where((u) => u.uid == uid);
    if (cached.isNotEmpty) return cached.first;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!);
      }
    } catch (e) {
      print('Emanetly: Error getting user profile from Firestore: $e');
    }
    return null;
  }

  @override
  void addReviewToUser(String targetUserId, UserReview review) {
    final index = _mappedMockUsers.indexWhere((u) => u.uid == targetUserId);
    if (index != -1) {
      final user = _mappedMockUsers[index];
      
      // Calculate new reviews list
      final updatedReviews = List<UserReview>.from(user.reviews)..add(review);
      
      // Calculate new average rating
      double totalRating = 0.0;
      for (final r in updatedReviews) {
        totalRating += double.tryParse(r.rating) ?? 5.0;
      }
      final double newAvg = updatedReviews.isEmpty ? 5.0 : (totalRating / updatedReviews.length);

      // Calculate new trust score dynamically (base 90 + rating weight)
      int newTrustScore = (newAvg * 20).round();
      if (newTrustScore > 100) newTrustScore = 100;
      if (newTrustScore < 0) newTrustScore = 0;

      // Update in memory list
      _mappedMockUsers[index] = UserProfile(
        uid: user.uid,
        name: user.name,
        username: user.username,
        studentId: user.studentId,
        email: user.email,
        department: user.department,
        avatarUrl: user.avatarUrl,
        bio: user.bio,
        trustScore: newTrustScore,
        averageRating: double.parse(newAvg.toStringAsFixed(1)),
        reviewCount: updatedReviews.length,
        successfulBorrows: user.successfulBorrows + (review.comment.contains('iade') ? 1 : 0),
        successfulLends: user.successfulLends,
        onTimeReturnRate: user.onTimeReturnRate,
        avgResponseTime: user.avgResponseTime,
        lateReturnsCount: user.lateReturnsCount,
        verificationBadges: user.verificationBadges,
        userBadges: user.userBadges,
        reviews: updatedReviews,
      );

      // If this is also the current user, notify auth stream
      if (_currentUser?.uid == targetUserId) {
        _currentUser = _mappedMockUsers[index];
        _controller.add(_currentUser);
      }
    }
  }
}
