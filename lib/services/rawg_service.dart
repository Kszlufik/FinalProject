import 'dart:convert';
import 'package:http/http.dart' as http;

class RawgService {
  static const String _baseUrl = 'https://api.rawg.io/api';
  static const String _apiKey = '7ebe36a5b43249e995faab2bf81262bf';

  Future<List<dynamic>> fetchGames({
    int page = 1,
    String sortBy = '-rating',
    String genre = '',
    String search = '',
  }) async {
    final queryParams = {
      'key': _apiKey,
      'page_size': '40',
      'page': page.toString(),
      'ordering': sortBy,
      if (genre.isNotEmpty) 'genres': genre,
      if (search.isNotEmpty) 'search': search,
    };

    final uri = Uri.https('api.rawg.io', '/api/games', queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to fetch games');
    }
  }

  Future<Map<String, dynamic>> fetchGameDetails(int id) async {
    final uri = Uri.parse('$_baseUrl/games/$id?key=$_apiKey');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch game details');
    }
  }
}
