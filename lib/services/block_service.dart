import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class BlockedUserModel {
  final String blockedUserId;
  final DateTime createdAt;
  final String source; // 'profile' | 'chat'

  BlockedUserModel({
    required this.blockedUserId,
    required this.createdAt,
    required this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'blockedUserId': blockedUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'source': source,
    };
  }

  factory BlockedUserModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate;
    final rawCreated = map['createdAt'];
    if (rawCreated is Timestamp) {
      parsedDate = rawCreated.toDate();
    } else if (rawCreated is String) {
      parsedDate = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return BlockedUserModel(
      blockedUserId: map['blockedUserId'] ?? id,
      createdAt: parsedDate,
      source: map['source'] ?? 'profile',
    );
  }
}

abstract class BlockService {
  Future<void> blockUser({
    required String currentUserId,
    required String blockedUserId,
    required String source,
  });

  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  });

  Future<bool> isUserBlockedByMe({
    required String currentUserId,
    required String blockedUserId,
  });

  Stream<Set<String>> watchBlockedUserIds(String currentUserId);
}

class FirestoreBlockService implements BlockService {
  final FirebaseFirestore _firestore;

  FirestoreBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _blockedRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('blockedUsers');
  }

  @override
  Future<void> blockUser({
    required String currentUserId,
    required String blockedUserId,
    required String source,
  }) async {
    if (currentUserId.isEmpty || blockedUserId.isEmpty || currentUserId == blockedUserId) {
      return;
    }
    if (source != 'profile' && source != 'chat') {
      throw ArgumentError('Source must be either "profile" or "chat".');
    }

    try {
      final docRef = _blockedRef(currentUserId).doc(blockedUserId);
      
      // Idempotency check: If already blocked, no-op to preserve initial createdAt & source
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        debugPrint('[FirestoreBlockService] User $blockedUserId already blocked by $currentUserId. Idempotent no-op.');
        return;
      }

      final model = BlockedUserModel(
        blockedUserId: blockedUserId,
        createdAt: DateTime.now(),
        source: source,
      );
      await docRef.set(model.toMap());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // Race condition double-click safety: check if document was created concurrently
        final docRef = _blockedRef(currentUserId).doc(blockedUserId);
        final recheck = await docRef.get();
        if (recheck.exists) {
          debugPrint('[FirestoreBlockService] Race condition handled for $blockedUserId. Idempotent no-op.');
          return;
        }
      }
      debugPrint('[FirestoreBlockService] Error blocking user $blockedUserId: $e');
      rethrow;
    } catch (e) {
      debugPrint('[FirestoreBlockService] Error blocking user $blockedUserId: $e');
      rethrow;
    }
  }

  @override
  Future<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    if (currentUserId.isEmpty || blockedUserId.isEmpty) return;

    try {
      final docRef = _blockedRef(currentUserId).doc(blockedUserId);
      await docRef.delete();
    } catch (e) {
      debugPrint('[FirestoreBlockService] Error unblocking user $blockedUserId: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isUserBlockedByMe({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    if (currentUserId.isEmpty || blockedUserId.isEmpty) return false;

    try {
      final doc = await _blockedRef(currentUserId).doc(blockedUserId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('[FirestoreBlockService] Error checking block status: $e');
      return false;
    }
  }

  @override
  Stream<Set<String>> watchBlockedUserIds(String currentUserId) {
    if (currentUserId.isEmpty) {
      return Stream.value({});
    }

    return _blockedRef(currentUserId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toSet();
    });
  }
}
