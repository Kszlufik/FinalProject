import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/game_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List games = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  // Fetch games from RAWG API
  fetchGames() async {
    const apiKey = '7ebe36a5b43249e995faab2bf81262bf';
    final url =
        'https://api.rawg.io/api/games?key=$apiKey&ordering=-rating&page_size=20';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          games = data['results'];
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          errorMessage = 'Failed to fetch games: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = 'Error fetching games: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine columns based on screen width (responsive)
    int calculateColumns(double width) {
      if (width > 1000) return 4;
      if (width > 600) return 3;
      return 2;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('PlayPal')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = calculateColumns(constraints.maxWidth);
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: games.length,
                        itemBuilder: (context, index) {
                          final game = games[index];
                          return GameCard(
                            name: game['name'] ?? 'Unknown',
                            imageUrl: game['background_image'] ?? '',
                            rating: (game['rating'] ?? 0).toDouble(),
                            released: game['released'] ?? 'Unknown',
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
