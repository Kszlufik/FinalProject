import 'package:flutter/material.dart';

class RecentlyViewedList extends StatelessWidget {
  final List<Map<String, dynamic>> recentlyViewed;
  final Function(Map<String, dynamic>) onTapGame;

  const RecentlyViewedList({
    super.key,
    required this.recentlyViewed,
    required this.onTapGame,
  });

  @override
  Widget build(BuildContext context) {
    if (recentlyViewed.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recentlyViewed.length,
        itemBuilder: (context, index) {
          final game = recentlyViewed[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: InkWell(
              onTap: () => onTapGame(game),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      game['background_image'] ?? '',
                      width: 100,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 100,
                    child: Text(
                      game['name'] ?? '',
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
