/// Distributor model representing a retail outlet/distribution point
class Distributor {
  final String id;
  final String name;
  final String contact;
  final String address;
  final double latitude;
  final double longitude;
  final String? adminId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Distributor({
    required this.id,
    required this.name,
    required this.contact,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.adminId,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Convert Distributor to Firestore JSON
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'address': address,
      'location': {'latitude': latitude, 'longitude': longitude},
      'adminId': adminId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
    };
  }

  /// Create Distributor from Firestore JSON
  factory Distributor.fromFirestore(Map<String, dynamic> data) {
    // Handle both location formats: nested 'location' object or top-level latitude/longitude
    double latitude = 0.0;
    double longitude = 0.0;

    if (data['location'] is Map<String, dynamic>) {
      final location = data['location'] as Map<String, dynamic>;
      latitude = (location['latitude'] as num?)?.toDouble() ?? 0.0;
      longitude = (location['longitude'] as num?)?.toDouble() ?? 0.0;
    } else {
      latitude = (data['latitude'] as num?)?.toDouble() ?? 0.0;
      longitude = (data['longitude'] as num?)?.toDouble() ?? 0.0;
    }

    return Distributor(
      id: data['id'] as String,
      name: data['name'] as String,
      contact: (data['contact'] as String?) ?? (data['phone'] as String?) ?? '',
      address:
          (data['address'] as String?) ??
          (data['location'] is String ? (data['location'] as String) : ''),
      latitude: latitude,
      longitude: longitude,
      adminId: data['adminId'] as String?,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Create a copy with optional fields updated
  Distributor copyWith({
    String? id,
    String? name,
    String? contact,
    String? address,
    double? latitude,
    double? longitude,
    String? adminId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Distributor(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() => 'Distributor(id: $id, name: $name, contact: $contact)';
}
