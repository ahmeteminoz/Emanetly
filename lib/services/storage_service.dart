import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

abstract class StorageService {
  Future<String> uploadItemImage(String itemId, File imageFile, {void Function(double progress)? onProgress});
  Future<String> uploadProfileImage(String userId, File imageFile, {void Function(double progress)? onProgress});
  Future<void> deleteImage(String imageUrl);
}

class FirebaseStorageService implements StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<String> uploadItemImage(String itemId, File imageFile, {void Function(double progress)? onProgress}) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('items').child(itemId).child(fileName);
      
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((event) {
          if (event.totalBytes > 0) {
            final progress = event.bytesTransferred / event.totalBytes;
            onProgress(progress);
          }
        });
      }
      
      final snapshot = await uploadTask.timeout(const Duration(seconds: 15));
      return await snapshot.ref.getDownloadURL().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('FirebaseStorageService: Error uploading item image: $e');
      rethrow;
    }
  }

  @override
  Future<String> uploadProfileImage(String userId, File imageFile, {void Function(double progress)? onProgress}) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('profiles').child(userId).child(fileName);
      
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((event) {
          if (event.totalBytes > 0) {
            final progress = event.bytesTransferred / event.totalBytes;
            onProgress(progress);
          }
        });
      }
      
      final snapshot = await uploadTask.timeout(const Duration(seconds: 15));
      return await snapshot.ref.getDownloadURL().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('FirebaseStorageService: Error uploading profile image: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) return;
    try {
      if (imageUrl.contains('firebasestorage.googleapis.com')) {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }
    } catch (e) {
      debugPrint('FirebaseStorageService: Error deleting image from storage: $e');
    }
  }
}

class MockStorageService implements StorageService {
  @override
  Future<String> uploadItemImage(String itemId, File imageFile, {void Function(double progress)? onProgress}) async {
    debugPrint('MockStorageService: Uploading item image for $itemId');
    if (onProgress != null) {
      onProgress(0.2);
      await Future.delayed(const Duration(milliseconds: 150));
      onProgress(0.5);
      await Future.delayed(const Duration(milliseconds: 150));
      onProgress(0.8);
      await Future.delayed(const Duration(milliseconds: 150));
      onProgress(1.0);
    }
    return imageFile.path;
  }

  @override
  Future<String> uploadProfileImage(String userId, File imageFile, {void Function(double progress)? onProgress}) async {
    debugPrint('MockStorageService: Uploading profile image for $userId');
    if (onProgress != null) {
      onProgress(0.2);
      await Future.delayed(const Duration(milliseconds: 150));
      onProgress(0.5);
      await Future.delayed(const Duration(milliseconds: 150));
      onProgress(0.8);
      await Future.delayed(const Duration(milliseconds: 150));
      onProgress(1.0);
    }
    return imageFile.path;
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    debugPrint('MockStorageService: Deleting image $imageUrl');
  }
}
