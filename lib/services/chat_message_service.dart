import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

abstract class ChatMessageService {
  Future<void> sendChatMessage(ChatMessageModel message);
  Stream<List<ChatMessageModel>> listenToAllChatMessages();
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
      print('Emanetly: Firestore sendChatMessage error: $e');
      rethrow;
    }
  }

  @override
  Stream<List<ChatMessageModel>> listenToAllChatMessages() {
    return _firestore
        .collection('chatMessages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageModel.fromMap(doc.data()))
          .toList();
    });
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
        final senderId = doc.data()['senderId'];
        if (senderId != currentUserId) {
          batch.update(doc.reference, {'isRead': true});
          count++;
        }
      }
      if (count > 0) {
        await batch.commit();
      }
    } catch (e) {
      print('Emanetly: Firestore markMessagesAsRead error: $e');
    }
  }
}

class MockChatMessageService implements ChatMessageService {
  @override
  Future<void> sendChatMessage(ChatMessageModel message) async {
    // Mock fallback, no database write needed
  }

  @override
  Stream<List<ChatMessageModel>> listenToAllChatMessages() {
    return const Stream.empty();
  }

  @override
  Future<void> markMessagesAsRead(String requestId, String currentUserId) async {
    // Mock fallback, no action needed
  }
}
