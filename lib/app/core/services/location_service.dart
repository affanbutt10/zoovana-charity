import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../errors/app_error.dart';

class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
  });

  final double latitude;
  final double longitude;
  final double accuracyM;
}

/// Reads the device position when proof is submitted.
class LocationService {
  Future<LocationFix> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw AppError(
        type: AppErrorType.validation,
        code: ApiErrorCode.gpsRequired,
        message: 'Turn on location services to submit the proof.'.tr,
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw AppError(
        type: AppErrorType.validation,
        code: ApiErrorCode.gpsRequired,
        message:
            'Allow location access so the feeding spot can be verified.'.tr,
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return LocationFix(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyM: position.accuracy,
    );
  }
}
