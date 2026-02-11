import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/game_card.dart';
import '../widgets/filters_bar.dart';
import 'game_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List games = [];
  bool isLoading = false;

  int currentPage = 1;
  int totalPages = 1;
  final int pageSize = 40;

  String ordering = '-rating';
  String genre = '';

  Set<int> favoriteGameIds = {};

  final String apiKey = '7ebe36a5b43249e995faab2bf81262bf';

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  Future<void> fetchGames() async {
    setState(() => isLoading = true);

    String url =
        'https://api.rawg.io/api/games?key=$apiKey&page_size=$pageSize&page=$currentPage&ordering=$ordering';

    if (genre.isNotEmpty) {
      url += '&genres=$genre';
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          games = data['results'];
          totalPages = (data['count'] / pageSize).ceil();
        });
      } else {
        debugPrint('API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching games: $e');
    }

    setState(() => isLoading = false);
  }

  void handleSortChange(String? value) {
    if (value == null) return;

    setState(() {
      ordering = value;
      currentPage = 1;
    });

    fetchGames();
  }

  void handleGenreChange(String? value) {
    if (value == null) return;

    setState(() {
      genre = value;
      currentPage = 1;
    });

    fetchGames();
  }

  void clearFilters() {
    setState(() {
      ordering = '-rating';
      genre = '';
      currentPage = 1;
    });

    fetchGames();
  }

  void goToPage(int page) {
    setState(() {
      currentPage = page;
    });

    fetchGames();
  }

  void toggleFavorite(int id) {
    setState(() {
      if (favoriteGameIds.contains(id)) {
        favoriteGameIds.remove(id);
      } else {
        favoriteGameIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PlayPal'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Fltering
                FiltersBar(
                  sortBy: ordering,
                  genre: genre,
                  onSortChange: handleSortChange,
                  onGenreChange: handleGenreChange,
                  onClearFilters: clearFilters,
                ),

                const SizedBox(height: 16),

                // smooth loading
                if (isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount =
                            (constraints.maxWidth / 250).floor();

                        if (crossAxisCount < 2) crossAxisCount = 2;

                        return GridView.builder(
                          itemCount: games.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          itemBuilder: (context, index) {
                            final game = games[index];

                            return GameCard(
                              name: game['name'] ?? '',
                              imageUrl:
                                  game['background_image'] ?? '',
                              rating:
                                  (game['rating'] ?? 0).toDouble(),
                              released:
                                  game['released'] ?? 'Unknown',
                              isFavorite:
                                  favoriteGameIds.contains(game['id']),
                              onFavoriteToggle: () =>
                                  toggleFavorite(game['id']),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        GameDetailsScreen(
                                      name: game['name'] ?? '',
                                      imageUrl: game[
                                              'background_image'] ??
                                          '',
                                      rating:
                                          (game['rating'] ?? 0)
                                              .toDouble(),
                                      released:
                                          game['released'] ??
                                              'Unknown',
                                      description:
                                          game['slug'] ??
                                              'No description available',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                // Ppagination
                if (!isLoading)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: currentPage > 1
                            ? () => goToPage(currentPage - 1)
                            : null,
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 20),
                      Text('Page $currentPage of $totalPages'),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: currentPage < totalPages
                            ? () => goToPage(currentPage + 1)
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
