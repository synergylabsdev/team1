class BrandModel {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  BrandModel({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: _requireString(json['id'], 'id'),
      name: _requireString(json['name'], 'name'),
      description: json['description']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      createdAt: _requireDate(json['created_at'], 'created_at'),
      updatedAt: _requireDate(json['updated_at'], 'updated_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BrandModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
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

DateTime _requireDate(dynamic value, String fieldName) {
  if (value == null) {
    throw FormatException('Missing required field: $fieldName');
  }
  return DateTime.parse(value.toString());
}
