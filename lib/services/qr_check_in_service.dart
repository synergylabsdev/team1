import 'dart:convert';
import '../models/qr_check_in_payload.dart';
import 'supabase_service.dart';

class QRCheckInResponse {
  final String status;
  final int? points;
  final String? message;

  QRCheckInResponse({
    required this.status,
    this.points,
    this.message,
  });

  factory QRCheckInResponse.fromJson(Map<String, dynamic> json) {
    return QRCheckInResponse(
      status: json['status'] as String,
      points: json['points'] as int?,
      message: json['message'] as String?,
    );
  }

  bool get isSuccess => status == 'success';
}

class QRCheckInService {
  /// Call Supabase RPC function to check in to an event
  static Future<QRCheckInResponse> checkInEvent({
    required String eventId,
    required String fallbackCode,
  }) async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Call the RPC function
      final response = await SupabaseService.client.rpc(
        'check_in_event',
        params: {
          'p_user_id': user.id,
          'p_event_id': eventId,
          'p_fallback_code': fallbackCode,
        },
      );

      // Parse response
      if (response is Map<String, dynamic>) {
        return QRCheckInResponse.fromJson(response);
      } else if (response is String) {
        // If response is a JSON string, parse it
        final json = jsonDecode(response) as Map<String, dynamic>;
        return QRCheckInResponse.fromJson(json);
      } else {
        throw Exception('Unexpected response format: $response');
      }
    } catch (e) {
      print('Error calling check_in_event RPC: $e');
      
      // Try to extract error message from Supabase error
      String errorMessage = 'Failed to check in';
      if (e.toString().contains('already checked in')) {
        errorMessage = 'You have already checked in to this event';
      } else if (e.toString().contains('Invalid fallback code')) {
        errorMessage = 'Invalid fallback code';
      } else if (e.toString().contains('Event not active')) {
        errorMessage = 'Event is not currently active';
      } else if (e.toString().contains('Event not found')) {
        errorMessage = 'Event not found';
      } else {
        errorMessage = e.toString();
      }

      return QRCheckInResponse(
        status: 'error',
        message: errorMessage,
      );
    }
  }

  /// Process QR code payload and check in
  static Future<QRCheckInResponse> processQRCode(String qrData) async {
    try {
      // Try to parse as JSON
      final payload = QRCheckInPayload.fromJsonString(qrData);
      
      if (payload == null) {
        // If not JSON, try to use as fallback code directly
        // In this case, we need to find the event by fallback code
        return QRCheckInResponse(
          status: 'error',
          message: 'Invalid QR code format. Please scan a valid event QR code.',
        );
      }

      // Call check-in with the payload data
      return await checkInEvent(
        eventId: payload.eventId,
        fallbackCode: payload.fallbackCode,
      );
    } catch (e) {
      return QRCheckInResponse(
        status: 'error',
        message: 'Error processing QR code: ${e.toString()}',
      );
    }
  }

  /// Check in using only fallback code (manual entry)
  /// This requires finding the event by fallback code first
  static Future<QRCheckInResponse> checkInWithFallbackCode(
    String fallbackCode,
  ) async {
    try {
      // Find event by fallback code
      final eventResponse = await SupabaseService.client
          .from('events')
          .select('id')
          .eq('fallback_code', fallbackCode)
          .maybeSingle();

      if (eventResponse == null) {
        return QRCheckInResponse(
          status: 'error',
          message: 'Invalid fallback code. No event found.',
        );
      }

      final eventId = eventResponse['id'] as String;

      // Call check-in RPC
      return await checkInEvent(
        eventId: eventId,
        fallbackCode: fallbackCode,
      );
    } catch (e) {
      return QRCheckInResponse(
        status: 'error',
        message: 'Error: ${e.toString()}',
      );
    }
  }
}

