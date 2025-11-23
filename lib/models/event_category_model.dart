class EventCategoryModel {
  final String id;
  final String eventId;
  final String categoryId;

  EventCategoryModel({
    required this.id,
    required this.eventId,
    required this.categoryId,
  });

  factory EventCategoryModel.fromJson(Map<String, dynamic> json) {
    return EventCategoryModel(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      categoryId: json['category_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'category_id': categoryId,
    };
  }

  EventCategoryModel copyWith({
    String? id,
    String? eventId,
    String? categoryId,
  }) {
    return EventCategoryModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}

