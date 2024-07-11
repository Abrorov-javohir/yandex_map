import 'package:dio/dio.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class YandexMapService {
  static Future<List<SuggestItem>> searchPlace(String query) async {
    const apiKey = 'YOUR_YANDEX_API_KEY'; // Yandex API keyni kiritish kerak
    final url = 'https://search-maps.yandex.ru/v1/?apikey=$apiKey&text=$query&lang=en_US&results=10';

    try {
      final response = await Dio().get(url);

      if (response.statusCode == 200) {
        final List<dynamic> suggestions = response.data['features'];
        return suggestions.map((item) {
          final point = Point(
            latitude: item['geometry']['coordinates'][1],
            longitude: item['geometry']['coordinates'][0],
          );
          return SuggestItem(
            name: item['properties']['name'],
            point: point,
          );
        }).toList();
      } else {
        throw Exception('Failed to load suggestions');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
      throw Exception('Failed to load suggestions');
    }
  }
}

class SuggestItem {
  final String name;
  final Point point;

  SuggestItem({
    required this.name,
    required this.point,
  });
}
