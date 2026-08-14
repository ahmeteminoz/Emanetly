import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/user_profile.dart';
import '../models/borrow_request.dart';
import '../models/chat_message.dart';
import '../models/meeting_point_proposal.dart';
import '../services/auth_service.dart';
import '../services/item_service.dart';
import '../services/borrow_request_service.dart';
import '../services/chat_message_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import 'notifiers/auth_notifier.dart';
export 'notifiers/auth_notifier.dart' show ViewMode;
import 'notifiers/item_notifier.dart';
import 'notifiers/request_notifier.dart';

class AppState extends ChangeNotifier {
  // ─── Modüler Notifier'lar ─────────────────────────────────────────────────
  late final AuthNotifier _authNotifier;
  late final ItemNotifier _itemNotifier;
  late final RequestNotifier _requestNotifier;

  // ─── Servisler (AppState düzeyinde kalan) ─────────────────────────────────
  final AnalyticsService _analyticsService;
  final CrashlyticsService _crashlyticsService;

  // ─── Activity Logs ────────────────────────────────────────────────────────
  bool _isLoading = false;
  final List<String> _activityLogs = [];

  String? _currentFcmToken;

  AppState({
    required AuthService authService,
    required ItemService itemService,
    required BorrowRequestService borrowRequestService,
    required ChatMessageService chatMessageService,
    required StorageService storageService,
    AnalyticsService? analyticsService,
    CrashlyticsService? crashlyticsService,
  })  : _analyticsService = analyticsService ?? AnalyticsService(),
        _crashlyticsService = crashlyticsService ?? CrashlyticsService() {

    _authNotifier = AuthNotifier(
      authService: authService,
      analyticsService: _analyticsService,
      crashlyticsService: _crashlyticsService,
    );

    _itemNotifier = ItemNotifier(
      itemService: itemService,
      storageService: storageService,
      analyticsService: _analyticsService,
      crashlyticsService: _crashlyticsService,
    );

    _requestNotifier = RequestNotifier(
      borrowRequestService: borrowRequestService,
      chatMessageService: chatMessageService,
      currentUser: () => _authNotifier.currentUser,
      isUserBlocked: (uid) => _authNotifier.isUserBlocked(uid),
      analyticsService: _analyticsService,
    );
    _requestNotifier.onLog = _addLog;

    // Auth değişimlerini dinle
    _authNotifier.onAuthChanged = (UserProfile? user) {
      if (user != null) {
        _requestNotifier.startRequestsSubscription(user.uid);
        _setupNotifications(user.uid);
      } else {
        _requestNotifier.cancelRequestsSubscription();
      }
      notifyListeners();
    };
    _authNotifier.addListener(notifyListeners);
    _itemNotifier.addListener(notifyListeners);
    _requestNotifier.addListener(notifyListeners);

    // Uygulama açıkken zaten giriş yapılmışsa
    final initialUser = _authNotifier.currentUser;
    if (initialUser != null) {
      _requestNotifier.startRequestsSubscription(initialUser.uid);
      _setupNotifications(initialUser.uid);
    }

    _loadInitialData();
  }

  // ─── Getters ──────────────────────────────────────────────────────────────
  AnalyticsService get analytics => _analyticsService;
  CrashlyticsService get crashlytics => _crashlyticsService;

  // ─── Items delegation (ItemNotifier) ──────────────────────────────────────
  List<EmanetItem> get items {
    return List.unmodifiable(
      _itemNotifier.rawItems.where(
        (item) =>
            item.status != EmanetStatus.archived &&
            !isRelationBlocked(item.lenderId),
      ),
    );
  }

  List<EmanetItem> get allItems => _itemNotifier.rawItems;

  EmanetItem? findItemInMemory(String itemId) =>
      _itemNotifier.findItemInMemory(itemId);

  Future<EmanetItem?> getItemById(String itemId) =>
      _itemNotifier.getItemById(itemId);

  // Private accessor for internal business methods
  List<EmanetItem> get _items => _itemNotifier.rawItems.toList();
  ItemService get _itemService => _itemNotifier.itemService;
  StorageService get _storageService => _itemNotifier.storageService;
  ItemService get itemService => _itemNotifier.itemService;

  // ─── Auth delegation (AuthNotifier) ───────────────────────────────────────
  UserProfile? get currentUser => _authNotifier.currentUser;
  AuthService get authService => _authNotifier.authService;
  List<UserProfile> get availableMockUsers => _authNotifier.availableMockUsers;

