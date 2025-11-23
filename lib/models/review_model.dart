class ReviewModel {
  final String id;
  final String userId;
  final String eventId;
  final String brandId;
  final int rating;
  final List<String> tags;
  final String? comment;
  final int pointsEarned;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.brandId,
    required this.rating,
    required this.tags,
    this.comment,
    this.pointsEarned = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String,
      brandId: json['brand_id'] as String,
      rating: json['rating'] as int,
      tags: List<String>.from(json['tags'] as List? ?? []),
      comment: json['comment'] as String?,
      pointsEarned: (json['points_earned'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'brand_id': brandId,
      'rating': rating,
      'tags': tags,
      'comment': comment,
      'points_earned': pointsEarned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ReviewModel copyWith({
    String? id,
    String? userId,
    String? eventId,
    String? brandId,
    int? rating,
    List<String>? tags,
    String? comment,
    int? pointsEarned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      brandId: brandId ?? this.brandId,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      comment: comment ?? this.comment,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

