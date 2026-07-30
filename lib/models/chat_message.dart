enum ChatMessageType {
  text,
  system,
  meetingPointProposal,
  requestStatusUpdate,
}

class ChatMessageModel {
  final String id;
  final String requestId;
  final String senderId;
  final String senderName;
  final String text;
  final ChatMessageType type;
  final DateTime createdAt;
  final String? customPayload; // Optional payload for IDs or metadata (e.g. proposalId)
  final bool isRead;

  ChatMessageModel({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.type,
    required this.createdAt,
    this.customPayload,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestId': requestId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'customPayload': customPayload,
      'isRead': isRead,
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    final rawCreated = map['createdAt'];
    if (rawCreated is Timestamp) {
      parsedDate = rawCreated.toDate();
    } else if (rawCreated is String) {
      parsedDate = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return ChatMessageModel(
      id: map['id'] ?? '',
      requestId: map['requestId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      type: ChatMessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ChatMessageType.text,
      ),
      createdAt: parsedDate.toLocal(),
      customPayload: map['customPayload'],
      isRead: map['isRead'] ?? false,
    );
  }
}
