import 'dart:async';
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/item_service.dart';
import '../services/qr_service.dart';

enum ViewMode {
  compactGrid,
  standardGrid,
  largeCards,
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
  }) async {
    if (currentUser == null) return false;
    _setLoading(true);
    try {
      // Pick a random mock color for the grid photo placeholders
      final colorOptions = [0xFF3B82F6, 0xFFEF4444, 0xFFF59E0B, 0xFF10B981, 0xFF8B5CF6, 0xFFEC4899];
      final mockColor = colorOptions[DateTime.now().millisecond % colorOptions.length];

      final newItem = EmanetItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
        category: category,
        lenderId: currentUser!.uid,
        lenderName: currentUser!.name,
        location: location,
        status: EmanetStatus.available,
        createdAt: DateTime.now(),
        comments: [],
        mockImageColorValue: mockColor,
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

  // Request to borrow an item
  Future<bool> requestBorrow(String itemId) async {
    if (currentUser == null) return false;
    _setLoading(true);
    try {
      final item = _items.firstWhere((i) => i.id == itemId);
      await _itemService.requestBorrow(itemId, currentUser!.uid, currentUser!.name);
      _addLog('${currentUser!.name}, "${item.title}" için ödünç talebi gönderdi.');
      return true;
    } catch (e) {
      _addLog('Ödünç talebi hatası: $e');
      return false;
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
