class AchievementModel {
  final String id;
  final String name;
  final String? description;
  final String? criteria;
  final int? pointsReward;
  final DateTime createdAt;

  AchievementModel({
    required this.id,
    required this.name,
    this.description,
    this.criteria,
    this.pointsReward,
    required this.createdAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      criteria: json['criteria'] as String?,
      pointsReward: json['points_reward'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'criteria': criteria,
      'points_reward': pointsReward,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AchievementModel copyWith({
    String? id,
    String? name,
    String? description,
    String? criteria,
    int? pointsReward,
    DateTime? createdAt,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      criteria: criteria ?? this.criteria,
      pointsReward: pointsReward ?? this.pointsReward,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

