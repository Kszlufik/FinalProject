import 'package:flutter/material.dart';

class GameGrid extends StatelessWidget {
  final List<dynamic> games;
  final Set<int> favorites;
  final bool isLoading;
  final bool isNextPageLoading;
  final VoidCallback onNextPage;
  final Function(int) onToggleFavorite;
  final Function(Map<String, dynamic>)? onTapGame;

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
        final id = game['id'];

        // ✅ FIX: Card wraps InkWell, not the other way around.
        // InkWell outside Card is blocked by the Card's Material layer.
        return Card(
          elevation: 3,
          clipBehavior: Clip.antiAlias, // ✅ keeps tap ripple within card corners
          child: InkWell(
            onTap: () {
            print('🟢 CARD TAPPED: ${game['name']}');
            if (onTapGame != null) {
           print('🟡 calling onTapGame');
           onTapGame!(game);
          } else {
           print('🔴 onTapGame is NULL');
       }
},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.network(
                    game['background_image'] ?? '',
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
                        game['name'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "⭐ ${game['rating']}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      favorites.contains(id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: favorites.contains(id) ? Colors.red : null,
                    ),
                    onPressed: () => onToggleFavorite(id),
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