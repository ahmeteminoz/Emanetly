import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import '../models/comment.dart';

abstract class ItemService {
  Future<List<EmanetItem>> getItems();
  Future<void> addItem(EmanetItem item);
  Future<void> requestBorrow(String itemId, String borrowerId, String borrowerName);
  Future<void> approveBorrow(String itemId);
  Future<void> rejectBorrow(String itemId);
  Future<void> requestReturn(String itemId);
  Future<void> approveReturn(String itemId);
  
  // New Delivery & Rota methods
  Future<void> setMeetingPoint(String itemId, String meetingPoint);
  Future<void> startRouting(String itemId);
  Future<void> completeDelivery(String itemId);
  
  Stream<List<EmanetItem>> get onItemsChanged;
}

class MockItemService implements ItemService {
  final _controller = StreamController<List<EmanetItem>>.broadcast();
  final List<EmanetItem> _items = [];

  List<EmanetItem> get items => _items;

  MockItemService() {
    // Standard mock reviews
    final List<EmanetComment> dummyComments = [
      EmanetComment(
        id: 'c1',
        authorName: 'Ayşe Yılmaz',
        rating: 4.8,
        content: 'Zamanında teslim etti. Çok nazik bir arkadaştı.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      EmanetComment(
        id: 'c2',
        authorName: 'Can Demir',
        rating: 5.0,
        content: 'Eşya son derece temizdi, hiçbir sıkıntı yaşamadan sınavımda kullandım.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      EmanetComment(
        id: 'c3',
        authorName: 'Ahmet Öz',
        rating: 4.7,
        content: 'Hızlı ve kolay iletişim kuruldu. Güvenle ödünç alabilirsiniz.',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];

    // Initial dummy data with colored container representations
    _items.addAll([
      EmanetItem(
        id: 'item_1',
        title: 'USB-C Hızlı Şarj Cihazı (65W)',
        description: 'MacBook ve Android telefonları hızlı şarj eder. Kütüphane 2. katta elden teslim edebilirim.',
        category: 'Elektronik',
        lenderId: 'user_2', // Ayşe Yılmaz
        lenderName: 'Ayşe Yılmaz',
        location: 'Merkez Kütüphane 2. Kat',
        status: EmanetStatus.available,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        comments: [dummyComments[1], dummyComments[2]],
        mockImageColorValue: 0xFF3B82F6, // Bright Blue
        pickupLocationTitle: 'Kütüphane önü',
        pickupAddressText: 'Merkez Kütüphane ana giriş kapısı önü',
        pickupLatitude: 41.0082,
        pickupLongitude: 28.9784,
        locationVisibility: true,
      ),
      EmanetItem(
        id: 'item_2',
        title: 'Büyük Boy Siyah Şemsiye',
        description: 'Sağlam rüzgara dayanıklı şemsiye. Yağmurlu günlerde ders bitimine kadar ödünç verebilirim.',
        category: 'Günlük Eşya & Yaşam',
        lenderId: 'user_3', // Can Demir
        lenderName: 'Can Demir',
        location: 'Fizik Bölümü Kantini',
        status: EmanetStatus.available,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        comments: [dummyComments[0]],
        mockImageColorValue: 0xFFEF4444, // Vibrant Red
        pickupLocationTitle: 'Fizik Kantini çevresi',
        pickupAddressText: 'Fizik Bölümü giriş kat kantin masaları',
        pickupLatitude: 41.0095,
        pickupLongitude: 28.9770,
        locationVisibility: true,
      ),
      EmanetItem(
        id: 'item_3',
        title: 'Casio fx-991EX Bilimsel Hesap Makinesi',
        description: 'Matematik ve mühendislik sınavlarında kullanılabilir. Sınavınız bitince teslim alırım.',
        category: 'Elektronik',
        lenderId: 'user_1', // Ahmet Öz
        lenderName: 'Ahmet Öz',
        location: 'Mühendislik Fakültesi B Blok',
        status: EmanetStatus.available,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        comments: [dummyComments[0], dummyComments[1]],
        mockImageColorValue: 0xFFF59E0B, // Amber Orange
        pickupLocationTitle: 'Mühendislik B Blok önü',
        pickupAddressText: 'Mühendislik Fakültesi B Blok giriş merdivenleri',
        pickupLatitude: 41.0070,
        pickupLongitude: 28.9790,
        locationVisibility: true,
      ),
      EmanetItem(
        id: 'item_4',
        title: 'Sineklerin Tanrısı - William Golding',
        description: 'Edebiyat dersi için almıştım, okumak isteyen öğrenci arkadaşlara 2 hafta süreliğine emanet edebilirim.',
        category: 'Ders & Kırtasiye',
        lenderId: 'user_2', // Ayşe Yılmaz
        lenderName: 'Ayşe Yılmaz',
        location: 'Merkez Kütüphane',
        status: EmanetStatus.available,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        comments: [dummyComments[2]],
        mockImageColorValue: 0xFF10B981, // Emerald Green
        pickupLocationTitle: 'Kütüphane önü',
        pickupAddressText: 'Merkez Kütüphane iade bankosu',
        pickupLatitude: 41.0082,
        pickupLongitude: 28.9784,
        locationVisibility: true,
      ),
      EmanetItem(
        id: 'item_5',
        title: 'Çizim Cetveli T-Cetveli 60cm',
        description: 'Mimarlık öğrencileri için T-cetveli. 1-2 günlüğüne ödünç alabilirsiniz.',
        category: 'Ders & Kırtasiye',
        lenderId: 'user_3', // Can Demir
        lenderName: 'Can Demir',
        location: 'Mimarlık Stüdyoları',
        status: EmanetStatus.available,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        comments: [],
        mockImageColorValue: 0xFF8B5CF6, // Deep Purple
        pickupLocationTitle: 'Mimarlık Stüdyo Girişi',
        pickupAddressText: 'Mimarlık Fakültesi A Blok stüdyolar giriş turnikesi',
        pickupLatitude: 41.0065,
        pickupLongitude: 28.9795,
        locationVisibility: true,
      ),
      EmanetItem(
        id: 'item_6',
        title: 'Logitech Kablosuz Sessiz Fare',
        description: 'Mühendislik laboratuvarında çalışırken kullanmak için sessiz tıklamalı ergonomik kablosuz mouse.',
        category: 'Elektronik',
        lenderId: 'user_1', // Ahmet Öz
        lenderName: 'Ahmet Öz',
        location: 'Mühendislik B Blok',
        status: EmanetStatus.available,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        comments: [],
        mockImageColorValue: 0xFF10B981, // Emerald Green
        pickupLocationTitle: 'Mühendislik B Blok',
        pickupAddressText: 'Mühendislik B Blok giriş kapısı önü',
        pickupLatitude: 41.0070,
        pickupLongitude: 28.9790,
        locationVisibility: true,
      ),
      EmanetItem(
        id: 'item_7',
        title: 'Python Programlamaya Giriş Kitabı',
        description: 'Temel Python kavramları ve örnek projeler içeren ders kitabı. 2 hafta süreliğine verebilirim.',
        category: 'Ders & Kırtasiye',
        lenderId: 'user_1', // Ahmet Öz
        lenderName: 'Ahmet Öz',
        location: 'Merkez Kütüphane',
        status: EmanetStatus.available,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        comments: [],
        mockImageColorValue: 0xFF3B82F6, // Bright Blue
        pickupLocationTitle: 'Kütüphane önü',
        pickupAddressText: 'Merkez Kütüphane ana giriş merdivenleri',
        pickupLatitude: 41.0082,
        pickupLongitude: 28.9784,
        locationVisibility: true,
      ),
    ]);
    _notify();
  }

  void _notify() {
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<List<EmanetItem>> getItems() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_items);
  }

