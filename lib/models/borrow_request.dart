import 'package:cloud_firestore/cloud_firestore.dart';

enum BorrowRequestStatus {
  onlyInquiry,
  pendingDiscussion,
  accepted,
  rejected,
  cancelled,
  expired,
  completed,
  borrowed,
}

class BorrowRequestModel {
  final String id;
  final String itemId;
  final String ownerId;
  final String requesterId;
  final BorrowRequestStatus status;
  final String requestedDurationText;
  final String? proposedMeetingPointId;
  final DateTime createdAt;
  final String? meetingLocation;
  final String? meetingNote;
  final DateTime? meetingUpdatedAt;

  // Double-Confirm Handover Timestamps (v0.9.1)
  final DateTime? handoverLenderConfirmedAt;
  final DateTime? handoverBorrowerConfirmedAt;
  final DateTime? returnBorrowerConfirmedAt;
  final DateTime? returnLenderConfirmedAt;

  BorrowRequestModel({
    required this.id,
    required this.itemId,
    required this.ownerId,
    required this.requesterId,
    required this.status,
    required this.requestedDurationText,
    this.proposedMeetingPointId,
    required this.createdAt,
    this.meetingLocation,
    this.meetingNote,
    this.meetingUpdatedAt,
    this.handoverLenderConfirmedAt,
    this.handoverBorrowerConfirmedAt,
    this.returnBorrowerConfirmedAt,
    this.returnLenderConfirmedAt,
  });

  BorrowRequestModel copyWith({
    String? id,
    String? itemId,
    String? ownerId,
    String? requesterId,
    BorrowRequestStatus? status,
    String? requestedDurationText,
    String? proposedMeetingPointId,
    DateTime? createdAt,
    String? meetingLocation,
    String? meetingNote,
    DateTime? meetingUpdatedAt,
    DateTime? handoverLenderConfirmedAt,
    DateTime? handoverBorrowerConfirmedAt,
    DateTime? returnBorrowerConfirmedAt,
    DateTime? returnLenderConfirmedAt,
  }) {
    return BorrowRequestModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      ownerId: ownerId ?? this.ownerId,
      requesterId: requesterId ?? this.requesterId,
      status: status ?? this.status,
      requestedDurationText: requestedDurationText ?? this.requestedDurationText,
      proposedMeetingPointId: proposedMeetingPointId ?? this.proposedMeetingPointId,
      createdAt: createdAt ?? this.createdAt,
      meetingLocation: meetingLocation ?? this.meetingLocation,
      meetingNote: meetingNote ?? this.meetingNote,
      meetingUpdatedAt: meetingUpdatedAt ?? this.meetingUpdatedAt,
      handoverLenderConfirmedAt: handoverLenderConfirmedAt ?? this.handoverLenderConfirmedAt,
      handoverBorrowerConfirmedAt: handoverBorrowerConfirmedAt ?? this.handoverBorrowerConfirmedAt,
      returnBorrowerConfirmedAt: returnBorrowerConfirmedAt ?? this.returnBorrowerConfirmedAt,
      returnLenderConfirmedAt: returnLenderConfirmedAt ?? this.returnLenderConfirmedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'ownerId': ownerId,
      'requesterId': requesterId,
      'status': status.name,
      'requestedDurationText': requestedDurationText,
      'proposedMeetingPointId': proposedMeetingPointId,
      'createdAt': createdAt.toIso8601String(),
      'meetingLocation': meetingLocation,
      'meetingNote': meetingNote,
      'meetingUpdatedAt': meetingUpdatedAt?.toIso8601String(),
      'handoverLenderConfirmedAt': handoverLenderConfirmedAt?.toIso8601String(),
      'handoverBorrowerConfirmedAt': handoverBorrowerConfirmedAt?.toIso8601String(),
      'returnBorrowerConfirmedAt': returnBorrowerConfirmedAt?.toIso8601String(),
      'returnLenderConfirmedAt': returnLenderConfirmedAt?.toIso8601String(),
    };
  }

  static DateTime? _parseTimestamp(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  factory BorrowRequestModel.fromMap(Map<String, dynamic> map) {
    return BorrowRequestModel(
      id: map['id'] ?? '',
      itemId: map['itemId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      requesterId: map['requesterId'] ?? '',
      status: BorrowRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => BorrowRequestStatus.onlyInquiry,
      ),
      requestedDurationText: map['requestedDurationText'] ?? '',
      proposedMeetingPointId: map['proposedMeetingPointId'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt'].toString()))
          : DateTime.now(),
      meetingLocation: map['meetingLocation'],
      meetingNote: map['meetingNote'],
      meetingUpdatedAt: map['meetingUpdatedAt'] != null
          ? (map['meetingUpdatedAt'] is Timestamp
              ? (map['meetingUpdatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['meetingUpdatedAt'].toString()))
          : null,
      handoverLenderConfirmedAt: _parseTimestamp(map['handoverLenderConfirmedAt']),
      handoverBorrowerConfirmedAt: _parseTimestamp(map['handoverBorrowerConfirmedAt']),
      returnBorrowerConfirmedAt: _parseTimestamp(map['returnBorrowerConfirmedAt']),
      returnLenderConfirmedAt: _parseTimestamp(map['returnLenderConfirmedAt']),
    );
  }
}
