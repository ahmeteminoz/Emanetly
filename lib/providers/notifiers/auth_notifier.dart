import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import '../../services/crashlytics_service.dart';
import '../../services/block_service.dart';

enum ViewMode {
  compactGrid,
  standardGrid,
  largeCards;
}

/// AuthNotifier - Kullanıcı kimlik doğrulama, tema, favoriler ve engelleme mantığını yönetir.
/// AppState facade'ı tarafından orkestra edilir; tüm public getter/metodlar korunur.
class AuthNotifier extends ChangeNotifier {
  final AuthService _authService;
  final AnalyticsService _analyticsService;
  final CrashlyticsService _crashlyticsService;

  // Theme & UI preferences
  ThemeMode _themeMode = ThemeMode.system;
  int _selectedPaletteIndex = 0;
  ViewMode _gridViewMode = ViewMode.standardGrid;

  // Favorites
  final Set<String> _favoriteItemIds = {};
  bool _favoritesInitialized = false;

  // Blocked users
  final Set<String> _blockedUserIds = {};
  final Set<String> _blockedRelationUserIds = {};

  // Subscriptions
  StreamSubscription<UserProfile?>? _authSubscription;
  StreamSubscription? _blockedUsersSubscription;
  StreamSubscription? _userRelationsSubscription;

  BlockService? _blockService;
  BlockService get blockService => _blockService ??= FirestoreBlockService();

  /// Callback: AuthNotifier dışarıya auth değişimlerini haber verir
  /// (AppState'in kendi dinleyicilerini tetiklemesi için)
  void Function(UserProfile? user)? onAuthChanged;

  AuthNotifier({
    required AuthService authService,
    AnalyticsService? analyticsService,
    CrashlyticsService? crashlyticsService,
  })  : _authService = authService,
        _analyticsService = analyticsService ?? AnalyticsService(),
        _crashlyticsService = crashlyticsService ?? CrashlyticsService() {
    _authSubscription = _authService.onAuthStateChanged.listen((user) {
      if (user != null) {
        if (!_favoritesInitialized) {
          _favoriteItemIds
            ..clear()
            ..addAll(user.favoriteItemIds);
          _favoritesInitialized = true;
        }
        _startBlockedUsersSubscription(user.uid);
        _startUserRelationsSubscription(user.uid);
      } else {
        _blockedUsersSubscription?.cancel();
        _userRelationsSubscription?.cancel();
        _blockedUserIds.clear();
        _blockedRelationUserIds.clear();
        _favoriteItemIds.clear();
        _favoritesInitialized = false;
      }
      onAuthChanged?.call(user);
      notifyListeners();
    });
  }

  // ─── Getters ─────────────────────────────────────────────────────────────

  UserProfile? get currentUser => _authService.currentUser;
  AuthService get authService => _authService;
  List<UserProfile> get availableMockUsers => _authService.availableMockUsers;
  bool get isProfileLoaded => _authService.isProfileLoaded;

  ThemeMode get themeMode => _themeMode;
  int get selectedPaletteIndex => _selectedPaletteIndex;
  ViewMode get gridViewMode => _gridViewMode;
  Set<String> get favoriteItemIds => _favoriteItemIds;
  Set<String> get blockedRelationUserIds => _blockedRelationUserIds;

  // ─── Theme ───────────────────────────────────────────────────────────────

