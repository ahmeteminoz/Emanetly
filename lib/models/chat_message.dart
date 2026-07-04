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

  ChatMessageModel({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.type,
    required this.createdAt,
    this.customPayload,
  });
}
