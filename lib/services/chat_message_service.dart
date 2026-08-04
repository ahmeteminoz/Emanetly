import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';

abstract class ChatMessageService {
  Future<void> sendChatMessage(ChatMessageModel message);
  /// Belirli bir request'e ait mesajları dinler (tüm mesajlar yerine)
  Stream<List<ChatMessageModel>> listenToChatMessages(String requestId);
  /// Kullanıcının dahil olduğu tüm request ID'leri için mesajları dinler
  Stream<List<ChatMessageModel>> listenToMessagesForRequests(List<String> requestIds);
  Future<void> markMessagesAsRead(String requestId, String currentUserId);
}

class FirestoreChatMessageService implements ChatMessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> sendChatMessage(ChatMessageModel message) async {
    try {
      await _firestore
          .collection('chatMessages')
          .doc(message.id)
          .set(message.toMap());
    } catch (e) {
      debugPrint('Emanetly: Firestore sendChatMessage error: $e');
      rethrow;
    }
  }

  @override
  Stream<List<ChatMessageModel>> listenToChatMessages(String requestId) {
    return _firestore
        .collection('chatMessages')
        .where('requestId', isEqualTo: requestId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatMessageModel.fromMap(doc.data())).toList());
  }

  @override
  Stream<List<ChatMessageModel>> listenToMessagesForRequests(List<String> requestIds) {
    if (requestIds.isEmpty) {
      return Stream.value([]);
    }
    // Firestore whereIn 30 item ile sınırlı — chunk'lara böl
    final chunks = <List<String>>[];
    for (var i = 0; i < requestIds.length; i += 30) {
      chunks.add(requestIds.sublist(
        i,
        i + 30 > requestIds.length ? requestIds.length : i + 30,
      ));
    }

    final streams = chunks.map((chunk) => _firestore
        .collection('chatMessages')
        .where('requestId', whereIn: chunk)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ChatMessageModel.fromMap(doc.data())).toList()));

    if (streams.length == 1) return streams.first;

    // Birden fazla chunk varsa birleştir
    return streams.fold<Stream<List<ChatMessageModel>>>(
      Stream.value([]),
      (combined, stream) => combined.asyncMap((acc) async {
        final next = await stream.first;
        return [...acc, ...next];
      }),
    );
  }

  @override
  Future<void> markMessagesAsRead(String requestId, String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('chatMessages')
          .where('requestId', isEqualTo: requestId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      var count = 0;
      for (final doc in snapshot.docs) {
        final senderId = doc.data()['senderId'] as String?;
        if (senderId != null && senderId != currentUserId) {
          batch.update(doc.reference, {'isRead': true});
          count++;
        }
      }
      if (count > 0) await batch.commit();
    } catch (e) {
      debugPrint('Emanetly: Firestore markMessagesAsRead error: $e');
    }
  }
}

class MockChatMessageService implements ChatMessageService {
  @override
  Future<void> sendChatMessage(ChatMessageModel message) async {}

  @override
  Stream<List<ChatMessageModel>> listenToChatMessages(String requestId) =>
      const Stream.empty();

  @override
  Stream<List<ChatMessageModel>> listenToMessagesForRequests(
          List<String> requestIds) =>
      const Stream.empty();

  @override
  Future<void> markMessagesAsRead(String requestId, String currentUserId) async {}
}