  @override
  Future<void> addItem(EmanetItem item) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _items.insert(0, item);
    _notify();
  }

  @override
  Future<void> requestBorrow(String itemId, String borrowerId, String borrowerName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1 && _items[index].status == EmanetStatus.available) {
      _items[index] = _items[index].copyWith(
        status: EmanetStatus.pendingApproval,
        borrowerId: borrowerId,
        borrowerName: borrowerName,
        deliveryStatus: DeliveryStatus.requestSent,
      );
      _notify();
    }
  }

  @override
  Future<void> approveBorrow(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1 && _items[index].status == EmanetStatus.pendingApproval) {
      _items[index] = _items[index].copyWith(
        deliveryStatus: DeliveryStatus.accepted,
      );
      _notify();
    }
  }

  @override
  Future<void> rejectBorrow(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1 && _items[index].status == EmanetStatus.pendingApproval) {
      _items[index] = _items[index].copyWith(
        status: EmanetStatus.available,
        borrowerId: null,
        borrowerName: null,
        deliveryStatus: null,
        meetingPoint: null,
      );
      _notify();
    }
  }

  @override
  Future<void> requestReturn(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1 && _items[index].status == EmanetStatus.borrowed) {
      _items[index] = _items[index].copyWith(
        status: EmanetStatus.pendingReturn,
      );
      _notify();
    }
  }

  @override
  Future<void> approveReturn(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1 && _items[index].status == EmanetStatus.pendingReturn) {
      _items[index] = _items[index].copyWith(
        status: EmanetStatus.available,
        borrowerId: null,
        borrowerName: null,
        deliveryStatus: null,
        meetingPoint: null,
      );
      _notify();
    }
  }

  // Delivery & Rota methods implementation
  @override
  Future<void> setMeetingPoint(String itemId, String meetingPoint) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        meetingPoint: meetingPoint,
        deliveryStatus: DeliveryStatus.meetingPointSet,
      );
      _notify();
    }
  }

  @override
  Future<void> startRouting(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        deliveryStatus: DeliveryStatus.routingStarted,
      );
      _notify();
    }
  }

  @override
  Future<void> completeDelivery(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        status: EmanetStatus.borrowed,
        deliveryStatus: DeliveryStatus.completed,
      );
      _notify();
    }
  }

  @override
  Stream<List<EmanetItem>> get onItemsChanged => _controller.stream;
}

