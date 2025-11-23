enum AdminRole {
  superAdmin,
  moderator;

  String get value {
    switch (this) {
      case AdminRole.superAdmin:
        return 'SuperAdmin';
      case AdminRole.moderator:
        return 'Moderator';
    }
  }

  static AdminRole fromString(String value) {
    switch (value) {
      case 'SuperAdmin':
        return AdminRole.superAdmin;
      case 'Moderator':
        return AdminRole.moderator;
      default:
        return AdminRole.moderator;
    }
  }
}

class AdminModel {
  final String id;
  final String email;
  final String? name;
  final AdminRole role;
  final DateTime createdAt;

  AdminModel({
    required this.id,
    required this.email,
    this.name,
    this.role = AdminRole.moderator,
    required this.createdAt,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      role: json['role'] != null
          ? AdminRole.fromString(json['role'] as String)
          : AdminRole.moderator,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.value,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AdminModel copyWith({
    String? id,
    String? email,
    String? name,
    AdminRole? role,
    DateTime? createdAt,
  }) {
    return AdminModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

