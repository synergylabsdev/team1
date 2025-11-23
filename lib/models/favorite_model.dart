class FavoriteModel {
  final String id;
  final String userId;
  final String brandId;
  final DateTime createdAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.brandId,
    required this.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      brandId: json['brand_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'brand_id': brandId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  FavoriteModel copyWith({
    String? id,
    String? userId,
    String? brandId,
    DateTime? createdAt,
  }) {
    return FavoriteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      brandId: brandId ?? this.brandId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

