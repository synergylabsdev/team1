import 'dart:convert';

class QRCheckInPayload {
  final String eventId;
  final String fallbackCode;

  QRCheckInPayload({
    required this.eventId,
    required this.fallbackCode,
  });

  factory QRCheckInPayload.fromJson(Map<String, dynamic> json) {
    return QRCheckInPayload(
      eventId: json['eventId'] as String,
      fallbackCode: json['fallbackCode'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'fallbackCode': fallbackCode,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  static QRCheckInPayload? fromJsonString(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return QRCheckInPayload.fromJson(json);
    } catch (e) {
      return null;
    }
  }
}

