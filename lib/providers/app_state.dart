import 'dart:async';
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/user_profile.dart';
import '../models/borrow_request.dart';
import '../models/chat_message.dart';
import '../models/meeting_point_proposal.dart';
import '../services/auth_service.dart';
import '../services/item_service.dart';
import '../services/qr_service.dart';

enum ViewMode {
  compactGrid,
  standardGrid,
  largeCards;
}

class AppState extends ChangeNotifier {
  final AuthService _authService;
  final ItemService _itemService;
  final QrService _qrService;

  List<EmanetItem> _items = [];
  bool _isLoading = false;
  final List<String> _activityLogs = [];
  
  // Theme and customization settings
  ThemeMode _themeMode = ThemeMode.system;
  int _selectedPaletteIndex = 0;
  ViewMode _gridViewMode = ViewMode.standardGrid;
  final Set<String> _favoriteItemIds = {};

  // Pre-agreement negotiation collections
  final List<BorrowRequestModel> _borrowRequests = [];
  final List<ChatMessageModel> _chatMessages = [];
  final List<MeetingPointProposalModel> _meetingPointProposals = [];

  StreamSubscription<UserProfile?>? _authSubscription;
  StreamSubscription<List<EmanetItem>>? _itemsSubscription;

  AppState({
    required AuthService authService,
    required ItemService itemService,
    required QrService qrService,
  })  : _authService = authService,
        _itemService = itemService,
        _qrService = qrService {
    
    // Listen to Auth State changes
    _authSubscription = _authService.onAuthStateChanged.listen((user) {
      notifyListeners();
    });

    // Listen to Items changes
    _itemsSubscription = _itemService.onItemsChanged.listen((newItems) {
      _items = newItems;
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

  List<UserProfile> get availableMockUsers {
    final service = _authService;
    if (service is MockAuthService) {
      return service.availableMockUsers;
    }
    return [];
  }

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

  // Favorites logic
  bool isFavorite(String itemId) => _favoriteItemIds.contains(itemId);

  void toggleFavorite(String itemId) {
    if (_favoriteItemIds.contains(itemId)) {
      _favoriteItemIds.remove(itemId);
      _addLog('Ürün favorilerden çıkarıldı: $itemId');
    } else {
      _favoriteItemIds.add(itemId);
      _addLog('Ürün favorilere eklendi: $itemId');
    }
    notifyListeners();
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
    int? mockColorValue,
  }) async {
    if (currentUser == null) return false;
    _setLoading(true);
    try {
      // Pick a random mock color for the grid photo placeholders if not selected
      final colorOptions = [0xFF3B82F6, 0xFFEF4444, 0xFFF59E0B, 0xFF10B981, 0xFF8B5CF6, 0xFFEC4899];
      final finalColor = mockColorValue ?? colorOptions[DateTime.now().millisecond % colorOptions.length];

      final newItem = EmanetItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
        category: category,
        lenderId: currentUser!.uid,
        lenderName: currentUser!.name,
        location: location,
        imageUrl: imageUrl,
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

      _borrowRequests.add(newRequest);

      // System message
      _chatMessages.add(ChatMessageModel(
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
        _borrowRequests[index] = req.copyWith(
          status: BorrowRequestStatus.pendingDiscussion,
          requestedDurationText: requestedDurationText,
        );
        
        // Add a system message in the chat
        _chatMessages.add(ChatMessageModel(
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

  // Set Meeting Point
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
      await _itemService.approveReturn(itemId);
      _addLog('"${item.title}" iadesi onaylandı ve eşya teslim alındı.');
    } catch (e) {
      _addLog('İade onaylama hatası: $e');
    }
  }

  // Handle Mock QR Scan
  Future<bool> processQrCode(String qrCodeData) async {
    _setLoading(true);
    try {
      final result = await _qrService.scanQrCode(qrCodeData);
      if (result != null) {
        if (result.isBorrow) {
          // If action is borrow, let's complete delivery
          await _itemService.completeDelivery(result.itemId);
          _addLog('QR Kod doğrulandı: Ödünç teslimatı tamamlandı.');
        } else if (result.isReturn) {
          // If action is return, approve return
          await _itemService.approveReturn(result.itemId);
          _addLog('QR Kod doğrulandı: İade alma işlemi onaylandı.');
        }
        return true;
      }
      return false;
    } catch (e) {
      _addLog('QR Okuma Hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Pre-Agreement Chat and Proposal Getters
  List<BorrowRequestModel> get borrowRequests => _borrowRequests;
  
  List<ChatMessageModel> getChatMessagesForRequest(String requestId) {
    return _chatMessages.where((msg) => msg.requestId == requestId).toList();
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
      return _borrowRequests.firstWhere((req) => req.itemId == itemId);
    } catch (_) {
      return null;
    }
  }

  // Pre-Agreement Actions
  void sendChatMessage(String requestId, String text) {
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
    _chatMessages.add(message);
    _addLog('Mesaj gönderildi: "$text"');
    notifyListeners();
  }

  void proposeMeetingPoint(String requestId, String title, String addressText, String timeText) {
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
    _chatMessages.add(message);

    _addLog('Yeni buluşma noktası önerildi: $title');
    notifyListeners();
  }

  void acceptMeetingPoint(String proposalId) {
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
    _chatMessages.add(message);

    _addLog('Buluşma noktası onaylandı: ${proposal.title}');
    notifyListeners();
  }

  void rejectMeetingPoint(String proposalId) {
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
    _chatMessages.add(message);

    _addLog('Buluşma noktası reddedildi: ${proposal.title}');
    notifyListeners();
  }

  void acceptBorrowRequest(String requestId) {
    final reqIndex = _borrowRequests.indexWhere((r) => r.id == requestId);
    if (reqIndex == -1) return;
    final request = _borrowRequests[reqIndex];

    _borrowRequests[reqIndex] = request.copyWith(status: BorrowRequestStatus.accepted);

    // Update item status in ItemService
    final itemIndex = _items.indexWhere((i) => i.id == request.itemId);
    if (itemIndex != -1) {
      final item = _items[itemIndex];
      
      // Seed details to make it ready for mock routing
      UserProfile borrowerProfile;
      try {
        borrowerProfile = availableMockUsers.firstWhere((u) => u.uid == request.requesterId);
      } catch (_) {
        borrowerProfile = currentUser!;
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

      // Save item changes locally
      final mockService = _itemService;
      if (mockService is MockItemService) {
        final index = mockService.items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          mockService.items[index] = updatedItem;
        }
      }
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
    _chatMessages.add(message);

    _addLog('Ödünç talebi kabul edildi. Rota takibi açılabilir.');
    notifyListeners();
  }

  void rejectBorrowRequest(String requestId) {
    final reqIndex = _borrowRequests.indexWhere((r) => r.id == requestId);
    if (reqIndex == -1) return;
    final request = _borrowRequests[reqIndex];

    _borrowRequests[reqIndex] = request.copyWith(status: BorrowRequestStatus.rejected);

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
    _chatMessages.add(message);

    _addLog('Ödünç talebi reddedildi.');
    notifyListeners();
  }

  void addUserReview(String targetUserId, String comment, double ratingRating) {
    if (currentUser == null) return;
    
    final review = UserReview(
      authorName: currentUser!.name,
      rating: ratingRating.toStringAsFixed(1),
      comment: comment,
      dateText: 'Bugün',
    );

    if (_authService is MockAuthService) {
      (_authService as MockAuthService).addReviewToUser(targetUserId, review);
      notifyListeners();
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

  @override
  void dispose() {
    _authSubscription?.cancel();
    _itemsSubscription?.cancel();
    super.dispose();
  }
}
