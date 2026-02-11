// lib/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import '../widgets/game_card.dart';

class FavoritesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> favoriteGames;
  final Function(Map<String, dynamic>) onRemoveFavorite;

  const FavoritesScreen({
    super.key,
    required this.favoriteGames,
    required this.onRemoveFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favoriteGames.isEmpty
          ? const Center(child: Text('No favorites yet.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemCount: favoriteGames.length,
                itemBuilder: (context, index) {
                  final game = favoriteGames[index];
                  return GameCard(
                    name: game['name'],
                    imageUrl: game['background_image'] ?? '',
                    rating: (game['rating'] ?? 0).toDouble(),
                    released: game['released'] ?? 'Unknown',
                    isFavorite: true,
                    onFavoriteToggle: () => onRemoveFavorite(game),
                    onTap: () {
                      // navigate to game details if needed
                    },
                  );
                },
              ),
            ),
    );
  }
}
