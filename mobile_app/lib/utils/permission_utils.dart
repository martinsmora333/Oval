import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// A utility class for handling permissions in the app.
class PermissionUtils {
  /// Requests location permission from the user.
  ///
  /// Returns `true` if the permission is granted, `false` otherwise.
  /// If [requestIfDenied] is `true`, it will request the permission if it was previously denied.
  /// If [openSettingsIfPermanentlyDenied] is `true`, it will open the app settings if the permission
  /// was permanently denied.
  static Future<bool> requestLocationPermission({
    bool requestIfDenied = true,
    bool openSettingsIfPermanentlyDenied = true,
  }) async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check location permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied && requestIfDenied) {
      permission = await Geolocator.requestPermission();
    }

    // If permission is permanently denied, open app settings
    if (permission == LocationPermission.deniedForever) {
      if (openSettingsIfPermanentlyDenied) {
        await openAppSettings();
      }
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Checks if the app has location permission.
  ///
  /// Returns `true` if the permission is granted, `false` otherwise.
  static Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Requests camera permission from the user.
  ///
  /// Returns `true` if the permission is granted, `false` otherwise.
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Requests storage permission from the user.
  ///
  /// [requestType] can be either `request()` or `requestMultiple()`.
  /// [withPhotos] if `true`, requests access to photos as well (iOS only).
  ///
  /// Returns `true` if the permission is granted, `false` otherwise.
  static Future<bool> requestStoragePermission({
    bool withPhotos = false,
  }) async {
    if (withPhotos) {
      final status = await Permission.storage.request();
      final photosStatus = await Permission.photos.request();
      return status.isGranted && photosStatus.isGranted;
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  /// Requests notification permission from the user.
  ///
  /// Returns `true` if the permission is granted, `false` otherwise.
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Opens the app settings page.
  static Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }

  /// Checks if a permission is granted.
  ///
  /// [permission] is the permission to check.
  ///
  /// Returns `true` if the permission is granted, `false` otherwise.
  static Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Requests a list of permissions.
  ///
  /// [permissions] is the list of permissions to request.
  ///
  /// Returns a map of permissions and their status.
  static Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    return await permissions.request();
  }

  /// Checks if location services are enabled.
  ///
  /// Returns `true` if location services are enabled, `false` otherwise.
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Opens the location settings page.
  ///
  /// Returns `true` if the settings page was opened, `false` otherwise.
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Opens the app settings page.
  ///
  /// Returns `true` if the settings page was opened, `false` otherwise.
  static Future<bool> openApplicationSettings() async {
    return openAppSettings();
  }
}
