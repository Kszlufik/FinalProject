import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../widgets/review_dialog.dart';

class GameCard extends StatelessWidget {
  final int gameId;
  final String name;
  final String imageUrl;
  final double rating;
  final String released;
  final bool isFavorite;
  final bool hasReview;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;
  final String gameName;

  const GameCard({
    super.key,
    required this.gameId,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.released,
    this.isFavorite = false,
    this.hasReview = false,
    required this.onFavoriteToggle,
    required this.onTap,
    required this.gameName,
  });

  Future<void> _openReviewDialog(BuildContext context) async {
    final userService = UserService();
    final existingReview = await userService.loadReview(gameId);

    if (!context.mounted) return;

    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) => ReviewDialog(
        gameName: gameName,
        existingReview: existingReview,
      ),
    );

    if (result == null) return;

    if (result == 'delete') {
      await userService.deleteReview(gameId);
      return;
    }

    await userService.saveReview(
      gameId: gameId,
      gameName: gameName,
      reviewText: result['reviewText'],
      personalRating: result['personalRating'],
      status: result['status'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _openReviewDialog(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.expand(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: onFavoriteToggle,
                  ),
                ),
                // Review indicator badge
                if (hasReview)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.rate_review,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(rating.toString()),
            ],
          ),
          const SizedBox(height: 4),
          Text('Released: $released', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          // Long press hint
          Text(
            'Hold to review',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}