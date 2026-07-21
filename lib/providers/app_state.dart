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
import '../services/qr_service.dart';
import '../services/borrow_request_service.dart';
import '../services/chat_message_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

enum ViewMode {
  compactGrid,
  standardGrid,
  largeCards;
}

class AppState extends ChangeNotifier {
  final AuthService _authService;
  final ItemService _itemService;
  final QrService _qrService;
  final BorrowRequestService _borrowRequestService;
  final ChatMessageService _chatMessageService;
  final StorageService _storageService;

  List<EmanetItem> _items = [];
  bool _isLoading = false;
  final List<String> _activityLogs = [];
  
  // Theme and customization settings
  ThemeMode _themeMode = ThemeMode.system;
  int _selectedPaletteIndex = 0;
  ViewMode _gridViewMode = ViewMode.standardGrid;
  final Set<String> _favoriteItemIds = {};
  final Set<String> _blockedUserIds = {};

  // Pre-agreement negotiation collections
  final List<BorrowRequestModel> _borrowRequests = [];
  final List<ChatMessageModel> _chatMessages = [];
  final List<MeetingPointProposalModel> _meetingPointProposals = [];

  StreamSubscription<UserProfile?>? _authSubscription;
  StreamSubscription<List<EmanetItem>>? _itemsSubscription;
  StreamSubscription<List<BorrowRequestModel>>? _requestsSubscription;
  StreamSubscription<List<ChatMessageModel>>? _chatSubscription;

  AppState({
    required AuthService authService,
    required ItemService itemService,
    required QrService qrService,
    required BorrowRequestService borrowRequestService,
    required ChatMessageService chatMessageService,
    required StorageService storageService,
  })  : _authService = authService,
        _itemService = itemService,
        _qrService = qrService,
        _borrowRequestService = borrowRequestService,
        _chatMessageService = chatMessageService,
        _storageService = storageService {
    
    // Listen to Auth State changes
    _authSubscription = _authService.onAuthStateChanged.listen((user) {
      if (user != null) {
        _startRequestsSubscription(user.uid);
        _setupNotifications(user.uid);
      } else {
        _cancelRequestsSubscription();
      }
      notifyListeners();
    });

    // Handle initial state if user is already logged in on startup
    final initialUser = _authService.currentUser;
    if (initialUser != null) {
      _startRequestsSubscription(initialUser.uid);
      _setupNotifications(initialUser.uid);
    }

    // Listen to Items changes
    _itemsSubscription = _itemService.onItemsChanged.listen((newItems) {
      _items = newItems;
      notifyListeners();
    });

    // Listen to Chat Messages changes globally
    _chatSubscription = _chatMessageService.listenToAllChatMessages().listen((newMessages) {
      _chatMessages.clear();
      _chatMessages.addAll(newMessages);
      notifyListeners();
    });

    // Initialize list
    _loadInitialData();
    _initPreAgreementMocks();
  }

  // Getters
  List<EmanetItem> get items => _items;
  UserProfile? get currentUser => _authService.currentUser;
  bool get isLoading => _isLoading;
  List<String> get activityLogs => List.unmodifiable(_activityLogs.reversed);
  
  ThemeMode get themeMode => _themeMode;
  int get selectedPaletteIndex => _selectedPaletteIndex;
  ViewMode get gridViewMode => _gridViewMode;
  Set<String> get favoriteItemIds => _favoriteItemIds;

  List<UserProfile> get availableMockUsers => _authService.availableMockUsers;

  AuthService get authService => _authService;
  ItemService get itemService => _itemService;
  QrService get qrService => _qrService;

  void _loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _itemService.getItems();
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
      _items = await _itemService.getItems();
      if (currentUser != null) {
        await _authService.reloadUser();
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

  // Theme, Palette, View Preferences changes
  void changeThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _addLog('Tema modu değiştirildi: ${mode.name}');
    notifyListeners();
  }

  void changePalette(int index) {
    _selectedPaletteIndex = index;
    _addLog('Renk paleti değiştirildi: İndeks $index');
    notifyListeners();
  }

  void changeViewMode(ViewMode mode) {
    _gridViewMode = mode;
    _addLog('Görünüm modu değiştirildi: ${mode.name}');
    notifyListeners();
  }

  // Blocked users logic
  bool isUserBlocked(String uid) {
    return _blockedUserIds.contains(uid);
  }

