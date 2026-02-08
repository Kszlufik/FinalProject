import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/game_card.dart';
import 'game_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List games = [];
  bool loading = true;
  String? errorMessage;
  int currentPage = 1; 

  final TextEditingController _searchController = TextEditingController();
  String currentQuery = '';

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  Future<void> fetchGames({String query = '', int page = 1}) async {
    const apiKey = '7ebe36a5b43249e995faab2bf81262bf';
    currentQuery = query;
    currentPage = page;

    final url = query.isEmpty
        ? 'https://api.rawg.io/api/games?key=$apiKey&ordering=-rating&page_size=100&page=$page'
        : 'https://api.rawg.io/api/games?key=$apiKey&search=$query&page_size=100&page=$page';

    setState(() {
      loading = true;
      errorMessage = null;
    });

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

  void _nextPage() {
    fetchGames(query: currentQuery, page: currentPage + 1);
  }

  void _previousPage() {
    if (currentPage > 1) {
      fetchGames(query: currentQuery, page: currentPage - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PlayPal')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SEARCH BAR
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search games...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (value) {
                              fetchGames(query: value, page: 1);
                            },
                          ),
                          const SizedBox(height: 24),

                          // GAME GRID
                          Expanded(
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
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => GameDetailsScreen(
                                          name: game['name'] ?? 'Unknown',
                                          imageUrl:
                                              game['background_image'] ?? '',
                                          rating:
                                              (game['rating'] ?? 0).toDouble(),
                                          released:
                                              game['released'] ?? 'Unknown',
                                          description:
                                              game['description'] ??
                                              'No description available',
                                        ),
                                      ),
                                    );
                                  },
                                  child: GameCard(
                                    name: game['name'] ?? 'Unknown',
                                    imageUrl: game['background_image'] ?? '',
                                    rating: (game['rating'] ?? 0).toDouble(),
                                    released: game['released'] ?? 'Unknown',
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // PAGE NAVIGATION
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed:
                                    currentPage > 1 ? _previousPage : null,
                                child: const Text('Previous'),
                              ),
                              const SizedBox(width: 16),
                              Text('Page $currentPage'),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _nextPage,
                                child: const Text('Next'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
