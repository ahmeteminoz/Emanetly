import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/item_service.dart';
import '../services/qr_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService;
  final ItemService _itemService;
  final QrService _qrService;

  List<EmanetItem> _items = [];
  bool _isLoading = false;
  final List<String> _activityLogs = [];
  
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
      _addLog('"${item.title}" ödünç talebi onaylandı. Eşya ${item.borrowerName ?? 'öğrenci'} tarafından teslim alındı.');
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
          // If action is borrow, let's approve it
          await _itemService.approveBorrow(result.itemId);
          _addLog('QR Kod doğrulandı: Ödünç alma işlemi onaylandı.');
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
