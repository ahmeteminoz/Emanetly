import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../services/item_service.dart';
import '../../services/storage_service.dart';
import '../../services/analytics_service.dart';
import '../../services/crashlytics_service.dart';

/// ItemNotifier - Emanet ilan listesi ve CRUD operasyonlarını yönetir.
/// AppState facade'ı tarafından orkestra edilir; tüm public getter/metotlar korunur.
class ItemNotifier extends ChangeNotifier {
  final ItemService _itemService;
  final StorageService _storageService;
  final AnalyticsService _analyticsService;
  final CrashlyticsService _crashlyticsService;

  List<EmanetItem> _items = [];
  StreamSubscription<List<EmanetItem>>? _itemsSubscription;

  ItemNotifier({
    required ItemService itemService,
    required StorageService storageService,
    AnalyticsService? analyticsService,
    CrashlyticsService? crashlyticsService,
  })  : _itemService = itemService,
        _storageService = storageService,
        _analyticsService = analyticsService ?? AnalyticsService(),
        _crashlyticsService = crashlyticsService ?? CrashlyticsService() {
    // İlan listesini real-time dinle
    _itemsSubscription = _itemService.onItemsChanged.listen((newItems) {
      _items = newItems;
      notifyListeners();
    });
    // İlk yükleme
    _loadInitialItems();
  }

  // ─── Getters ─────────────────────────────────────────────────────────────

  /// Tüm ilanlar (archived hariç). Blok filtresi AppState katmanında uygulanır.
  List<EmanetItem> get rawItems => List.unmodifiable(_items);

  EmanetItem? findItemInMemory(String itemId) {
    try {
      return _items.firstWhere((i) => i.id == itemId);
    } catch (_) {
      return null;
    }
  }

  Future<EmanetItem?> getItemById(String itemId) async {
    final cached = findItemInMemory(itemId);
    if (cached != null) return cached;
    try {
      return await _itemService.getItemById(itemId);
    } catch (e) {
      debugPrint('Emanetly: getItemById error: $e');
      return null;
    }
  }

  ItemService get itemService => _itemService;
  StorageService get storageService => _storageService;

  // ─── Initial Load ─────────────────────────────────────────────────────────

  Future<void> _loadInitialItems() async {
    try {
      _items = await _itemService.getItems();
      notifyListeners();
    } catch (e) {
      debugPrint('Emanetly: ItemNotifier initial load error: $e');
    }
  }

  Future<void> refreshItems() async {
    try {
      _items = await _itemService.getItems();
      notifyListeners();
    } catch (e) {
      debugPrint('Emanetly: ItemNotifier refresh error: $e');
    }
  }

  // ─── CRUD ─────────────────────────────────────────────────────────────────

  Future<bool> addItem(EmanetItem item) async {
    try {
      await _itemService.addItem(item);
      _analyticsService.logListingCreated(
        category: item.category,
        durationBucket: 'standard',
      );
      return true;
    } catch (e, stack) {
      _crashlyticsService.recordError(e, stack, reason: 'addItem failed');
      return false;
    }
  }

  Future<bool> editItem({
    required String itemId,
    required String title,
    required String description,
    required String category,
    required String location,
    List<String> images = const [],
    String? imageUrl,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final existing = findItemInMemory(itemId);
      if (existing == null) return false;

      final uploadedUrls = <String>[];
      for (int i = 0; i < images.length; i++) {
        final path = images[i];
        if (path.startsWith('http')) {
          uploadedUrls.add(path);
        } else {
          final file = File(path);
          final url = await _storageService.uploadItemImage(
            itemId,
            file,
            onProgress: onProgress != null
                ? (p) => onProgress((i + p) / images.length)
                : null,
          );
          uploadedUrls.add(url);
        }
      }
      if (uploadedUrls.isEmpty && imageUrl != null && imageUrl.isNotEmpty) {
        uploadedUrls.add(imageUrl);
      }

      final updated = existing.copyWith(
        title: title,
        description: description,
        category: category,
        location: location,
        images: uploadedUrls.isNotEmpty ? uploadedUrls : existing.images,
        imageUrl: uploadedUrls.isNotEmpty ? uploadedUrls.first : existing.imageUrl,
      );
      await _itemService.updateItem(updated);
      return true;
    } catch (e, stack) {
      _crashlyticsService.recordError(e, stack, reason: 'editItem failed');
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      await _itemService.deleteItem(itemId);
      return true;
    } catch (e, stack) {
      _crashlyticsService.recordError(e, stack, reason: 'deleteItem failed');
      return false;
    }
  }

  Future<String> uploadItemImage(
    String itemId,
    File file, {
    void Function(double)? onProgress,
  }) async {
    return _storageService.uploadItemImage(itemId, file, onProgress: onProgress);
  }

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    super.dispose();
  }
}
