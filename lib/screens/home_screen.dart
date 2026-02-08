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
  final TextEditingController _searchController = TextEditingController();

  int currentPage = 1;
  String sortBy = 'rating';
  bool ascending = false;
  String? selectedGenre;

  final Map<String, String> genres = {
    'Action': '4',
    'Adventure': '3',
    'RPG': '5',
    'Shooter': '2',
    'Strategy': '10',
    'Sports': '15',
    'Racing': '1',
    'Fighting': '6',
    'Platformer': '83',
    'Horror': '11',
    'Casual': '40',
    'Indie': '51',
    'Educational': '13',
    'Simulation': '14',
    'Puzzle': '7',
    'Massively Multiplayer': '59',
  };

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  Future<void> fetchGames({int page = 1, String query = ''}) async {
    const apiKey = '7ebe36a5b43249e995faab2bf81262bf';
    String ordering = ascending ? sortBy : '-$sortBy';

    String url =
        'https://api.rawg.io/api/games?key=$apiKey&page_size=40&page=$page&ordering=$ordering';

    if (query.isNotEmpty) url += '&search=$query';
    if (selectedGenre != null) url += '&genres=$selectedGenre';

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

  void clearFilters() {
    _searchController.clear();
    selectedGenre = null;
    sortBy = 'rating';
    ascending = false;
    currentPage = 1;
    fetchGames(page: currentPage);
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
                          horizontal: 24, vertical: 24),
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
                              currentPage = 1;
                              fetchGames(
                                  page: currentPage, query: value.trim());
                            },
                          ),

                          const SizedBox(height: 16),

                          // SORT & FILTER CONTROLS
                          Row(
                            children: [
                              DropdownButton<String>(
                                value: sortBy,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'rating', child: Text('Rating')),
                                  DropdownMenuItem(
                                      value: 'released',
                                      child: Text('Release Date')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      sortBy = value;
                                    });
                                    fetchGames(
                                        page: currentPage,
                                        query: _searchController.text);
                                  }
                                },
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: Icon(ascending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward),
                                onPressed: () {
                                  setState(() {
                                    ascending = !ascending;
                                  });
                                  fetchGames(
                                      page: currentPage,
                                      query: _searchController.text);
                                },
                              ),
                              const SizedBox(width: 16),
                              DropdownButton<String>(
                                hint: const Text('Genre'),
                                value: selectedGenre,
                                items: genres.entries
                                    .map((e) => DropdownMenuItem(
                                        value: e.value, child: Text(e.key)))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedGenre = value;
                                  });
                                  fetchGames(
                                      page: currentPage,
                                      query: _searchController.text);
                                },
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: clearFilters,
                                child: const Text('Clear'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

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
                                          rating: (game['rating'] ?? 0)
                                              .toDouble(),
                                          released: game['released'] ?? 'Unknown',
                                          description:
                                              game['description_raw'] ??
                                                  'No description available.',
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

                          // PAGINATION
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: currentPage > 1
                                    ? () {
                                        setState(() => currentPage--);
                                        fetchGames(
                                            page: currentPage,
                                            query: _searchController.text);
                                      }
                                    : null,
                                child: const Text('Previous'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: games.length == 40
                                    ? () {
                                        setState(() => currentPage++);
                                        fetchGames(
                                            page: currentPage,
                                            query: _searchController.text);
                                      }
                                    : null,
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
