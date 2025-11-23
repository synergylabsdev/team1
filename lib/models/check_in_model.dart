class CheckInModel {
  final String id;
  final String userId;
  final String eventId;
  final int pointsEarned;
  final DateTime checkInTime;
  final String? barcodeUsed;

  CheckInModel({
    required this.id,
    required this.userId,
    required this.eventId,
    this.pointsEarned = 0,
    required this.checkInTime,
    this.barcodeUsed,
  });

  factory CheckInModel.fromJson(Map<String, dynamic> json) {
    return CheckInModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String,
      pointsEarned: (json['points_earned'] as int?) ?? 0,
      checkInTime: DateTime.parse(json['check_in_time'] as String),
      barcodeUsed: json['barcode_used'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'points_earned': pointsEarned,
      'check_in_time': checkInTime.toIso8601String(),
      'barcode_used': barcodeUsed,
    };
  }

  CheckInModel copyWith({
    String? id,
    String? userId,
    String? eventId,
    int? pointsEarned,
    DateTime? checkInTime,
    String? barcodeUsed,
  }) {
    return CheckInModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      checkInTime: checkInTime ?? this.checkInTime,
      barcodeUsed: barcodeUsed ?? this.barcodeUsed,
    );
  }
}
