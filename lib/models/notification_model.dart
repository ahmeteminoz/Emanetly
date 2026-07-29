import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String type; // 'chat', 'pendingApproval', 'accepted', 'rejected', 'cancelled', 'completed'
  final String title;
  final String body;
  final String? requestId;
  final String? itemId;
  final String? senderId;
  final DateTime? readAt;
  final int schemaVersion;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.requestId,
    this.itemId,
    this.senderId,
    this.readAt,
    this.schemaVersion = 1,
    this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return AppNotification(
      id: doc.id, // Derived directly from DocumentSnapshot.id (No duplicate id field)
      type: data['type'] as String? ?? 'general',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      requestId: data['requestId'] as String?,
      itemId: data['itemId'] as String?,
      senderId: data['senderId'] as String?,
      readAt: parseTimestamp(data['readAt']),
      schemaVersion: (data['schemaVersion'] as num?)?.toInt() ?? 1,
      createdAt: parseTimestamp(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'body': body,
      if (requestId != null) 'requestId': requestId,
      if (itemId != null) 'itemId': itemId,
      if (senderId != null) 'senderId': senderId,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'schemaVersion': schemaVersion,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
