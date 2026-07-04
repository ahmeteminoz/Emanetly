import 'dart:async';
import '../models/item.dart';

abstract class ItemService {
  Future<List<EmanetItem>> getItems();
  Future<void> addItem(EmanetItem item);
  Future<void> requestBorrow(String itemId, String borrowerId, String borrowerName);
  Future<void> approveBorrow(String itemId);
  Future<void> rejectBorrow(String itemId);
  Future<void> requestReturn(String itemId);
  Future<void> approveReturn(String itemId);
  Stream<List<EmanetItem>> get onItemsChanged;
}

class MockItemService implements ItemService {
  final _controller = StreamController<List<EmanetItem>>.broadcast();
  final List<EmanetItem> _items = [];

  MockItemService() {
    // Initial dummy data
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
      ),
      EmanetItem(
        id: 'item_2',
        title: 'Büyük Boy Siyah Şemsiye',
        description: 'Sağlam rüzgara dayanıklı şemsiye. Yağmurlu günlerde ders bitimine kadar ödünç verebilirim.',
        category: 'Yağmurluk/Şemsiye',
        lenderId: 'user_3', // Can Demir
        lenderName: 'Can Demir',
        location: 'Fizik Bölümü Kantini',
        status: EmanetStatus.available,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
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
      ),
      EmanetItem(
        id: 'item_4',
        title: 'Sineklerin Tanrısı - William Golding',
        description: 'Edebiyat dersi için almıştım, okumak isteyen öğrenci arkadaşlara 2 hafta süreliğine emanet edebilirim.',
        category: 'Ders/Kitap',
        lenderId: 'user_2', // Ayşe Yılmaz
        lenderName: 'Ayşe Yılmaz',
        location: 'Merkez Kütüphane',
        status: EmanetStatus.borrowed,
        borrowerId: 'user_1', // Ahmet Öz
        borrowerName: 'Ahmet Öz',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      EmanetItem(
        id: 'item_5',
        title: 'Çizim Cetveli T-Cetveli 60cm',
        description: 'Mimarlık öğrencileri için T-cetveli. 1-2 günlüğüne ödünç alabilirsiniz.',
        category: 'Kırtasiye',
        lenderId: 'user_3', // Can Demir
        lenderName: 'Can Demir',
        location: 'Mimarlık Stüdyoları',
        status: EmanetStatus.pendingApproval,
        borrowerId: 'user_1', // Ahmet Öz
        borrowerName: 'Ahmet Öz',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ]);
    _notify();
  }

  void _notify() {
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<List<EmanetItem>> getItems() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_items);
  }

  @override
  Future<void> addItem(EmanetItem item) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _items.insert(0, item);
    _notify();
  }

  @override
  Future<void> requestBorrow(String itemId, String borrowerId, String borrowerName) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1 && _items[index].status == EmanetStatus.available) {
      _items[index] = _items[index].copyWith(
        status: EmanetStatus.pendingApproval,
        borrowerId: borrowerId,
        borrowerName: borrowerName,
      );
      _notify();
    } else {
      throw Exception('Eşya şu anda ödünç alınamaz durumda.');
    }
  }

  @override
  Future<void> approveBorrow(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1 && _items[index].status == EmanetStatus.pendingApproval) {
      _items[index] = _items[index].copyWith(
        status: EmanetStatus.borrowed,
      );
      _notify();
    }
  }

  @override
  Future<void> rejectBorrow(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1 && _items[index].status == EmanetStatus.pendingApproval) {
      _items[index] = _items[index].copyWith(
        status: EmanetStatus.available,
        borrowerId: null,
        borrowerName: null,
      );
      _notify();
    }
  }

  @override
  Future<void> requestReturn(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 400));
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
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1 && _items[index].status == EmanetStatus.pendingReturn) {
      _items[index] = _items[index].copyWith(
        status: EmanetStatus.available,
        borrowerId: null,
        borrowerName: null,
      );
      _notify();
    }
  }

  @override
  Stream<List<EmanetItem>> get onItemsChanged => _controller.stream;
}
