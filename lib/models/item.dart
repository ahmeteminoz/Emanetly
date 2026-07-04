enum EmanetStatus {
  available,
  pendingApproval,
  borrowed,
  pendingReturn,
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
    );
  }
}
