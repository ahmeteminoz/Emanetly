enum MeetingPointStatus {
  pending,
  accepted,
  rejected,
}

class MeetingPointProposalModel {
  final String id;
  final String requestId;
  final String proposedByUserId;
  final String title;
  final String addressText;
  final String proposedTimeText;
  final MeetingPointStatus status;
  final bool acceptedByOwner;
  final bool acceptedByRequester;

  MeetingPointProposalModel({
    required this.id,
    required this.requestId,
    required this.proposedByUserId,
    required this.title,
    required this.addressText,
    required this.proposedTimeText,
    required this.status,
    required this.acceptedByOwner,
    required this.acceptedByRequester,
  });

  MeetingPointProposalModel copyWith({
    String? id,
    String? requestId,
    String? proposedByUserId,
    String? title,
    String? addressText,
    String? proposedTimeText,
    MeetingPointStatus? status,
    bool? acceptedByOwner,
    bool? acceptedByRequester,
  }) {
    return MeetingPointProposalModel(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      proposedByUserId: proposedByUserId ?? this.proposedByUserId,
      title: title ?? this.title,
      addressText: addressText ?? this.addressText,
      proposedTimeText: proposedTimeText ?? this.proposedTimeText,
      status: status ?? this.status,
      acceptedByOwner: acceptedByOwner ?? this.acceptedByOwner,
      acceptedByRequester: acceptedByRequester ?? this.acceptedByRequester,
    );
  }
}