  ThemeMode get themeMode => _authNotifier.themeMode;
  int get selectedPaletteIndex => _authNotifier.selectedPaletteIndex;
  ViewMode get gridViewMode => _authNotifier.gridViewMode;
  Set<String> get favoriteItemIds => _authNotifier.favoriteItemIds;
  Set<String> get blockedRelationUserIds =>
      _authNotifier.blockedRelationUserIds;

  bool get isLoading => _isLoading;
  List<String> get activityLogs =>
      List.unmodifiable(_activityLogs.reversed);

  // ─── Request delegation (RequestNotifier) ────────────────────────────────
  List<BorrowRequestModel> get borrowRequests =>
      _requestNotifier.borrowRequests;

  void setActiveChatRoom(String? requestId) =>
      _requestNotifier.setActiveChatRoom(requestId);

  List<ChatMessageModel> getChatMessagesForRequest(String requestId) =>
      _requestNotifier.getChatMessagesForRequest(requestId);

  int getUnreadCountForRequest(String requestId) =>
      _requestNotifier.getUnreadCountForRequest(requestId);

  int get totalUnreadCount => _requestNotifier.totalUnreadCount;

  MeetingPointProposalModel? getProposal(String proposalId) =>
      _requestNotifier.getProposal(proposalId);

  BorrowRequestModel? getRequestForActiveItem(String itemId) =>
      _requestNotifier.getRequestForActiveItem(itemId);

  Future<void> sendChatMessage(String requestId, String text,
          {String? customPayload}) =>
      _requestNotifier.sendChatMessage(requestId, text,
          customPayload: customPayload);

  Future<void> markMessagesAsRead(String requestId) =>
      _requestNotifier.markMessagesAsRead(requestId);

  Future<void> proposeMeetingPoint(
          String requestId, String title, String addressText, String timeText) =>
      _requestNotifier.proposeMeetingPoint(
          requestId, title, addressText, timeText);

  Future<void> acceptMeetingPoint(String proposalId) =>
      _requestNotifier.acceptMeetingPoint(proposalId);

  Future<void> rejectMeetingPoint(String proposalId) =>
      _requestNotifier.rejectMeetingPoint(proposalId);

  void rejectBorrowRequest(String requestId) =>
      _requestNotifier.rejectBorrowRequest(requestId);

