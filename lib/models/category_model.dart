class CategoryModel {
  final String id;
  final String name;
  final String? parentId;
  final int? ageRestriction;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.parentId,
    this.ageRestriction,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: _requireString(json['id'], 'id'),
      name: _requireString(json['name'], 'name'),
      parentId: json['parent_id']?.toString(),
      ageRestriction: _optionalInt(json['age_restriction']),
      createdAt: _requireDate(json['created_at'], 'created_at'),
      updatedAt: _requireDate(json['updated_at'], 'updated_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'age_restriction': ageRestriction,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? parentId,
    int? ageRestriction,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      ageRestriction: ageRestriction ?? this.ageRestriction,
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

int? _optionalInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String && value.isNotEmpty) {
    return int.parse(value);
  }
  return null;
}

DateTime _requireDate(dynamic value, String fieldName) {
  if (value == null) {
    throw FormatException('Missing required field: $fieldName');
  }
  return DateTime.parse(value.toString());
}
