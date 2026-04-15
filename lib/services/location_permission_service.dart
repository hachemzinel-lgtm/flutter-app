import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum LocationPermissionState {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

class LocationPermissionResult {
  const LocationPermissionResult({required this.state, required this.message});

  final LocationPermissionState state;
  final String message;

  bool get isGranted => state == LocationPermissionState.granted;
  bool get needsSettings => state == LocationPermissionState.permanentlyDenied;
}

class LocationPermissionService {
  static Future<LocationPermissionResult>
  ensureLocationWhenInUsePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationPermissionResult(
        state: LocationPermissionState.serviceDisabled,
        message:
            'Location services are turned off. Please enable GPS and try again.',
      );
    }

    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      return const LocationPermissionResult(
        state: LocationPermissionState.granted,
        message: 'Location permission granted.',
      );
    }

    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        return const LocationPermissionResult(
          state: LocationPermissionState.granted,
          message: 'Location permission granted.',
        );
      }
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      return const LocationPermissionResult(
        state: LocationPermissionState.permanentlyDenied,
        message:
            'NearWork needs your location to find nearby services. Please enable location permission in app settings.',
      );
    }

    return const LocationPermissionResult(
      state: LocationPermissionState.denied,
      message:
          'NearWork needs your location to find nearby services. Please allow location access to continue.',
    );
  }

  static Future<void> showPermissionFeedback(
    BuildContext context,
    LocationPermissionResult result, {
    Future<void> Function()? onRetry,
  }) async {
    if (result.needsSettings) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Location permission needed'),
            content: Text(result.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Not now'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await openAppSettings();
                },
                child: const Text('Open settings'),
              ),
            ],
          );
        },
      );
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(result.message),
        action:
            onRetry == null
                ? null
                : SnackBarAction(
                  label: 'Retry',
                  onPressed: () {
                    onRetry();
                  },
                ),
      ),
    );
  }
}
