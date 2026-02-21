import 'package:flutter/material.dart';
import '../widgets/game_card.dart';
import 'game_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final List favoriteGames;
  final Set<int> favorites;
  final Function(int) onToggleFavorite;

  const FavoritesScreen({
    super.key,
    required this.favoriteGames,
    required this.favorites,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: favoriteGames.isEmpty
                ? const Center(child: Text('No favorites yet!'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = (constraints.maxWidth / 250).floor();
                      if (crossAxisCount < 2) crossAxisCount = 2;

                      return GridView.builder(
                        itemCount: favoriteGames.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemBuilder: (context, index) {
                          final game = favoriteGames[index];
                          return GameCard(
                            name: game['name'] ?? '',
                            imageUrl: game['background_image'] ?? '',
                            rating: (game['rating'] ?? 0).toDouble(),
                            released: game['released'] ?? 'Unknown',
                            isFavorite: favorites.contains(game['id']),
                            onFavoriteToggle: () => onToggleFavorite(game['id']),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GameDetailsScreen(
                                    name: game['name'] ?? '',
                                    imageUrl: game['background_image'] ?? '',
                                    rating: (game['rating'] ?? 0).toDouble(),
                                    released: game['released'] ?? 'Unknown',
                                    description: game['slug'] ?? 'No description available',
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
        ),
      ),
    );
  }
}
