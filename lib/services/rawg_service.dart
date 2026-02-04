import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game.dart';

class RawgService {
  static const String _baseUrl = 'https://api.rawg.io/api';
  static const String _apiKey = '7ebe36a5b43249e995faab2bf81262bf';

  Future<List<Game>> fetchPopularGames() async {
    final url = Uri.parse(
      '$_baseUrl/games?key=$_apiKey&ordering=-rating&page_size=10',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];

      return results.map((json) => Game.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load games');
    }
  }
}
