import 'package:flutter/material.dart';
import '../models/game.dart';
import '../widgets/game_card.dart';
import 'game_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final List<Game> favoriteGames;
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
      appBar: AppBar(title: const Text('Favorites')),
      body: favoriteGames.isEmpty
          ? const Center(child: Text('No favorites yet!'))
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 0.68,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: favoriteGames.length,
              itemBuilder: (context, index) {
                final game = favoriteGames[index];
                return GameCard(
                  name: game.name,
                  imageUrl: game.backgroundImage,
                  rating: game.rating,
                  released: game.released,
                  isFavorite: favorites.contains(game.id),
                  onFavoriteToggle: () => onToggleFavorite(game.id),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameDetailsScreen(game: game),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
