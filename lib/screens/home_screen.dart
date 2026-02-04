import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/game_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  Future<void> fetchGames() async {
    const apiKey = '7ebe36a5b43249e995faab2bf81262bf';
    final url =
        'https://api.rawg.io/api/games?key=$apiKey&ordering=-rating&page_size=30';

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
          errorMessage = 'Failed to fetch games (${response.statusCode})';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('PlayPal'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 1200, 
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: GridView.builder(
                        itemCount: games.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 320, 
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          childAspectRatio: 0.68,
                        ),
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
                    ),
                  ),
                ),
    );
  }
}
