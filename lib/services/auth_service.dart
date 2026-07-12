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
          comment: 'Eşyayı temiz kullandı ve vaktinde iade etti.',
          dateText: '2 hafta önce',
        ),
      ],
    ),
    UserProfile(
      uid: 'user_2',
      name: 'Ayşe Yılmaz',
      username: '@ayseyilmaz',
      studentId: '20230202042',
      email: 'ayse@kampus.edu.tr',
      department: 'Endüstri Tasarımı',
      bio: 'Endüstriyel Tasarım öğrencisiyim. İhtiyacınız olan maket malzemelerini veya cetvelleri sorabilirsiniz.',
      trustScore: 97,
      averageRating: 4.9,
      reviewCount: 8,
      successfulBorrows: 4,
      successfulLends: 9,
      onTimeReturnRate: 100.0,
      avgResponseTime: '8 dk',
      lateReturnsCount: 0,
      verificationBadges: ['E-posta doğrulandı', 'Öğrenci profili'],
      userBadges: ['Aktif paylaşımcı', 'Hızlı yanıt'],
      reviews: [
        UserReview(
          authorName: 'Ahmet Öz',
          rating: '5.0',
          comment: 'USB-C kablosunu çok temiz teslim etti, çok teşekkürler.',
          dateText: '3 gün önce',
        ),
        UserReview(
          authorName: 'Can Demir',
          rating: '4.8',
          comment: 'Gereksiz uzatmadan hemen teslim etti.',
          dateText: '3 hafta önce',
        ),
      ],
    ),
    UserProfile(
      uid: 'user_3',
      name: 'Can Demir',
      username: '@candemir',
      studentId: '20210303077',
      email: 'can@kampus.edu.tr',
      department: 'Fizik Bölümü',
      bio: 'Fizik Bölümü öğrencisiyim. Genelde merkez kütüphane veya fizik kantini çevresindeyim.',
      trustScore: 89,
      averageRating: 4.5,
      reviewCount: 5,
      successfulBorrows: 6,
      successfulLends: 3,
      onTimeReturnRate: 92.0,
      avgResponseTime: '25 dk',
      lateReturnsCount: 1,
      verificationBadges: ['E-posta doğrulandı', 'Telefon doğrulandı'],
      userBadges: ['Yardımsever'],
      reviews: [
        UserReview(
          authorName: 'Ahmet Öz',
          rating: '4.0',
          comment: 'T-cetvelini aldım, iletişimi iyiydi ama teslimatta 5 dk gecikti.',
          dateText: '5 gün önce',
        ),
      ],
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
}
