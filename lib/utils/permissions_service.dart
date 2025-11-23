import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:geolocator/geolocator.dart';

class PermissionsService {
  // Location Permission
  static Future<bool> requestLocationPermission() async {
    final status = await ph.Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> checkLocationPermission() async {
    final status = await ph.Permission.location.status;
    return status.isGranted;
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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
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

  // Open App Settings (for when permission is permanently denied)
  static Future<bool> openAppSettings() async {
    return await ph.openAppSettings();
  }
}

