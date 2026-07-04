enum BorrowRequestStatus {
  pendingDiscussion,
  accepted,
  rejected,
  cancelled,
  expired,
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
}
