import 'package:flutter/material.dart';
import '../models/game.dart';
import '../widgets/game_card.dart';

// Responsive game grid with infinite scroll — loads more games as you near the bottom
class GameGrid extends StatefulWidget {
  final List<Game> games;
  final Set<int> favorites;
  final Set<int> reviewedGameIds;
  final bool isLoading;
  final bool isNextPageLoading;
  final VoidCallback onNextPage;
  final Function(int) onToggleFavorite;
  final Function(Game)? onTapGame;
  final VoidCallback onReviewSaved;

  const GameGrid({
    super.key,
    required this.games,
    required this.favorites,
    required this.reviewedGameIds,
    required this.isLoading,
    required this.isNextPageLoading,
    required this.onNextPage,
    required this.onToggleFavorite,
    this.onTapGame,
    required this.onReviewSaved,
  });

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Trigger next page load when user reaches 80% of the way down
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          !widget.isNextPageLoading &&
          !widget.isLoading) {
        widget.onNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show spinner while first page is loading
    if (widget.isLoading) return const Center(child: CircularProgressIndicator());

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(10),
      // +1 item slot at the end to show a loading spinner when fetching the next page
      itemCount: widget.games.length + (widget.isNextPageLoading ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.55,
      ),
      itemBuilder: (context, index) {
        // Last slot shows a spinner while the next page loads
        if (index >= widget.games.length) {
          return const Center(child: CircularProgressIndicator());
        }

        final game = widget.games[index];

        return GameCard(
          gameId: game.id,
          name: game.name,
          gameName: game.name,
          imageUrl: game.backgroundImage,
          rating: game.rating,
          released: game.released,
          isFavorite: widget.favorites.contains(game.id),
          hasReview: widget.reviewedGameIds.contains(game.id),
          onFavoriteToggle: () => widget.onToggleFavorite(game.id),
          onTap: () {
            if (widget.onTapGame != null) widget.onTapGame!(game);
          },
          onReviewSaved: widget.onReviewSaved,
        );
      },
    );
  }
}