class FirestoreItemService implements ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _controller = StreamController<List<EmanetItem>>.broadcast();
  List<EmanetItem> _cachedItems = [];
  StreamSubscription? _firestoreSubscription;

  FirestoreItemService() {
    // Listen to real-time updates from Firestore items collection
    _firestoreSubscription = _firestore
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Database is empty, let's pre-populate with default mock items so the feed is not blank
        _populateDefaultItems();
      } else {
        final List<EmanetItem> firestoreItems = snapshot.docs.map((doc) {
          final data = doc.data();
          return EmanetItem.fromMap(data);
        }).toList();

        // Merge firestore items with locally modified state (borrowed status, delivery status, etc.)
        // so that local mock updates are preserved on screen rebuilds
        _mergeWithLocalCache(firestoreItems);
      }
    }, onError: (e) {
      print('Emanetly: Firestore items listen error: $e');
    });
  }

  void _populateDefaultItems() async {
    final List<EmanetItem> defaultItems = [
      EmanetItem(
        id: 'item_1',
        title: 'USB-C Hızlı Şarj Cihazı (65W)',
        description: 'MacBook ve Android telefonları hızlı şarj eder. Kütüphane 2. katta elden teslim edebilirim.',
        category: 'Elektronik',
        lenderId: 'user_2', // Ayşe Yılmaz
        lenderName: 'Ayşe Yılmaz',
        location: 'Merkez Kütüphane 2. Kat',
        status: EmanetStatus.available,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        mockImageColorValue: 0xFF3B82F6, // Bright Blue
        pickupLocationTitle: 'Kütüphane önü',
        pickupAddressText: 'Merkez Kütüphane ana giriş kapısı önü',
        pickupLatitude: 41.0082,
        pickupLongitude: 28.9784,
        locationVisibility: true,
      ),
      EmanetItem(
        id: 'item_2',
        title: 'Büyük Boy Siyah Şemsiye',
        description: 'Sağlam rüzgara dayanıklı şemsiye. Yağmurlu günlerde ders bitimine kadar ödünç verebilirim.',
        category: 'Günlük Eşya & Yaşam',
        lenderId: 'user_3', // Can Demir
        lenderName: 'Can Demir',
        location: 'Fizik Bölümü Kantini',
        status: EmanetStatus.available,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        mockImageColorValue: 0xFFEF4444, // Vibrant Red
        pickupLocationTitle: 'Fizik Kantini çevresi',
        pickupAddressText: 'Fizik Bölümü giriş kat kantin masaları',
        pickupLatitude: 41.0095,
        pickupLongitude: 28.9770,
        locationVisibility: true,
      ),
      EmanetItem(
        id: 'item_3',
        title: 'Casio fx-991EX Bilimsel Hesap Makinesi',
        description: 'Matematik ve mühendislik sınavlarında kullanılabilir. Sınavınız bitince teslim alırım.',
        category: 'Elektronik',
        lenderId: 'user_1', // Ahmet Öz
        lenderName: 'Ahmet Öz',
        location: 'Mühendislik Fakültesi B Blok',
        status: EmanetStatus.available,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        mockImageColorValue: 0xFF10B981, // Vibrant Green
        pickupLocationTitle: 'Mühendislik B Blok Girişi',
        pickupAddressText: 'Mühendislik Fakültesi B Blok ana giriş merdivenleri',
        pickupLatitude: 41.0070,
        pickupLongitude: 28.9790,
        locationVisibility: true,
      ),
    ];

    for (final item in defaultItems) {
      try {
        await _firestore.collection('items').doc(item.id).set(item.toMap());
      } catch (e) {
        print('Emanetly: Error populating default item ${item.id}: $e');
      }
    }
  }

  void _mergeWithLocalCache(List<EmanetItem> firestoreItems) {
    final updatedList = <EmanetItem>[];
    
    for (final freshItem in firestoreItems) {
      // Find if we have a locally modified version (e.g. status was changed to borrowed in memory)
      final localIndex = _cachedItems.indexWhere((u) => u.id == freshItem.id);
      if (localIndex != -1) {
        final localItem = _cachedItems[localIndex];
        // Keep the local state modifications (status, borrower, comments, meeting points, delivery status)
        updatedList.add(freshItem.copyWith(
          status: localItem.status,
          borrowerId: localItem.borrowerId,
          borrowerName: localItem.borrowerName,
          comments: localItem.comments,
          meetingPoint: localItem.meetingPoint,
          deliveryStatus: localItem.deliveryStatus,
        ));
      } else {
        updatedList.add(freshItem);
      }
    }
    
    _cachedItems = updatedList;
    _controller.add(_cachedItems);
  }

  @override
  Future<List<EmanetItem>> getItems() async {
    if (_cachedItems.isEmpty) {
      try {
        final snapshot = await _firestore
            .collection('items')
            .orderBy('createdAt', descending: true)
            .get();
        _cachedItems = snapshot.docs.map((doc) => EmanetItem.fromMap(doc.data())).toList();
      } catch (e) {
        print('Emanetly: Firestore getItems error: $e');
      }
    }
    return _cachedItems;
  }

  @override
  Future<void> addItem(EmanetItem item) async {
    try {
      final docRef = _firestore.collection('items').doc();
      final finalItem = item.copyWith(id: docRef.id);
      await docRef.set(finalItem.toMap());
    } catch (e) {
      print('Emanetly: Firestore addItem error: $e');
      rethrow;
    }
  }

  // Local Memory fallback handlers for other Stage 2+ features so they continue to work in Stage 1
  void _updateLocalItem(String itemId, EmanetItem Function(EmanetItem) updater) {
    final index = _cachedItems.indexWhere((u) => u.id == itemId);
    if (index != -1) {
      _cachedItems[index] = updater(_cachedItems[index]);
      _controller.add(_cachedItems);
    }
  }

  @override
  Future<void> requestBorrow(String itemId, String borrowerId, String borrowerName) async {
    _updateLocalItem(itemId, (item) => item.copyWith(
      status: EmanetStatus.pendingApproval,
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      deliveryStatus: DeliveryStatus.requestSent,
    ));
  }

  @override
  Future<void> approveBorrow(String itemId) async {
    _updateLocalItem(itemId, (item) => item.copyWith(
      status: EmanetStatus.borrowed,
      deliveryStatus: DeliveryStatus.delivered,
    ));
  }

  @override
  Future<void> rejectBorrow(String itemId) async {
    _updateLocalItem(itemId, (item) => item.copyWith(
      status: EmanetStatus.available,
      borrowerId: null,
      borrowerName: null,
      deliveryStatus: null,
    ));
  }

  @override
  Future<void> requestReturn(String itemId) async {
    _updateLocalItem(itemId, (item) => item.copyWith(
      status: EmanetStatus.pendingReturn,
    ));
  }

  @override
  Future<void> approveReturn(String itemId) async {
    _updateLocalItem(itemId, (item) => item.copyWith(
      status: EmanetStatus.available,
      borrowerId: null,
      borrowerName: null,
      deliveryStatus: null,
    ));
  }

  @override
  Future<void> setMeetingPoint(String itemId, String meetingPoint) async {
    _updateLocalItem(itemId, (item) => item.copyWith(
      meetingPoint: meetingPoint,
      deliveryStatus: DeliveryStatus.meetingPointSet,
    ));
  }

  @override
  Future<void> startRouting(String itemId) async {
    _updateLocalItem(itemId, (item) => item.copyWith(
      deliveryStatus: DeliveryStatus.routingStarted,
    ));
  }

  @override
  Future<void> completeDelivery(String itemId) async {
    _updateLocalItem(itemId, (item) => item.copyWith(
      status: EmanetStatus.borrowed,
      deliveryStatus: DeliveryStatus.completed,
    ));
  }

  @override
  Stream<List<EmanetItem>> get onItemsChanged => _controller.stream;

  void dispose() {
    _firestoreSubscription?.cancel();
  }
}
