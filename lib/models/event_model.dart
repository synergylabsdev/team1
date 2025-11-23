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
    switch (value.toLowerCase()) {
      case 'active':
        return EventStatus.active;
      case 'live':
        return EventStatus.live;
      case 'archived':
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
      id: _requireString(json['id'], 'id'),
      brandId: _requireString(json['brand_id'], 'brand_id'),
      storeName: _requireString(json['store_name'], 'store_name'),
      location: _requireString(json['location'], 'location'),
      latitude: _requireDouble(json['latitude'], 'latitude'),
      longitude: _requireDouble(json['longitude'], 'longitude'),
      description: json['description']?.toString(),
      dateStart: _requireDate(json['date_start'], 'date_start'),
      dateEnd: _requireDate(json['date_end'], 'date_end'),
      qrCodeUrl: json['qr_code_url']?.toString(),
      fallbackCode: json['fallback_code']?.toString(),
      status: json['status'] != null
          ? EventStatus.fromString(json['status'].toString())
          : EventStatus.active,
      createdAt: _requireDate(json['created_at'], 'created_at'),
      updatedAt: _requireDate(json['updated_at'], 'updated_at'),
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

String _requireString(dynamic value, String fieldName) {
  if (value == null) {
    throw FormatException('Missing required field: $fieldName');
  }
  return value.toString();
}

double _requireDouble(dynamic value, String fieldName) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String && value.isNotEmpty) {
    return double.parse(value);
  }
  throw FormatException('Invalid numeric value for $fieldName: $value');
}

DateTime _requireDate(dynamic value, String fieldName) {
  if (value == null) {
    throw FormatException('Missing required field: $fieldName');
  }
  return DateTime.parse(value.toString());
}
