import 'dart:async';

import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:geolocator/geolocator.dart';

class PermissionsService {
  // Location Permission
  static Future<bool> requestLocationPermission() async {
    final status = await ph.Permission.location.request();
    if (status.isPermanentlyDenied) {
      await ph.openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  static Future<bool> checkLocationPermission() async {
    final status = await ph.Permission.location.status;
    if (status.isGranted) {
      return true;
    }
    if (status.isLimited || status.isProvisional) {
      return true;
    }
    return false;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        final granted = await requestLocationPermission();
        if (!granted) {
          return null;
        }
      }

      final position =
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Location timeout'),
          );
      return position;
    } on TimeoutException {
      final lastKnown = await Geolocator.getLastKnownPosition();
      return lastKnown;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Notification Permission
  static Future<bool> requestNotificationPermission() async {
    final status = await ph.Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> checkNotificationPermission() async {
    final status = await ph.Permission.notification.status;
    return status.isGranted;
  }

  // Calendar Permission
  static Future<bool> ensureCalendarPermission() async {
    final status = await ph.Permission.calendar.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }

    final result = await ph.Permission.calendar.request();
    if (result.isPermanentlyDenied) {
      await ph.openAppSettings();
      return false;
    }

    return result.isGranted || result.isLimited;
  }

  // Open App Settings (for when permission is permanently denied)
  static Future<bool> openAppSettings() async {
    return await ph.openAppSettings();
  }
}
