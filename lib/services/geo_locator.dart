import 'package:geolocator/geolocator.dart';

class GeolocatorService {
  static bool serviceEnabled = false;
  static LocationPermission permission = LocationPermission.denied;

  static Future<void> init() async {
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {

        print('Location permissions are denied');
      }
    }
  }

  static Future<Position> getLocation() async {
    return Geolocator.getCurrentPosition();
  }

  static Stream<Position> getLiveLocation() async* {
    yield* Geolocator.getPositionStream();
  }
}