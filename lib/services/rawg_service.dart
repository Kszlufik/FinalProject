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
    String platform = '',
    String dates = '',
  }) async {
    final queryParams = {
      'key': _apiKey,
      'page_size': '40',
      'page': page.toString(),
      'ordering': sortBy,
      'esrb_rating': 'everyone,everyone-10-plus,teen,mature',
      'exclude_additions': 'true',
      'metacritic': '1,100',
      if (genre.isNotEmpty) 'genres': genre,
      if (search.isNotEmpty) 'search': search,
      if (platform.isNotEmpty) 'platforms': platform,
      if (dates.isNotEmpty) 'dates': dates,
    };

    final uri = Uri.https('api.rawg.io', '/api/games', queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List<dynamic>;

      
      final filtered = results.where((game) {
        final esrb = game['esrb_rating'];
        if (esrb == null) return true;
        final slug = esrb['slug'] ?? '';
        return slug != 'adults-only';
      }).toList();

      return filtered;
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