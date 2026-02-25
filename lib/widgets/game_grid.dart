import 'package:flutter/material.dart';
import '../models/game.dart';

class GameGrid extends StatefulWidget {
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
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

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
    if (widget.isLoading) return const Center(child: CircularProgressIndicator());

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(10),
      itemCount: widget.games.length + (widget.isNextPageLoading ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.6,
      ),
      itemBuilder: (context, index) {
        if (index >= widget.games.length) {
          // show loading spinner at bottom
          return const Center(child: CircularProgressIndicator());
        }

        final game = widget.games[index];

        return Card(
          elevation: 3,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (widget.onTapGame != null) widget.onTapGame!(game);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.network(
                    game.backgroundImage,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "⭐ ${game.rating}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      widget.favorites.contains(game.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color:
                          widget.favorites.contains(game.id) ? Colors.red : null,
                    ),
                    onPressed: () => widget.onToggleFavorite(game.id),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