  // ─── Utility ──────────────────────────────────────────────────────────────
  void _loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _addLog('Uygulama başarıyla başlatıldı.');
    } catch (e) {
      _addLog('Veri yüklenirken hata oluştu: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    try {
      await _itemNotifier.refreshItems();
      if (currentUser != null) {
        await _authNotifier.authService.reloadUser();
      }
      _addLog('Veriler başarıyla yenilendi.');
    } catch (e) {
      _addLog('Yenileme sırasında hata oluştu: $e');
    } finally {
      notifyListeners();
    }
  }

  void _addLog(String log) {
    final timestamp = DateTime.now().toLocal().toString().substring(11, 16);
    _activityLogs.add('[$timestamp] $log');
    notifyListeners();
  }

  // ─── Theme delegation ──────────────────────────────────────────────────────
  void changeThemeMode(ThemeMode mode) {
    _authNotifier.changeThemeMode(mode);
    _addLog('Tema modu değiştirildi: ${mode.name}');
  }

  void changePalette(int index) {
    _authNotifier.changePalette(index);
    _addLog('Renk paleti değiştirildi: İndeks $index');
  }

  void changeViewMode(ViewMode mode) {
    _authNotifier.changeViewMode(mode);
    _addLog('Görünüm modu değiştirildi: ${mode.name}');
  }

  // ─── Block delegation ──────────────────────────────────────────────────────
  bool isUserBlocked(String uid) => _authNotifier.isUserBlocked(uid);
  bool isRelationBlocked(String uid) => _authNotifier.isRelationBlocked(uid);

  Future<void> blockUser(String targetUserId, {required String source}) async {
    await _authNotifier.blockUser(targetUserId, source: source);
    _addLog('Kullanıcı engellendi: $targetUserId');
  }

  Future<void> unblockUser(String targetUserId) async {
    await _authNotifier.unblockUser(targetUserId);
    _addLog('Kullanıcı engeli kaldırıldı: $targetUserId');
  }

  // ─── confirmHandoverAction (koordinatör — hem request hem item günceller) ──
  Future<bool> confirmHandoverAction(String requestId, String action) async {
    if (currentUser == null) return false;
    _setLoading(true);
    try {
      if (Firebase.apps.isNotEmpty) {
        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('confirmHandoverAction');
        final res = await callable.call({
          'requestId': requestId,
          'action': action,
        });

        final data = res.data as Map;
        final bool success = data['success'] ?? false;
        _addLog('Emanet Teslim/İade aksiyonu gönderildi: $action, Sonuç: $success');
        return success;
      } else {
        // Local simulation for widget/unit tests
        final borrowRequests = _requestNotifier.mutableBorrowRequests;
        final reqIndex = borrowRequests.indexWhere((r) => r.id == requestId);
        if (reqIndex == -1) return false;
        final req = borrowRequests[reqIndex];

        final items = _items;
        final itemIndex = items.indexWhere((i) => i.id == req.itemId);
        if (itemIndex == -1) return false;
        final item = items[itemIndex];

        DateTime? handoverLenderConfirmedAt = req.handoverLenderConfirmedAt;
        DateTime? handoverBorrowerConfirmedAt = req.handoverBorrowerConfirmedAt;
        DateTime? returnBorrowerConfirmedAt = req.returnBorrowerConfirmedAt;
        DateTime? returnLenderConfirmedAt = req.returnLenderConfirmedAt;

        if (action == 'lender_handover') {
          handoverLenderConfirmedAt = DateTime.now();
        } else if (action == 'borrower_receipt') {
          handoverBorrowerConfirmedAt = DateTime.now();
        } else if (action == 'borrower_return') {
          returnBorrowerConfirmedAt = DateTime.now();
        } else if (action == 'lender_return_receipt') {
          returnLenderConfirmedAt = DateTime.now();
        }

        BorrowRequestStatus newStatus = req.status;
        EmanetStatus newItemStatus = item.status;
        DeliveryStatus? newDeliveryStatus = item.deliveryStatus;
        String? borrowerId = item.borrowerId;

        if (handoverLenderConfirmedAt != null &&
            handoverBorrowerConfirmedAt != null) {
          newStatus = BorrowRequestStatus.borrowed;
          newItemStatus = EmanetStatus.borrowed;
          borrowerId = req.requesterId;
          newDeliveryStatus = DeliveryStatus.delivered;
        }

        if (returnBorrowerConfirmedAt != null &&
            returnLenderConfirmedAt != null) {
          newStatus = BorrowRequestStatus.completed;
          newItemStatus = EmanetStatus.archived;
          borrowerId = null;
          newDeliveryStatus = null;
        }

        borrowRequests[reqIndex] = req.copyWith(
          status: newStatus,
          handoverLenderConfirmedAt: handoverLenderConfirmedAt,
          handoverBorrowerConfirmedAt: handoverBorrowerConfirmedAt,
          returnBorrowerConfirmedAt: returnBorrowerConfirmedAt,
          returnLenderConfirmedAt: returnLenderConfirmedAt,
        );

        final updatedItem = item.copyWith(
          status: newItemStatus,
          borrowerId: borrowerId,
          deliveryStatus: newDeliveryStatus,
        );
        await _itemService.updateItem(updatedItem);

        _addLog('Yerel simulasyon tamamlandı: $action');
        notifyListeners();
        return true;
      }
    } catch (e, stack) {
      _addLog('confirmHandoverAction hatası: $e');
      _crashlyticsService.recordError(e, stack,
          reason: 'confirmHandoverAction failed');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Favorites delegation ──────────────────────────────────────────────────
  bool isFavorite(String itemId) => _authNotifier.isFavorite(itemId);

  void toggleFavorite(String itemId) {
    final itemCategory =
        _items.where((i) => i.id == itemId).firstOrNull?.category ?? 'genel';
    _authNotifier.toggleFavorite(itemId, itemCategory: itemCategory);
    final isNowFav = _authNotifier.isFavorite(itemId);
    _addLog(isNowFav
        ? 'Ürün favorilere eklendi: $itemId'
        : 'Ürün favorilerden çıkarıldı: $itemId');
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    return _authNotifier.getUserProfile(uid);
  }

  void switchUser(String uid) {
    _authNotifier.switchUser(uid);
    _addLog('Aktif kullanıcı değiştirildi: ${currentUser?.name}');
  }

  // ─── Item Actions ──────────────────────────────────────────────────────────
  Future<bool> addNewItem({
    required String title,
    required String description,
    required String category,
    required String location,
    String? imageUrl,
    List<String> images = const [],
    int? mockColorValue,
    void Function(double progress)? onProgress,
  }) async {
    if (currentUser == null) return false;
    _setLoading(true);
    final itemId = 'item_${DateTime.now().millisecondsSinceEpoch}';
    final uploadedPaths = <String>[];
    bool draftCreated = false;

    String resolvedLenderName = 'Bilinmeyen Kullanıcı';
    final nameTrimmed = currentUser!.name.trim();
    final usernameTrimmed = (currentUser!.username ?? '').trim();
    final emailTrimmed = currentUser!.email.trim();

    if (nameTrimmed.isNotEmpty) {
      resolvedLenderName = nameTrimmed;
    } else if (usernameTrimmed.isNotEmpty) {
      resolvedLenderName = usernameTrimmed;
    } else if (emailTrimmed.isNotEmpty) {
      final emailPart = emailTrimmed.split('@').first.trim();
      if (emailPart.isNotEmpty) resolvedLenderName = emailPart;
    }

    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance.collection('items').doc(itemId).set({
          'lenderId': currentUser!.uid,
          'lenderName': resolvedLenderName,
          'status': 'draft',
          'createdAt': FieldValue.serverTimestamp(),
        });
        draftCreated = true;
        debugPrint(
            'Emanetly Upload Step 1: Draft item created in Firestore for $itemId with lenderName: $resolvedLenderName');
      }

      final sourcePaths = List<String>.from(images);
      if (sourcePaths.isEmpty && imageUrl != null && imageUrl.isNotEmpty) {
        sourcePaths.add(imageUrl);
      }

      final uploadedUrls = <String>[];
      if (sourcePaths.isNotEmpty) {
        final double progressScale = 1.0 / sourcePaths.length;
        for (int i = 0; i < sourcePaths.length; i++) {
          final path = sourcePaths[i];
          if (path.startsWith('http')) {
            uploadedUrls.add(path);
          } else {
            final file = File(path);
            debugPrint(
                'Emanetly Upload Step 3: Local file exists = ${file.existsSync()}, size = ${file.existsSync() ? file.lengthSync() : 0} bytes');
            final downloadUrl = await _storageService.uploadItemImage(
              itemId,
              file,
              onProgress: onProgress != null
                  ? (p) => onProgress((i + p) * progressScale)
                  : null,
            );
            uploadedPaths.add(path);
            uploadedUrls.add(downloadUrl);
            debugPrint('Emanetly Upload Step 6: Download URL = $downloadUrl');
          }
        }
      }

      final colorOptions = [
        0xFF3B82F6,
        0xFFEF4444,
        0xFFF59E0B,
        0xFF10B981,
        0xFF8B5CF6,
        0xFFEC4899,
      ];
      final finalColor = mockColorValue ??
          colorOptions[DateTime.now().millisecond % colorOptions.length];

      final newItem = EmanetItem(
        id: itemId,
        title: title,
        description: description,
        category: category,
        lenderId: currentUser!.uid,
        lenderName: resolvedLenderName,
        location: location,
        imageUrl: uploadedUrls.isNotEmpty ? uploadedUrls.first : null,
        images: uploadedUrls,
        status: EmanetStatus.available,
        createdAt: DateTime.now(),
        comments: [],
        mockImageColorValue: finalColor,
      );
      debugPrint(
          'Emanetly Upload Step 7: Transitioning item status to available...');
      await _itemService.addItem(newItem);
      _analyticsService.logListingCreated(
          category: category, durationBucket: 'standard');
      _addLog('$resolvedLenderName, yeni bir ilan yayınladı: "$title"');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Emanetly Upload ERROR: $e');
      _crashlyticsService.recordError(e, stackTrace,
          reason: 'Eşya eklenirken hata');
      _addLog('Eşya eklenirken hata: $e');

      if (draftCreated && Firebase.apps.isNotEmpty) {
        try {
          for (final p in uploadedPaths) {
            await _storageService.deleteImage(p);
          }
        } catch (cleanupErr) {
          debugPrint(
              'Emanetly Cleanup Non-fatal: Storage cleanup failed: $cleanupErr');
        }
        try {
          await FirebaseFirestore.instance
              .collection('items')
              .doc(itemId)
              .delete();
        } catch (cleanupErr) {
          debugPrint(
              'Emanetly Cleanup Non-fatal: Draft doc cleanup failed: $cleanupErr');
        }
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ─── requestBorrow (koordinatör — item + request + chat) ──────────────────
  Future<BorrowRequestModel?> requestBorrow(
    String itemId, {
    bool isOfficialRequest = true,
  }) async {
    if (currentUser == null) return null;
    _setLoading(true);
    try {
      final item = _items.firstWhere((i) => i.id == itemId);

      final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';
      final status = isOfficialRequest
          ? BorrowRequestStatus.pendingDiscussion
          : BorrowRequestStatus.onlyInquiry;

      final newRequest = BorrowRequestModel(
        id: requestId,
        itemId: itemId,
        ownerId: item.lenderId,
        requesterId: currentUser!.uid,
        status: status,
        requestedDurationText: 'Belirtilmedi',
        createdAt: DateTime.now(),
      );

      await _requestNotifier.borrowRequestService.addBorrowRequest(newRequest);
      _analyticsService.logBorrowRequestCreated(
        category: item.category,
        durationBucket: 'unspecified',
      );

      await _requestNotifier.chatMessageService.sendChatMessage(ChatMessageModel(
        id: 'msg_sys_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        senderId: 'system',
        senderName: 'Sistem',
        text: isOfficialRequest
            ? 'Ödünç talebi gönderildi. İlan sahibinin yanıtı bekleniyor.'
            : 'Ön görüşme odası oluşturuldu.',
        type: ChatMessageType.system,
        createdAt: DateTime.now(),
      ));

      _addLog('${currentUser!.name}, "${item.title}" için ön görüşme başlattı.');
      return newRequest;
    } catch (e) {
      _addLog('Ödünç talebi hatası: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> upgradeToOfficialRequest(String requestId) async {
    _setLoading(true);
    try {
      await _requestNotifier.upgradeToOfficialRequest(requestId);
    } catch (e) {
      _addLog('Talep resmiyete dökülürken hata: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> approveBorrow(String itemId) async {
    try {
      final item = _items.firstWhere((i) => i.id == itemId);
      await _itemService.approveBorrow(itemId);
      _addLog('"${item.title}" talebi onaylandı. Buluşma noktası belirlenmesi bekleniyor.');
    } catch (e) {
      _addLog('Talep onaylama hatası: $e');
    }
  }

  Future<void> rejectBorrow(String itemId) async {
    try {
      final item = _items.firstWhere((i) => i.id == itemId);
      await _itemService.rejectBorrow(itemId);
      _addLog('"${item.title}" ödünç talebi reddedildi.');
    } catch (e) {
      _addLog('Talep reddetme hatası: $e');
    }
  }

  Future<void> setMeetingPoint(String itemId, String meetingPoint) async {
    _setLoading(true);
    try {
      await _itemService.setMeetingPoint(itemId, meetingPoint);
      _addLog('Buluşma noktası ayarlandı: $meetingPoint');
    } catch (e) {
      _addLog('Buluşma noktası ayarlanırken hata: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateMeetingDetails(
      String itemId, String location, String note) async {
    _setLoading(true);
    try {
      final combined =
          note.isNotEmpty ? '$location | Not: $note' : location;
      await _itemService.setMeetingPoint(itemId, combined);

      final activeReq = getRequestForActiveItem(itemId);
      if (activeReq != null) {
        await _requestNotifier.borrowRequestService
            .updateMeetingDetails(activeReq.id, location, note);
      }
      _addLog('Buluşma detayları kaydedildi: $location ($note)');
    } catch (e) {
      _addLog('Buluşma detayları kaydedilirken hata: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ─── acceptBorrowRequest (koordinatör — hem item hem request günceller) ────
  void acceptBorrowRequest(String requestId) async {
    final borrowRequests = _requestNotifier.mutableBorrowRequests;
    final reqIndex = borrowRequests.indexWhere((r) => r.id == requestId);
    if (reqIndex == -1) return;
    final request = borrowRequests[reqIndex];

    await _requestNotifier.borrowRequestService
        .updateBorrowRequestStatus(requestId, BorrowRequestStatus.accepted);
    _analyticsService.logBorrowRequestStatusChanged(requestStatus: 'accepted');

    final itemIndex = _items.indexWhere((i) => i.id == request.itemId);
    if (itemIndex != -1) {
      final item = _items[itemIndex];

      UserProfile borrowerProfile;
      try {
        borrowerProfile = availableMockUsers
            .firstWhere((u) => u.uid == request.requesterId);
      } catch (_) {
        final realProfile = await _authNotifier.authService
            .getUserProfile(request.requesterId);
        borrowerProfile = realProfile ?? currentUser!;
      }

      final meetingPointName = _requestNotifier.mutableMeetingPointProposals
          .where((p) =>
              p.requestId == requestId &&
              p.status == MeetingPointStatus.accepted)
          .map((p) => p.title)
          .firstWhere((_) => true, orElse: () => item.location);

      final updatedItem = item.copyWith(
        status: EmanetStatus.pendingApproval,
        deliveryStatus: DeliveryStatus.accepted,
        borrowerId: borrowerProfile.uid,
        borrowerName: borrowerProfile.name,
        meetingPoint: meetingPointName,
      );

      await _itemService.updateItem(updatedItem);
    }

    final message = ChatMessageModel(
      id: 'msg_sys_${DateTime.now().millisecondsSinceEpoch}',
      requestId: requestId,
      senderId: 'system',
      senderName: 'Sistem',
      text: 'Talep kabul edildi. Buluşma detaylarını konuşabilirsiniz.',
      type: ChatMessageType.requestStatusUpdate,
      createdAt: DateTime.now(),
    );
    await _requestNotifier.chatMessageService.sendChatMessage(message);

    _addLog('Ödünç talebi kabul edildi. Rota takibi açılabilir.');
  }

  // ─── Notifications ─────────────────────────────────────────────────────────
  void _setupNotifications(String userId) {
    NotificationService.instance.initialize(
      onTokenReceived: (token) {
        _currentFcmToken = token;
        _updateFcmToken(userId, token);
      },
    );
    if (_currentFcmToken != null) {
      _updateFcmToken(userId, _currentFcmToken!);
    }
  }

  void _updateFcmToken(String userId, String token) async {
    final user = _authNotifier.authService.currentUser;
    if (user != null) {
      if (!user.fcmTokens.contains(token)) {
        final updatedTokens = List<String>.from(user.fcmTokens)..add(token);
        final updatedUser = user.copyWith(fcmTokens: updatedTokens);
        _authNotifier.authService.updateUserProfile(updatedUser);
      }

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmTokens': FieldValue.arrayUnion([token])
        });
        _addLog('FCM Token veritabanıyla senkronize edildi.');
      } catch (_) {}
    }
  }

  // ─── Routing & Delivery ────────────────────────────────────────────────────
  Future<void> startRouting(String itemId) async {
    _setLoading(true);
    try {
      await _itemService.startRouting(itemId);
      _addLog('Buluşma noktasına rota başlatıldı.');
    } catch (e) {
      _addLog('Rota başlatılırken hata: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeDelivery(String itemId) async {
    _setLoading(true);
    try {
      await _itemService.completeDelivery(itemId);
      _addLog('Eşya başarıyla teslim edildi. Ödünç süresi başladı.');
    } catch (e) {
      _addLog('Eşya teslimatı yapılırken hata: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> requestReturn(String itemId) async {
    if (currentUser == null) return false;
    _setLoading(true);
    try {
      final item = _items.firstWhere((i) => i.id == itemId);
      await _itemService.requestReturn(itemId);
      _addLog(
          '${currentUser!.name}, "${item.title}" eşyasını iade etmek için talep oluşturdu.');
      return true;
    } catch (e) {
      _addLog('İade talebi hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> approveReturn(String itemId) async {
    try {
      final item = _items.firstWhere((i) => i.id == itemId);
      if (item.status != EmanetStatus.pendingReturn) {
        _addLog(
            'İade onaylama iptal edildi: Ürün iade bekleme durumunda değil (Mevcut: ${item.status.name})');
        return;
      }
      await _itemService.approveReturn(itemId);
      _addLog('"${item.title}" iadesi onaylandı ve eşya teslim alındı.');

      try {
        final borrowRequests = _requestNotifier.mutableBorrowRequests;
        final reqIndex = borrowRequests.indexWhere((r) =>
            r.itemId == itemId &&
            (r.status == BorrowRequestStatus.accepted ||
                r.status == BorrowRequestStatus.borrowed));
        if (reqIndex != -1) {
          final request = borrowRequests[reqIndex];
          await _requestNotifier.borrowRequestService
              .updateBorrowRequestStatus(
                  request.id, BorrowRequestStatus.completed);
        }
      } catch (e) {
        _addLog('Talep tamamlandı olarak güncellenirken hata: $e');
      }

      try {
        final lenderProfile =
            await _authNotifier.authService.getUserProfile(item.lenderId);
        if (lenderProfile != null) {
          final updatedLender = lenderProfile.copyWith(
            successfulLends: lenderProfile.successfulLends + 1,
          );
          await _authNotifier.authService.updateUserProfile(updatedLender);
        }

        if (item.borrowerId != null) {
          final borrowerProfile = await _authNotifier.authService
              .getUserProfile(item.borrowerId!);
          if (borrowerProfile != null) {
            final updatedBorrower = borrowerProfile.copyWith(
              successfulBorrows: borrowerProfile.successfulBorrows + 1,
            );
            await _authNotifier.authService
                .updateUserProfile(updatedBorrower);
          }
        }
      } catch (e) {
        _addLog('Kullanıcı istatistikleri güncellenirken hata: $e');
      }
    } catch (e) {
      _addLog('İade onaylama hatası: $e');
    }
  }

  // ─── Reviews ───────────────────────────────────────────────────────────────
  Future<void> addUserReview(
    String targetUserId,
    String comment,
    double ratingRating,
    String requestId,
  ) async {
    if (currentUser == null) return;

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('addReview');

      await callable.call({
        'targetUserId': targetUserId,
        'comment': comment,
        'rating': ratingRating,
        'requestId': requestId,
      });

      _addLog('Değerlendirme başarıyla gönderildi: $targetUserId');
      notifyListeners();
    } catch (e, stack) {
      _crashlyticsService.recordError(e, stack, reason: 'addUserReview failed');
      _addLog('Değerlendirme hatası: $e');
      rethrow;
    }
  }

  // ─── Auth Methods ──────────────────────────────────────────────────────────
  Future<UserProfile?> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _authNotifier.authService.signIn(email, password);
      _addLog('Giriş yapıldı: ${user?.name}');
      return user;
    } catch (e) {
      _addLog('Giriş hatası: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserProfile?> signUp(
      String email, String password, String name) async {
    _setLoading(true);
    try {
      final user =
          await _authNotifier.authService.signUp(email, password, name);
      _addLog('Yeni üye kaydedildi: ${user?.name}');
      return user;
    } catch (e) {
      _addLog('Kayıt hatası: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authNotifier.authService.signOut();
      _addLog('Oturum kapatıldı.');
    } catch (e) {
      _addLog('Çıkış hatası: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteUserAccount(String password) async {
    _setLoading(true);
    try {
      await _authNotifier.authService.reauthenticateWithPassword(password);
      _addLog('Hesap silme öncesi yeniden kimlik doğrulandı.');

      if (Firebase.apps.isNotEmpty) {
        final callable =
            FirebaseFunctions.instanceFor(region: 'europe-west1')
                .httpsCallable('requestAccountDeletion');
        await callable.call();
      }

      await _authNotifier.authService.signOut();
      _addLog('Hesap başarıyla silindi ve oturum kapatıldı.');
    } catch (e, stack) {
      _crashlyticsService.recordError(e, stack,
          reason: 'deleteUserAccount failed');
      _addLog('Hesap silme hatası: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _authNotifier.authService.sendEmailVerification();
      _addLog('E-posta doğrulama bağlantısı gönderildi.');
    } catch (e) {
      _addLog('Doğrulama maili gönderme hatası: $e');
      rethrow;
    }
  }

  bool get isEmailVerified => _authNotifier.authService.isEmailVerified;

  Future<void> reloadUser() async {
    try {
      await _authNotifier.authService.reloadUser();
      notifyListeners();
    } catch (e) {
      _addLog('Kullanıcı güncelleme hatası: $e');
    }
  }

  Future<void> setUsername(String newUsername) async {
    _setLoading(true);
    try {
      if (Firebase.apps.isNotEmpty) {
        await reloadUser();

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw FirebaseAuthException(
              code: 'unauthenticated', message: 'Oturum bulunamadı.');
        }

        final tokenResult = await user.getIdTokenResult(true);
        debugPrint(
          'Username setup auth status: uid=${user.uid}, '
          'verified=${user.emailVerified}, '
          'tokenVerified=${tokenResult.claims?['email_verified']}',
        );

        final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
            .httpsCallable('setUsername');
        final result = await callable.call({
          'username': newUsername,
        });

        final data = result.data as Map<dynamic, dynamic>;
        if (data['success'] == true) {
          _addLog('Kullanıcı adı başarıyla güncellendi: $newUsername');
        }
      } else {
        final user = currentUser;
        if (user != null) {
          final updated = user.copyWith(
            username: newUsername,
            usernameNormalized: newUsername.toLowerCase(),
            usernameSource: 'custom',
            onboardingComplete: true,
          );
          await _authNotifier.authService.updateUserProfile(updated);
        }
      }

      await reloadUser();
      notifyListeners();
    } catch (e, stack) {
      _crashlyticsService.recordError(e, stack, reason: 'setUsername failed');
      _addLog('Kullanıcı adı ayarlama hatası: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authNotifier.authService.sendPasswordResetEmail(email);
      _addLog('Şifre sıfırlama e-postası gönderildi: $email');
    } catch (e) {
      _addLog('Şifre sıfırlama hatası: $e');
      rethrow;
    }
  }

  // ─── Item Update & Delete ──────────────────────────────────────────────────
  Future<void> updateItem(EmanetItem item,
      {void Function(double progress)? onProgress}) async {
    _setLoading(true);
    try {
      EmanetItem finalItem = item;

      EmanetItem? oldItem;
      try {
        oldItem = _items.firstWhere((i) => i.id == item.id);
      } catch (_) {
        oldItem = null;
      }

      final sourcePaths = List<String>.from(item.images);
      if (sourcePaths.isEmpty &&
          item.imageUrl != null &&
          item.imageUrl!.isNotEmpty) {
        sourcePaths.add(item.imageUrl!);
      }

      final uploadedUrls = <String>[];
      if (sourcePaths.isNotEmpty) {
        final double progressScale = 1.0 / sourcePaths.length;
        for (int i = 0; i < sourcePaths.length; i++) {
          final path = sourcePaths[i];
          if (path.startsWith('http')) {
            uploadedUrls.add(path);
          } else {
            final downloadUrl = await _storageService.uploadItemImage(
              item.id,
              File(path),
              onProgress: onProgress != null
                  ? (p) => onProgress((i + p) * progressScale)
                  : null,
            );
            uploadedUrls.add(downloadUrl);
          }
        }
      }

      final oldUrls = oldItem?.images ?? [];
      final oldImageUrl = oldItem?.imageUrl;
      final allOldUrls = {
        ...oldUrls,
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) oldImageUrl,
      };

      for (final oldUrl in allOldUrls) {
        if (!uploadedUrls.contains(oldUrl)) {
          await _storageService.deleteImage(oldUrl);
        }
      }

      finalItem = item.copyWith(
        imageUrl: uploadedUrls.isNotEmpty ? uploadedUrls.first : null,
        images: uploadedUrls,
      );

      await _itemService.updateItem(finalItem);
      _addLog('İlan güncellendi: ${item.id}');
    } catch (e) {
      _addLog('İlan güncellenirken hata: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteItem(String itemId) async {
    _setLoading(true);
    try {
      final index = _items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        final item = _items[index];
        if (item.status != EmanetStatus.available &&
            item.status != EmanetStatus.archived) {
          _addLog('İlan silme engellendi: Aktif işlemdeki ilanlar silinemez.');
          return;
        }
        final allImageUrls = <String>{
          ...item.images.where((u) => u.startsWith('http')),
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            item.imageUrl!,
        };
        for (final url in allImageUrls) {
          try {
            await _storageService.deleteImage(url);
          } catch (e) {
            debugPrint(
                'Emanetly: Storage image cleanup non-fatal: $e');
          }
        }
      }
      await _itemService.deleteItem(itemId);
      _addLog('İlan silindi: $itemId');
    } catch (e) {
      _addLog('İlan silinirken hata: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleItemArchive(String itemId, bool shouldArchive) async {
    _setLoading(true);
    try {
      final index = _items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        final item = _items[index];
        final updatedItem = item.copyWith(
          status:
              shouldArchive ? EmanetStatus.archived : EmanetStatus.available,
        );
        await _itemService.updateItem(updatedItem);
        _addLog('İlan arşiv durumu güncellendi: $shouldArchive');
      }
    } catch (e) {
      _addLog('İlan arşivlenirken hata: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ─── Profile ───────────────────────────────────────────────────────────────
  Future<void> updateUserProfilePhoto(File imageFile,
      {void Function(double progress)? onProgress}) async {
    final user = currentUser;
    if (user == null) return;

    final downloadUrl = await _storageService.uploadProfileImage(user.uid,
        imageFile, onProgress: onProgress);

    final oldAvatarUrl = user.avatarUrl;

    final updatedProfile = user.copyWith(avatarUrl: downloadUrl);

    await _authNotifier.authService.updateUserProfile(updatedProfile);

    if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
      await _storageService.deleteImage(oldAvatarUrl);
    }

    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String bio,
    required String department,
  }) async {
    final user = currentUser;
    if (user == null) return;

    _setLoading(true);
    try {
      final updated = user.copyWith(
        name: name.trim(),
        bio: bio.trim(),
        department: department.trim(),
      );
      await _authNotifier.authService.updateUserProfile(updated);
      _addLog('Profil başarıyla güncellendi.');
      notifyListeners();
    } catch (e, stack) {
      _crashlyticsService.recordError(e, stack,
          reason: 'updateProfile failed');
      _addLog('Profil güncelleme hatası: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Pre-Agreement Mocks ───────────────────────────────────────────────────
  // (Starting with empty mock data for clean prototype testing)

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authNotifier.dispose();
    _itemNotifier.dispose();
    _requestNotifier.dispose();
    super.dispose();
  }
}