  void toggleBlockUser(String uid) {
    if (_blockedUserIds.contains(uid)) {
      _blockedUserIds.remove(uid);
      _addLog('Kullanıcı engeli kaldırıldı: $uid');
    } else {
      _blockedUserIds.add(uid);
      _addLog('Kullanıcı engellendi: $uid');
    }
    notifyListeners();
  }

  // Favorites logic
  bool isFavorite(String itemId) {
    if (currentUser != null) {
      return currentUser!.favoriteItemIds.contains(itemId);
    }
    return _favoriteItemIds.contains(itemId);
  }

  void toggleFavorite(String itemId) async {
    if (currentUser != null) {
      final user = currentUser!;
      final bool isAlreadyFav = user.favoriteItemIds.contains(itemId);
      
      // Perform atomic toggle via service
      await _authService.toggleFavorite(user.uid, itemId, !isAlreadyFav);
      
      if (isAlreadyFav) {
        _addLog('Ürün favorilerden çıkarıldı: $itemId');
      } else {
        _addLog('Ürün favorilere eklendi: $itemId');
      }
      notifyListeners();
    } else {
      // Offline / Fallback mode
      if (_favoriteItemIds.contains(itemId)) {
        _favoriteItemIds.remove(itemId);
        _addLog('Ürün favorilerden çıkarıldı: $itemId');
      } else {
        _favoriteItemIds.add(itemId);
        _addLog('Ürün favorilere eklendi: $itemId');
      }
      notifyListeners();
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    return _authService.getUserProfile(uid);
  }

  // Swap users for prototype testing
  void switchUser(String uid) {
    final service = _authService;
    if (service is MockAuthService) {
      service.switchUser(uid);
      _addLog('Aktif kullanıcı değiştirildi: ${currentUser?.name}');
    }
  }

  // Add a new item listing
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
    try {
      final itemId = 'item_${DateTime.now().millisecondsSinceEpoch}';
      
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
            final downloadUrl = await _storageService.uploadItemImage(
              itemId,
              File(path),
              onProgress: onProgress != null
                  ? (p) => onProgress((i + p) * progressScale)
                  : null,
            );
            uploadedUrls.add(downloadUrl);
          }
        }
      }

      // Pick a random mock color for the grid photo placeholders if not selected
      final colorOptions = [0xFF3B82F6, 0xFFEF4444, 0xFFF59E0B, 0xFF10B981, 0xFF8B5CF6, 0xFFEC4899];
      final finalColor = mockColorValue ?? colorOptions[DateTime.now().millisecond % colorOptions.length];

      final newItem = EmanetItem(
        id: itemId,
        title: title,
        description: description,
        category: category,
        lenderId: currentUser!.uid,
        lenderName: currentUser!.name,
        location: location,
        imageUrl: uploadedUrls.isNotEmpty ? uploadedUrls.first : null,
        images: uploadedUrls,
        status: EmanetStatus.available,
        createdAt: DateTime.now(),
        comments: [],
        mockImageColorValue: finalColor,
      );
      await _itemService.addItem(newItem);
      _addLog('${currentUser!.name}, yeni bir ilan yayınladı: "$title"');
      return true;
    } catch (e) {
      _addLog('Eşya eklenirken hata: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Request to borrow an item (Creates pre-agreement discussion chat flow or inquiry)
  Future<BorrowRequestModel?> requestBorrow(
    String itemId, {
    bool isOfficialRequest = true,
    String requestedDurationText = 'Belirtilmedi',
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
        requestedDurationText: requestedDurationText,
        createdAt: DateTime.now(),
      );

      await _borrowRequestService.addBorrowRequest(newRequest);

      // System message
      await _chatMessageService.sendChatMessage(ChatMessageModel(
        id: 'msg_sys_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        senderId: 'system',
        senderName: 'Sistem',
        text: isOfficialRequest 
            ? 'Ödünç talebi oluşturuldu: Görüşme aşamasında (Süre: $requestedDurationText).'
            : 'Eşya hakkında soru soruldu: Bilgi alınıyor.',
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

  // Upgrade inquiry to official borrow request
  Future<void> upgradeToOfficialRequest(String requestId, {required String requestedDurationText}) async {
    _setLoading(true);
    try {
      final index = _borrowRequests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        final req = _borrowRequests[index];
        final updatedReq = req.copyWith(
          status: BorrowRequestStatus.pendingDiscussion,
          requestedDurationText: requestedDurationText,
        );
        
        await _borrowRequestService.addBorrowRequest(updatedReq);
        
        // Add a system message in the chat
        await _chatMessageService.sendChatMessage(ChatMessageModel(
          id: 'msg_sys_${DateTime.now().millisecondsSinceEpoch}',
          requestId: requestId,
          senderId: 'system',
          senderName: 'Sistem',
          text: 'Kullanıcı ödünç alma talebi gönderdi (Süre: $requestedDurationText).',
          type: ChatMessageType.system,
          createdAt: DateTime.now(),
        ));
        
        _addLog('Ödünç talebi resmiyete döküldü.');
        notifyListeners();
      }
    } catch (e) {
      _addLog('Talep resmiyete dökülürken hata: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Approve borrow request
  Future<void> approveBorrow(String itemId) async {
    try {
      final item = _items.firstWhere((i) => i.id == itemId);
      await _itemService.approveBorrow(itemId);
      _addLog('"${item.title}" talebi onaylandı. Buluşma noktası belirlenmesi bekleniyor.');
    } catch (e) {
      _addLog('Talep onaylama hatası: $e');
    }
  }

  // Reject borrow request
  Future<void> rejectBorrow(String itemId) async {
    try {
      final item = _items.firstWhere((i) => i.id == itemId);
      await _itemService.rejectBorrow(itemId);
      _addLog('"${item.title}" ödünç talebi reddedildi.');
    } catch (e) {
      _addLog('Talep reddetme hatası: $e');
    }
  }

  // Set Meeting Point & Additional Note
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

  Future<void> updateMeetingDetails(String itemId, String location, String note) async {
    _setLoading(true);
    try {
      final combined = note.isNotEmpty ? '$location | Not: $note' : location;
      await _itemService.setMeetingPoint(itemId, combined);
      
      final activeReq = getRequestForActiveItem(itemId);
      if (activeReq != null) {
        await _borrowRequestService.updateMeetingDetails(activeReq.id, location, note);
      }
      _addLog('Buluşma detayları kaydedildi: $location ($note)');
    } catch (e) {
      _addLog('Buluşma detayları kaydedilirken hata: $e');
    } finally {
      _setLoading(false);
    }
  }

  String? _currentFcmToken;

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

  void _updateFcmToken(String userId, String token) {
    final user = _authService.currentUser;
    if (user != null && !user.fcmTokens.contains(token)) {
      final updatedTokens = List<String>.from(user.fcmTokens)..add(token);
      final updatedUser = user.copyWith(fcmTokens: updatedTokens);
      _authService.updateUserProfile(updatedUser);
      _addLog('FCM Token kaydedildi.');
    }
  }

  // Start Routing
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

  // Complete Delivery (Marks as borrowed and sets progress status)
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

  // Request return of the item
  Future<bool> requestReturn(String itemId) async {
    if (currentUser == null) return false;
    _setLoading(true);
    try {
      final item = _items.firstWhere((i) => i.id == itemId);
      await _itemService.requestReturn(itemId);
      _addLog('${currentUser!.name}, "${item.title}" eşyasını iade etmek için talep oluşturdu.');
      return true;
    } catch (e) {
      _addLog('İade talebi hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Approve return of the item
  Future<void> approveReturn(String itemId) async {
    try {
      final item = _items.firstWhere((i) => i.id == itemId);
      if (item.status != EmanetStatus.pendingReturn) {
        _addLog('İade onaylama iptal edildi: Ürün iade bekleme durumunda değil (Mevcut: ${item.status.name})');
        return;
      }
      await _itemService.approveReturn(itemId);
      _addLog('"${item.title}" iadesi onaylandı ve eşya teslim alındı.');

      // Mark the corresponding accepted borrow request as completed in Firestore
      try {
        final reqIndex = _borrowRequests.indexWhere(
          (r) => r.itemId == itemId && r.status == BorrowRequestStatus.accepted
        );
        if (reqIndex != -1) {
          final request = _borrowRequests[reqIndex];
          await _borrowRequestService.updateBorrowRequestStatus(request.id, BorrowRequestStatus.completed);
        }
      } catch (e) {
        _addLog('Talep tamamlandı olarak güncellenirken hata: $e');
      }

      // Increment statistics for lender (current user) and borrower in Firestore
      try {
        final lenderProfile = await _authService.getUserProfile(item.lenderId);
        if (lenderProfile != null) {
          final updatedLender = lenderProfile.copyWith(
            successfulLends: lenderProfile.successfulLends + 1,
          );
          await _authService.updateUserProfile(updatedLender);
        }

        if (item.borrowerId != null) {
          final borrowerProfile = await _authService.getUserProfile(item.borrowerId!);
          if (borrowerProfile != null) {
            final updatedBorrower = borrowerProfile.copyWith(
              successfulBorrows: borrowerProfile.successfulBorrows + 1,
            );
            await _authService.updateUserProfile(updatedBorrower);
          }
        }
      } catch (e) {
        _addLog('Kullanıcı istatistikleri güncellenirken hata: $e');
      }
    } catch (e) {
      _addLog('İade onaylama hatası: $e');
    }
  }

  // Handle QR Scan Verification
  Future<String?> processQrCode(String qrCodeData) async {
    _setLoading(true);
    try {
      final result = await _qrService.scanQrCode(qrCodeData);
      if (result == null) {
        return 'QR Kod ayrıştırılamadı veya geçersiz format.';
      }

      // 1. Request gerçekten var mı
      final reqIndex = _borrowRequests.indexWhere((r) => r.id == result.requestId);
      if (reqIndex == -1) {
        return 'İlgili ödünç talebi bulunamadı.';
      }
      final request = _borrowRequests[reqIndex];
      
      // Find matching item details
      final itemIndex = _items.indexWhere((i) => i.id == request.itemId);
      if (itemIndex == -1) {
        return 'İlgili ilan bulunamadı.';
      }
      final item = _items[itemIndex];

      // 2. Süre koruması (5 dakika geçerlilik)
      final now = DateTime.now().millisecondsSinceEpoch;
      final differenceSeconds = (now - result.timestamp) / 1000;
      if (differenceSeconds < 0 || differenceSeconds > 300) {
        return 'Bu QR kodun süresi dolmuş. Lütfen yeni bir kod oluşturup tekrar deneyin.';
      }

      // 3. Doğru kullanıcı mı (tarayan kişi kim olmalı?)
      if (currentUser == null) {
        return 'Doğrulama için lütfen giriş yapın.';
      }
      
      if (result.isBorrow) {
        // Alıcı, vericinin QR'ını tarar. Tarayan kişi alıcı (requester) olmalı.
        if (currentUser!.uid != request.requesterId) {
          return 'Bu işlem sadece ödünç alan kullanıcı tarafından onaylanabilir.';
        }
        
        // 4. Beklenen durumda mı & işlem daha önce tamamlanmış mı (Tekrar Okutma Koruması)
        if (item.status == EmanetStatus.borrowed || item.deliveryStatus == DeliveryStatus.completed) {
          return 'Bu işlem zaten tamamlandı.';
        }
        if (item.status != EmanetStatus.pendingApproval || item.deliveryStatus != DeliveryStatus.routingStarted) {
          return 'Eşya henüz teslim aşamasına gelmemiş veya durum uyumsuz.';
        }

        // Teslimatı tamamla
        await _itemService.completeDelivery(item.id);
        _addLog('QR Kod doğrulandı: Ödünç teslimatı tamamlandı.');
        return null; // Başarılı
      } else if (result.isReturn) {
        // Verici, alıcının QR'ını tarar. Tarayan kişi verici (owner) olmalı.
        if (currentUser!.uid != request.ownerId) {
          return 'Bu işlem sadece eşya sahibi tarafından onaylanabilir.';
        }

        // 4. Beklenen durumda mı & işlem daha önce tamamlanmış mı (Tekrar Okutma Koruması)
        if (item.status == EmanetStatus.available) {
          return 'Bu işlem zaten tamamlandı.';
        }
        if (item.status != EmanetStatus.pendingReturn) {
          return 'Eşya iade bekleme durumunda değil.';
        }

        // İadeyi tamamla
        await approveReturn(item.id);
        _addLog('QR Kod doğrulandı: İade alma işlemi onaylandı.');
        return null; // Başarılı
      }
      
      return 'Bilinmeyen işlem türü.';
    } catch (e) {
      _addLog('QR Okuma Hatası: $e');
      return 'QR okuma işlemi sırasında hata oluştu: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Pre-Agreement Chat and Proposal Getters
  List<BorrowRequestModel> get borrowRequests => _borrowRequests;
  
  List<ChatMessageModel> getChatMessagesForRequest(String requestId) {
    return _chatMessages.where((msg) => msg.requestId == requestId).toList();
  }

  int getUnreadCountForRequest(String requestId) {
    if (currentUser == null) return 0;
    return _chatMessages.where((msg) =>
      msg.requestId == requestId &&
      msg.senderId != currentUser!.uid &&
      !msg.isRead
    ).length;
  }

  int get totalUnreadCount {
    if (currentUser == null) return 0;
    return _chatMessages.where((msg) =>
      msg.senderId != currentUser!.uid &&
      !msg.isRead
    ).length;
  }
  
  MeetingPointProposalModel? getProposal(String proposalId) {
    try {
      return _meetingPointProposals.firstWhere((p) => p.id == proposalId);
    } catch (_) {
      return null;
    }
  }

  BorrowRequestModel? getRequestForActiveItem(String itemId) {
    try {
      return _borrowRequests.firstWhere(
        (req) => req.itemId == itemId &&
                 req.status != BorrowRequestStatus.rejected &&
                 req.status != BorrowRequestStatus.cancelled &&
                 req.status != BorrowRequestStatus.expired &&
                 req.status != BorrowRequestStatus.completed
      );
    } catch (_) {
      return null;
    }
  }

  // Pre-Agreement Actions
  Future<void> sendChatMessage(String requestId, String text) async {
    if (currentUser == null) return;
    final message = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      requestId: requestId,
      senderId: currentUser!.uid,
      senderName: currentUser!.name,
      text: text,
      type: ChatMessageType.text,
      createdAt: DateTime.now(),
    );
    await _chatMessageService.sendChatMessage(message);
    _addLog('Mesaj gönderildi: "$text"');
  }

  Future<void> markMessagesAsRead(String requestId) async {
    if (currentUser == null) return;
    
    // Yerel mesajları anında okundu yaparak arayüzün anlık tepki vermesini sağlıyoruz
    var localUpdated = false;
    for (var i = 0; i < _chatMessages.length; i++) {
      final msg = _chatMessages[i];
      if (msg.requestId == requestId && msg.senderId != currentUser!.uid && !msg.isRead) {
        _chatMessages[i] = ChatMessageModel(
          id: msg.id,
          requestId: msg.requestId,
          senderId: msg.senderId,
          senderName: msg.senderName,
          text: msg.text,
          type: msg.type,
          createdAt: msg.createdAt,
          customPayload: msg.customPayload,
          isRead: true,
        );
        localUpdated = true;
      }
    }
    if (localUpdated) {
      notifyListeners();
    }
    
    await _chatMessageService.markMessagesAsRead(requestId, currentUser!.uid);
  }

  Future<void> proposeMeetingPoint(String requestId, String title, String addressText, String timeText) async {
    if (currentUser == null) return;
    
    final proposalId = 'prop_${DateTime.now().millisecondsSinceEpoch}';
    final requestIndex = _borrowRequests.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) return;
    final request = _borrowRequests[requestIndex];

    final isOwner = currentUser!.uid == request.ownerId;

    final proposal = MeetingPointProposalModel(
      id: proposalId,
      requestId: requestId,
      proposedByUserId: currentUser!.uid,
      title: title,
      addressText: addressText,
      proposedTimeText: timeText,
      status: MeetingPointStatus.pending,
      acceptedByOwner: isOwner,
      acceptedByRequester: !isOwner,
    );

    _meetingPointProposals.add(proposal);
    _borrowRequests[requestIndex] = request.copyWith(proposedMeetingPointId: proposalId);

    // Add proposal card as a system message in conversation
    final message = ChatMessageModel(
      id: 'msg_sys_${DateTime.now().millisecondsSinceEpoch}',
      requestId: requestId,
      senderId: 'system',
      senderName: 'Sistem',
      text: 'Buluşma noktası önerildi: $title ($timeText)',
      type: ChatMessageType.meetingPointProposal,
      createdAt: DateTime.now(),
      customPayload: proposalId,
    );
    await _chatMessageService.sendChatMessage(message);

    _addLog('Yeni buluşma noktası önerildi: $title');
  }

  Future<void> acceptMeetingPoint(String proposalId) async {
    final propIndex = _meetingPointProposals.indexWhere((p) => p.id == proposalId);
    if (propIndex == -1) return;
    final proposal = _meetingPointProposals[propIndex];

    _meetingPointProposals[propIndex] = proposal.copyWith(
      acceptedByOwner: true,
      acceptedByRequester: true,
      status: MeetingPointStatus.accepted,
    );

    // Add system message
    final message = ChatMessageModel(
      id: 'msg_sys_${DateTime.now().millisecondsSinceEpoch}',
      requestId: proposal.requestId,
      senderId: 'system',
      senderName: 'Sistem',
      text: 'Buluşma noktası onaylandı: ${proposal.title}',
      type: ChatMessageType.system,
      createdAt: DateTime.now(),
    );
    await _chatMessageService.sendChatMessage(message);

    _addLog('Buluşma noktası onaylandı: ${proposal.title}');
  }

  Future<void> rejectMeetingPoint(String proposalId) async {
    final propIndex = _meetingPointProposals.indexWhere((p) => p.id == proposalId);
    if (propIndex == -1) return;
    final proposal = _meetingPointProposals[propIndex];

    _meetingPointProposals[propIndex] = proposal.copyWith(
      status: MeetingPointStatus.rejected,
    );

    // Add system message
    final message = ChatMessageModel(
      id: 'msg_sys_${DateTime.now().millisecondsSinceEpoch}',
      requestId: proposal.requestId,
      senderId: 'system',
      senderName: 'Sistem',
      text: 'Buluşma noktası reddedildi: ${proposal.title}',
      type: ChatMessageType.system,
      createdAt: DateTime.now(),
    );
    await _chatMessageService.sendChatMessage(message);

    _addLog('Buluşma noktası reddedildi: ${proposal.title}');
  }

  void acceptBorrowRequest(String requestId) async {
    final reqIndex = _borrowRequests.indexWhere((r) => r.id == requestId);
    if (reqIndex == -1) return;
    final request = _borrowRequests[reqIndex];

    await _borrowRequestService.updateBorrowRequestStatus(requestId, BorrowRequestStatus.accepted);

    // Update item status in ItemService
    final itemIndex = _items.indexWhere((i) => i.id == request.itemId);
    if (itemIndex != -1) {
      final item = _items[itemIndex];
      
      UserProfile borrowerProfile;
      try {
        borrowerProfile = availableMockUsers.firstWhere((u) => u.uid == request.requesterId);
      } catch (_) {
        final realProfile = await _authService.getUserProfile(request.requesterId);
        borrowerProfile = realProfile ?? currentUser!;
      }
      
      final meetingPointName = _meetingPointProposals
          .where((p) => p.requestId == requestId && p.status == MeetingPointStatus.accepted)
          .map((p) => p.title)
          .firstWhere((_) => true, orElse: () => item.location);

      final updatedItem = item.copyWith(
        status: EmanetStatus.pendingApproval,
        deliveryStatus: DeliveryStatus.accepted,
        borrowerId: borrowerProfile.uid,
        borrowerName: borrowerProfile.name,
        meetingPoint: meetingPointName,
      );

      // Save item changes via service
      await _itemService.updateItem(updatedItem);
    }

    // Add system message
    final message = ChatMessageModel(
      id: 'msg_sys_${DateTime.now().millisecondsSinceEpoch}',
      requestId: requestId,
      senderId: 'system',
      senderName: 'Sistem',
      text: 'Talep kabul edildi. Teslimat süreci başladı!',
      type: ChatMessageType.requestStatusUpdate,
      createdAt: DateTime.now(),
    );
    await _chatMessageService.sendChatMessage(message);

    _addLog('Ödünç talebi kabul edildi. Rota takibi açılabilir.');
  }

  void rejectBorrowRequest(String requestId) async {
    final reqIndex = _borrowRequests.indexWhere((r) => r.id == requestId);
    if (reqIndex == -1) return;

    await _borrowRequestService.updateBorrowRequestStatus(requestId, BorrowRequestStatus.rejected);

    // Add system message
    final message = ChatMessageModel(
      id: 'msg_sys_${DateTime.now().millisecondsSinceEpoch}',
      requestId: requestId,
      senderId: 'system',
      senderName: 'Sistem',
      text: 'Talep reddedildi. Görüşme sonlandırıldı.',
      type: ChatMessageType.requestStatusUpdate,
      createdAt: DateTime.now(),
    );
    await _chatMessageService.sendChatMessage(message);

    _addLog('Ödünç talebi reddedildi.');
  }

  Future<void> addUserReview(String targetUserId, String comment, double ratingRating, String requestId) async {
    if (currentUser == null) return;
    
    final review = UserReview(
      authorName: currentUser!.name,
      rating: ratingRating.toStringAsFixed(1),
      comment: comment,
      dateText: 'Bugün',
      requestId: requestId,
    );

    await _authService.addReviewToUser(targetUserId, review);
    notifyListeners();
  }

  // Wrapper Authentication Methods for the entire application
  Future<UserProfile?> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _authService.signIn(email, password);
      _addLog('Giriş yapıldı: ${user?.name}');
      return user;
    } catch (e) {
      _addLog('Giriş hatası: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserProfile?> signUp(String email, String password, String name) async {
    _setLoading(true);
    try {
      final user = await _authService.signUp(email, password, name);
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
      await _authService.signOut();
      _addLog('Oturum kapatıldı.');
    } catch (e) {
      _addLog('Çıkış hatası: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
      _addLog('E-posta doğrulama bağlantısı gönderildi.');
    } catch (e) {
      _addLog('Doğrulama maili gönderme hatası: $e');
      rethrow;
    }
  }

  bool get isEmailVerified => _authService.isEmailVerified;

  Future<void> reloadUser() async {
    try {
      await _authService.reloadUser();
      notifyListeners();
    } catch (e) {
      _addLog('Kullanıcı güncelleme hatası: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      _addLog('Şifre sıfırlama e-postası gönderildi: $email');
    } catch (e) {
      _addLog('Şifre sıfırlama hatası: $e');
      rethrow;
    }
  }

  Future<void> updateItem(EmanetItem item, {void Function(double progress)? onProgress}) async {
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
      if (sourcePaths.isEmpty && item.imageUrl != null && item.imageUrl!.isNotEmpty) {
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

      // Garbage Collection: Delete old remote images that are no longer in the updated list
      final oldUrls = oldItem?.images ?? [];
      final oldImageUrl = oldItem?.imageUrl;
      final allOldUrls = {...oldUrls, if (oldImageUrl != null && oldImageUrl.isNotEmpty) oldImageUrl};

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
        if (item.status != EmanetStatus.available && item.status != EmanetStatus.archived) {
          _addLog('İlan silme engellendi: Aktif işlemdeki ilanlar silinemez.');
          return;
        }
        // İlan silinirken Storage'daki görseli de temizliyoruz
        if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
          await _storageService.deleteImage(item.imageUrl!);
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
          status: shouldArchive ? EmanetStatus.archived : EmanetStatus.available,
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

  // Pre-Agreement Mocks Initializer
  void _initPreAgreementMocks() {
    // Starting with empty mock data for clean prototype testing as requested.
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _startRequestsSubscription(String userId) {
    _requestsSubscription?.cancel();
    _requestsSubscription = _borrowRequestService.listenToBorrowRequests(userId).listen((newRequests) {
      _borrowRequests.clear();
      _borrowRequests.addAll(newRequests);
      notifyListeners();
    }, onError: (e) {
      _addLog('Talep verisi dinleme hatası: $e');
    });
  }

  void _cancelRequestsSubscription() {
    _requestsSubscription?.cancel();
    _requestsSubscription = null;
    _borrowRequests.clear();
  }

  StorageService get storageService => _storageService;

  Future<void> updateUserProfilePhoto(File imageFile, {void Function(double progress)? onProgress}) async {
    final user = currentUser;
    if (user == null) return;
    
    // Upload profile image to storage
    final downloadUrl = await _storageService.uploadProfileImage(user.uid, imageFile, onProgress: onProgress);
    
    // Keep reference to old photo
    final oldAvatarUrl = user.avatarUrl;
    
    // Create updated profile
    final updatedProfile = user.copyWith(avatarUrl: downloadUrl);
    
    // Update profile in Firestore/AuthService
    await _authService.updateUserProfile(updatedProfile);
    
    // If update is successful and there was an old photo, delete it from Storage
    if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
      await _storageService.deleteImage(oldAvatarUrl);
    }
    
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _itemsSubscription?.cancel();
    _requestsSubscription?.cancel();
    _chatSubscription?.cancel();
    super.dispose();
  }
}
