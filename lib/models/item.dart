import 'comment.dart';

enum EmanetStatus {
  available,
  pendingApproval,
  borrowed,
  pendingReturn,
  archived,
}

enum DeliveryStatus {
  requestSent,
  accepted,
  meetingPointSet,
  routingStarted,
  delivered,
  completed,
}

class EmanetItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String lenderId;
  final String lenderName;
  final String? borrowerId;
  final String? borrowerName;
  final String location;
  final String? imageUrl;
  final EmanetStatus status;
  final DateTime createdAt;
  
  // Marketplace & Delivery timeline extensions
  final List<EmanetComment> comments;
  final String? meetingPoint;
  final DeliveryStatus? deliveryStatus;
  final int mockImageColorValue; // e.g. 0xFF1E3A8A for rendering card gradient colors

  // Custom Pick-up Location Parameters
  final String pickupLocationTitle;
  final String pickupAddressText;
  final double pickupLatitude;
  final double pickupLongitude;
  final bool locationVisibility;

  EmanetItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.lenderId,
    required this.lenderName,
    this.borrowerId,
    this.borrowerName,
    required this.location,
    this.imageUrl,
    required this.status,
    required this.createdAt,
    this.comments = const [],
    this.meetingPoint,
    this.deliveryStatus,
    required this.mockImageColorValue,
    this.pickupLocationTitle = 'Kampüs Genel',
    this.pickupAddressText = 'Kampüs içi ortak alanda elden teslim',
    this.pickupLatitude = 41.0082,
    this.pickupLongitude = 28.9784,
    this.locationVisibility = true,
  });

  bool get isAvailable => status == EmanetStatus.available;

  EmanetItem copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? lenderId,
    String? lenderName,
    String? borrowerId,
    String? borrowerName,
    String? location,
    String? imageUrl,
    EmanetStatus? status,
    DateTime? createdAt,
    List<EmanetComment>? comments,
    String? meetingPoint,
    DeliveryStatus? deliveryStatus,
    int? mockImageColorValue,
    String? pickupLocationTitle,
    String? pickupAddressText,
    double? pickupLatitude,
    double? pickupLongitude,
    bool? locationVisibility,
  }) {
    return EmanetItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      lenderId: lenderId ?? this.lenderId,
      lenderName: lenderName ?? this.lenderName,
      borrowerId: borrowerId ?? this.borrowerId,
      borrowerName: borrowerName ?? this.borrowerName,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      comments: comments ?? this.comments,
      meetingPoint: meetingPoint ?? this.meetingPoint,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      mockImageColorValue: mockImageColorValue ?? this.mockImageColorValue,
      pickupLocationTitle: pickupLocationTitle ?? this.pickupLocationTitle,
      pickupAddressText: pickupAddressText ?? this.pickupAddressText,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      locationVisibility: locationVisibility ?? this.locationVisibility,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'lenderId': lenderId,
      'lenderName': lenderName,
      'borrowerId': borrowerId,
      'borrowerName': borrowerName,
      'location': location,
      'imageUrl': imageUrl,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'comments': comments.map((c) => c.toMap()).toList(),
      'meetingPoint': meetingPoint,
      'deliveryStatus': deliveryStatus?.name,
      'mockImageColorValue': mockImageColorValue,
      'pickupLocationTitle': pickupLocationTitle,
      'pickupAddressText': pickupAddressText,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'locationVisibility': locationVisibility,
    };
  }

  factory EmanetItem.fromMap(Map<String, dynamic> map) {
    return EmanetItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      lenderId: map['lenderId'] ?? '',
      lenderName: map['lenderName'] ?? '',
      borrowerId: map['borrowerId'],
      borrowerName: map['borrowerName'],
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'],
      status: EmanetStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => EmanetStatus.available,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      comments: map['comments'] != null
          ? List<EmanetComment>.from(
              (map['comments'] as List).map((c) => EmanetComment.fromMap(c)))
          : [],
      meetingPoint: map['meetingPoint'],
      deliveryStatus: map['deliveryStatus'] != null
          ? DeliveryStatus.values.firstWhere(
              (e) => e.name == map['deliveryStatus'],
              orElse: () => DeliveryStatus.requestSent,
            )
          : null,
      mockImageColorValue: map['mockImageColorValue'] ?? 0xFF1E3A8A,
      pickupLocationTitle: map['pickupLocationTitle'] ?? 'Kampüs Genel',
      pickupAddressText: map['pickupAddressText'] ?? 'Kampüs içi ortak alanda elden teslim',
      pickupLatitude: map['pickupLatitude'] ?? 41.0082,
      pickupLongitude: map['pickupLongitude'] ?? 28.9784,
      locationVisibility: map['locationVisibility'] ?? true,
    );
  }
}
