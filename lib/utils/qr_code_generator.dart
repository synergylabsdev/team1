import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/qr_check_in_payload.dart';

/// Utility class for generating QR codes for events
class QRCodeGenerator {
  /// Generate QR code data JSON string for an event
  static String generateQRCodeData({
    required String eventId,
    required String fallbackCode,
  }) {
    final payload = QRCheckInPayload(
      eventId: eventId,
      fallbackCode: fallbackCode,
    );
    return payload.toJsonString();
  }

  /// Generate QR code widget for display
  static Widget generateQRCodeWidget({
    required String eventId,
    required String fallbackCode,
    double size = 200,
  }) {
    final data = generateQRCodeData(
      eventId: eventId,
      fallbackCode: fallbackCode,
    );

    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      gapless: false,
    );
  }

  /// Example: Generate QR code for testing
  /// Usage: QRCodeGenerator.example()
  static String example() {
    return generateQRCodeData(
      eventId: '12345',
      fallbackCode: 'ABCD1234',
    );
  }
}
