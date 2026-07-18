import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

abstract class ChatMessageService {
  Future<void> sendChatMessage(ChatMessageModel message);
  Stream<List<ChatMessageModel>> listenToAllChatMessages();
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
}
