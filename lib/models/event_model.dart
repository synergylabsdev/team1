enum EventStatus {
  active,
  live,
  archived;

  String get value {
    switch (this) {
      case EventStatus.active:
        return 'Active';
      case EventStatus.live:
        return 'Live';
      case EventStatus.archived:
        return 'Archived';
    }
  }

  static EventStatus fromString(String value) {
    switch (value) {
      case 'Active':
        return EventStatus.active;
      case 'Live':
        return EventStatus.live;
      case 'Archived':
        return EventStatus.archived;
      default:
        return EventStatus.active;
    }
  }
}

class EventModel {
  final String id;
  final String brandId;
  final String storeName;
  final String location;
  final double latitude;
  final double longitude;
  final String? description;
  final DateTime dateStart;
  final DateTime dateEnd;
  final String? qrCodeUrl;
  final String? fallbackCode;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.brandId,
    required this.storeName,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.description,
    required this.dateStart,
    required this.dateEnd,
    this.qrCodeUrl,
    this.fallbackCode,
    this.status = EventStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      brandId: json['brand_id'] as String,
      storeName: json['store_name'] as String,
      location: json['location'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      description: json['description'] as String?,
      dateStart: DateTime.parse(json['date_start'] as String),
      dateEnd: DateTime.parse(json['date_end'] as String),
      qrCodeUrl: json['qr_code_url'] as String?,
      fallbackCode: json['fallback_code'] as String?,
      status: json['status'] != null
          ? EventStatus.fromString(json['status'] as String)
          : EventStatus.active,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand_id': brandId,
      'store_name': storeName,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'date_start': dateStart.toIso8601String(),
      'date_end': dateEnd.toIso8601String(),
      'qr_code_url': qrCodeUrl,
      'fallback_code': fallbackCode,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  EventModel copyWith({
    String? id,
    String? brandId,
    String? storeName,
    String? location,
    double? latitude,
    double? longitude,
    String? description,
    DateTime? dateStart,
    DateTime? dateEnd,
    String? qrCodeUrl,
    String? fallbackCode,
    EventStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      storeName: storeName ?? this.storeName,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      dateStart: dateStart ?? this.dateStart,
      dateEnd: dateEnd ?? this.dateEnd,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      fallbackCode: fallbackCode ?? this.fallbackCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

