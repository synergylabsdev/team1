enum TierStatus {
  bronze,
  silver,
  gold,
  platinum;

  String get value {
    switch (this) {
      case TierStatus.bronze:
        return 'Bronze';
      case TierStatus.silver:
        return 'Silver';
      case TierStatus.gold:
        return 'Gold';
      case TierStatus.platinum:
        return 'Platinum';
    }
  }

  static TierStatus fromString(String value) {
    switch (value) {
      case 'Bronze':
        return TierStatus.bronze;
      case 'Silver':
        return TierStatus.silver;
      case 'Gold':
        return TierStatus.gold;
      case 'Platinum':
        return TierStatus.platinum;
      default:
        return TierStatus.bronze;
    }
  }
}

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? phone;
  final DateTime? dob;
  final String? profilePicture;
  final int points;
  final TierStatus tierStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.phone,
    this.dob,
    this.profilePicture,
    this.points = 0,
    this.tierStatus = TierStatus.bronze,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      dob: json['dob'] != null
          ? DateTime.parse(json['dob'] as String)
          : null,
      profilePicture: json['profile_picture'] as String?,
      points: (json['points'] as int?) ?? 0,
      tierStatus: json['tier_status'] != null
          ? TierStatus.fromString(json['tier_status'] as String)
          : TierStatus.bronze,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'phone': phone,
      'dob': dob?.toIso8601String(),
      'profile_picture': profilePicture,
      'points': points,
      'tier_status': tierStatus.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phone,
    DateTime? dob,
    String? profilePicture,
    int? points,
    TierStatus? tierStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      profilePicture: profilePicture ?? this.profilePicture,
      points: points ?? this.points,
      tierStatus: tierStatus ?? this.tierStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

