import 'package:flutter/material.dart';
import '../models/game.dart';
import 'game_card.dart';

class GameGrid extends StatelessWidget {
  final List<Game> games;
  final Set<int> favorites;
  final bool isLoading;
  final bool isNextPageLoading;
  final VoidCallback onNextPage;
  final Function(int) onToggleFavorite;
  final Function(Game)? onTapGame;

  const GameGrid({
    super.key,
    required this.games,
    required this.favorites,
    required this.isLoading,
    required this.isNextPageLoading,
    required this.onNextPage,
    required this.onToggleFavorite,
    this.onTapGame,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: games.length + 1,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.6,
      ),
      itemBuilder: (context, index) {
        if (index == games.length) {
          return isNextPageLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: onNextPage,
                    child: const Text("Next Page"),
                  ),
                );
        }

        final game = games[index];

        return GameCard(
          name: game.name,
          imageUrl: game.backgroundImage,
          rating: game.rating,
          released: game.released,
          isFavorite: favorites.contains(game.id),
          onFavoriteToggle: () => onToggleFavorite(game.id),
          onTap: () => onTapGame?.call(game),
        );
      },
    );
  }
}