  void changeThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.toString());
  }

  void changePalette(int index) async {
    _selectedPaletteIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedPaletteIndex', index);
  }

  void changeViewMode(ViewMode mode) async {
    _gridViewMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gridViewMode', mode.toString());
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme
    final themeStr = prefs.getString('themeMode');
    if (themeStr != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeStr,
        orElse: () => ThemeMode.system,
      );
    }
    
    // Load palette
    _selectedPaletteIndex = prefs.getInt('selectedPaletteIndex') ?? 0;
    
    // Load view mode
    final viewModeStr = prefs.getString('gridViewMode');
    if (viewModeStr != null) {
      _gridViewMode = ViewMode.values.firstWhere(
        (e) => e.toString() == viewModeStr,
        orElse: () => ViewMode.standardGrid,
      );
    }
    notifyListeners();
  }

  // ─── Auth ────────────────────────────────────────────────────────────────

  Future<UserProfile?> getUserProfile(String uid) async {
    return _authService.getUserProfile(uid);
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _authService.updateUserProfile(profile);
    notifyListeners();
  }

  Future<void> updateUserProfilePhoto(String uid, String photoUrl) async {
    final user = await _authService.getUserProfile(uid);
    if (user != null) {
      await _authService.updateUserProfile(user.copyWith(avatarUrl: photoUrl));
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    notifyListeners();
  }

  Future<void> deleteUserAccount() async {
    if (currentUser == null) return;
    try {
      if (Firebase.apps.isNotEmpty) {
        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('requestAccountDeletion');
        await callable.call({'userId': currentUser!.uid});
      }
      await _authService.signOut();
      notifyListeners();
    } catch (e, stack) {
      _crashlyticsService.recordError(e, stack, reason: 'deleteUserAccount failed');
      rethrow;
    }
  }

  void switchUser(String uid) {
    final service = _authService;
    if (service is MockAuthService) {
      service.switchUser(uid);
      notifyListeners();
    }
  }

  // ─── Favorites ───────────────────────────────────────────────────────────

  bool isFavorite(String itemId) => _favoriteItemIds.contains(itemId);

  void toggleFavorite(String itemId, {String itemCategory = 'genel'}) async {
    if (currentUser == null) return;
    final bool isAlreadyFav = isFavorite(itemId);

    // Optimistic update
    if (isAlreadyFav) {
      _favoriteItemIds.remove(itemId);
    } else {
      _favoriteItemIds.add(itemId);
    }
    notifyListeners();

    try {
      await _authService.toggleFavorite(currentUser!.uid, itemId, !isAlreadyFav);
      _analyticsService.logFavoriteToggled(
        action: isAlreadyFav ? 'remove' : 'add',
        category: itemCategory,
      );
    } catch (e) {
      // Rollback on failure
      if (isAlreadyFav) {
        _favoriteItemIds.add(itemId);
      } else {
        _favoriteItemIds.remove(itemId);
      }
      notifyListeners();
    }
  }

  void initFavoritesFromUser(UserProfile user) {
    if (!_favoritesInitialized) {
      _favoriteItemIds
        ..clear()
        ..addAll(user.favoriteItemIds);
      _favoritesInitialized = true;
    }
  }

  // ─── Block ───────────────────────────────────────────────────────────────

  bool isUserBlocked(String uid) => _blockedUserIds.contains(uid);

  bool isRelationBlocked(String uid) =>
      _blockedUserIds.contains(uid) || _blockedRelationUserIds.contains(uid);

  Future<void> blockUser(String targetUserId, {required String source}) async {
    if (currentUser == null || targetUserId.isEmpty || currentUser!.uid == targetUserId) return;
    try {
      if (Firebase.apps.isNotEmpty) {
        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('toggleBlockUser');
        await callable.call({
          'targetUserId': targetUserId,
          'shouldBlock': true,
          'source': source,
        });
      } else {
        await blockService.blockUser(
          currentUserId: currentUser!.uid,
          blockedUserId: targetUserId,
          source: source,
        );
      }
      _blockedUserIds.add(targetUserId);
      _blockedRelationUserIds.add(targetUserId);
      _analyticsService.logUserBlocked(source: source);
      notifyListeners();
    } catch (e, stack) {
      _crashlyticsService.recordError(e, stack, reason: 'blockUser failed');
      rethrow;
    }
  }

  Future<void> unblockUser(String targetUserId) async {
    if (currentUser == null || targetUserId.isEmpty) return;
    try {
      if (Firebase.apps.isNotEmpty) {
        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('toggleBlockUser');
        await callable.call({
          'targetUserId': targetUserId,
          'shouldBlock': false,
        });
      } else {
        await blockService.unblockUser(
          currentUserId: currentUser!.uid,
          blockedUserId: targetUserId,
        );
      }
      _blockedUserIds.remove(targetUserId);
      _blockedRelationUserIds.remove(targetUserId);
      notifyListeners();
    } catch (e, stack) {
      _crashlyticsService.recordError(e, stack, reason: 'unblockUser failed');
      rethrow;
    }
  }

  // ─── FCM Token ───────────────────────────────────────────────────────────

  void updateFcmToken(String userId, String token) async {
    final user = _authService.currentUser;
    if (user == null) return;
    // Skip if already stored locally
    if (user.fcmTokens.contains(token)) return;
    try {
      // Use arrayUnion to safely add token without overwriting any other fields
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token])
      });
    } catch (_) {}
  }

  // ─── Private Subscriptions ───────────────────────────────────────────────

  void _startBlockedUsersSubscription(String userId) {
    _blockedUsersSubscription?.cancel();
    if (Firebase.apps.isNotEmpty) {
      _blockedUsersSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('blockedUsers')
          .snapshots()
          .listen((snapshot) {
        final newSet = <String>{};
        for (final doc in snapshot.docs) {
          final blockedUserId = doc.data()['blockedUserId'];
          if (blockedUserId != null && blockedUserId is String) {
            newSet.add(blockedUserId);
          }
        }
        _blockedUserIds.clear();
        _blockedUserIds.addAll(newSet);
        notifyListeners();
      }, onError: (e) {
        debugPrint('Emanetly: blockedUsers stream error: $e');
      });
    }
  }

  void _startUserRelationsSubscription(String userId) {
    _userRelationsSubscription?.cancel();
    if (Firebase.apps.isNotEmpty) {
      _userRelationsSubscription = FirebaseFirestore.instance
          .collection('userRelations')
          .where('users', arrayContains: userId)
          .where('interactionBlocked', isEqualTo: true)
          .snapshots()
          .listen((snapshot) {
        final newSet = <String>{};
        for (final doc in snapshot.docs) {
          final users = List<String>.from(doc.data()['users'] ?? []);
          for (final u in users) {
            if (u != userId) newSet.add(u);
          }
        }
        _blockedRelationUserIds.clear();
        _blockedRelationUserIds.addAll(newSet);
        notifyListeners();
      }, onError: (e) {
        debugPrint('Emanetly: userRelations stream error: $e');
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _blockedUsersSubscription?.cancel();
    _userRelationsSubscription?.cancel();
    super.dispose();
  }
}
