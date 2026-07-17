enum BorrowRequestStatus {
  onlyInquiry,
  pendingDiscussion,
  accepted,
  rejected,
  cancelled,
  expired,
  completed,
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

  BorrowRequestModel({
    required this.id,
    required this.itemId,
    required this.ownerId,
    required this.requesterId,
    required this.status,
    required this.requestedDurationText,
    this.proposedMeetingPointId,
    required this.createdAt,
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
    };
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
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
