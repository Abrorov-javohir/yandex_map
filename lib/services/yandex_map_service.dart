import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class YandexMapService {
  static Future<List<PolylineMapObject>> getDirection(Point from, Point to) async {
    final result = await YandexPedestrian.requestRoutes(
      points: [
        RequestPoint(point: from, requestPointType: RequestPointType.wayPoint),
        RequestPoint(point: to, requestPointType: RequestPointType.wayPoint),
      ],
      avoidSteep: true,
      timeOptions: TimeOptions(),
    );

    final drivingResults = await result.$2;

    if (drivingResults.error != null) {
      print("Yo'lni ololmadi");
      return [];
    }

    return drivingResults.routes!.map((route) {
      return PolylineMapObject(
        mapId: MapObjectId(UniqueKey().toString()),
        polyline: route.geometry,
        strokeColor: Colors.orange,
        strokeWidth: 5,
      );
    }).toList();
  }

  static Future<String> searchPlace(Point location) async {
    final result = await YandexSearch.searchByPoint(
      point: location,
      searchOptions: const SearchOptions(searchType: SearchType.geo),
    );

    final searchResult = await result.result;

    if (searchResult.error != null) {
      print("Joylashuv nomini bilmadim");
      return "Joy topilmadi";
    }

    return searchResult.items!.first.name;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late YandexMapController mapController;
  String currentLocationName = "";
  List<MapObject> markers = [];
  List<PolylineMapObject> polylines = [];
  List<Point> positions = [];
  Point? myLocation;
  Point najotTalim = const Point(latitude: 41.2856806, longitude: 69.2034646);

  void onMapCreated(YandexMapController controller) {
    setState(() {
      mapController = controller;

      mapController.moveCamera(
        animation: const MapAnimation(type: MapAnimationType.smooth, duration: 1),
        CameraUpdate.newCameraPosition(
          CameraPosition(target: najotTalim, zoom: 18),
        ),
      );
    });
  }

  void onCameraPositionChanged(CameraPosition position, CameraUpdateReason reason, bool finish) {
    myLocation = position.target;
    setState(() {});
  }

  void getMyCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      myLocation = Point(latitude: position.latitude, longitude: position.longitude);
      currentLocationName = "Mening joylashuvim";
      markers.add(
        PlacemarkMapObject(
          mapId: MapObjectId("meningJoylashuvim"),
          point: myLocation!,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromAssetImage("assets/location.png"),
              scale: 0.5,
            ),
          ),
        ),
      );
    });

    mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: myLocation!, zoom: 18),
      ),
    );
  }

  void addMarkerAndRoute(Point destination) async {
    if (myLocation != null) {
      markers.add(
        PlacemarkMapObject(
          mapId: MapObjectId(UniqueKey().toString()),
          point: destination,
          opacity: 1,
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromAssetImage("assets/location.png"),
              scale: 0.5,
            ),
          ),
        ),
      );

      polylines = await YandexMapService.getDirection(myLocation!, destination);

      setState(() {});
    }
  }

  void goToDestination() async {
    Point destination = najotTalim;
    addMarkerAndRoute(destination);
  }

  void startTrackingLocation() {
    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        myLocation = Point(latitude: position.latitude, longitude: position.longitude);
      });

      if (positions.isNotEmpty) {
        positions.removeLast();
      }

      positions.add(myLocation!);
      updateRoute();
    });
  }

  void updateRoute() async {
    if (positions.length == 2) {
      polylines = await YandexMapService.getDirection(positions[0], positions[1]);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentLocationName),
        actions: [
          IconButton(
            onPressed: () async {
              currentLocationName = await YandexMapService.searchPlace(myLocation!);
              setState(() {});
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              mapController.moveCamera(
                animation: const MapAnimation(type: MapAnimationType.smooth, duration: 1),
                CameraUpdate.zoomOut(),
              );
            },
            icon: const Icon(Icons.remove_circle),
          ),
          IconButton(
            onPressed: () {
              mapController.moveCamera(
                animation: const MapAnimation(type: MapAnimationType.smooth, duration: 1),
                CameraUpdate.zoomIn(),
              );
            },
            icon: const Icon(Icons.add_circle),
          ),
        ],
      ),
      body: Stack(
        children: [
          YandexMap(
            onMapCreated: onMapCreated,
            onCameraPositionChanged: onCameraPositionChanged,
            mapType: MapType.map,
            mapObjects: [
              PlacemarkMapObject(
                mapId: const MapObjectId("najotTalim"),
                point: najotTalim,
                opacity: 1,
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    image: BitmapDescriptor.fromAssetImage("assets/location_mark.png"),
                    scale: 0.5,
                  ),
                ),
              ),
              ...markers,
              PlacemarkMapObject(
                mapId: const MapObjectId("meningJoylashuvim"),
                point: myLocation ?? najotTalim,
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    image: BitmapDescriptor.fromAssetImage("assets/location.png"),
                    scale: 0.5,
                  ),
                ),
              ),
              PolylineMapObject(
                mapId: const MapObjectId("UydanNajotTalimgacha"),
                polyline: Polyline(
                  points: [
                    najotTalim,
                    myLocation ?? najotTalim,
                  ],
                ),
              ),
              ...polylines,
            ],
          ),
          const Align(
            child: Icon(
              Icons.place,
              size: 60,
              color: Colors.blue,
            ),
          ),
          Positioned(
            bottom: 45,
            left: 10,
            child: FloatingActionButton(
              onPressed: getMyCurrentLocation,
              child: const Icon(
                Icons.person,
                size: 30,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          goToDestination();
          startTrackingLocation();
        },
        child: const Icon(Icons.add_location),
      ),
    );
  }
}
