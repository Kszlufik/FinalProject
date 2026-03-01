import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/user_service.dart';
import '../widgets/review_dialog.dart';

class GameDetailsScreen extends StatefulWidget {
  final Game game;

  const GameDetailsScreen({super.key, required this.game});

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  final UserService _userService = UserService();
  Map<String, dynamic>? existingReview;
  bool isLoadingReview = true;

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  Future<void> _loadReview() async {
    final review = await _userService.loadReview(widget.game.id);
    if (mounted) {
      setState(() {
        existingReview = review;
        isLoadingReview = false;
      });
    }
  }

  Future<void> _openReviewDialog() async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) => ReviewDialog(
        gameName: widget.game.name,
        existingReview: existingReview,
      ),
    );

    if (result == null) return; // user cancelled

    if (result == 'delete') {
      await _userService.deleteReview(widget.game.id);
      if (mounted) setState(() => existingReview = null);
      return;
    }

    // Save the review
    await _userService.saveReview(
      gameId: widget.game.id,
      gameName: widget.game.name,
      reviewText: result['reviewText'],
      personalRating: result['personalRating'],
      status: result['status'],
    );

    if (mounted) {
      setState(() => existingReview = result);
    }
  }

  String _statusEmoji(String status) {
    switch (status) {
      case 'Completed': return '✅';
      case 'Playing': return '🎮';
      case 'Dropped': return '❌';
      default: return '🎮';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game.name),
        actions: [
          IconButton(
            icon: Icon(
              existingReview != null ? Icons.rate_review : Icons.rate_review_outlined,
              color: existingReview != null
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: _openReviewDialog,
            tooltip: existingReview != null ? 'Edit Review' : 'Write Review',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.game.backgroundImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Game name
                  Text(
                    widget.game.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),

                  // Rating and release
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(widget.game.rating.toString()),
                      const SizedBox(width: 24),
                      Text('Released: ${widget.game.released}'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Platforms
                  if (widget.game.platforms.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: widget.game.platforms.map((p) => Chip(
                        label: Text(p, style: const TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                      )).toList(),
                    ),

                  const SizedBox(height: 24),

                  // Description
                  Text(
                    widget.game.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 32),

                  // Review section
                  const Divider(),
                  const SizedBox(height: 16),

                  if (isLoadingReview)
                    const Center(child: CircularProgressIndicator())
                  else if (existingReview != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Review',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextButton.icon(
                          onPressed: _openReviewDialog,
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_statusEmoji(existingReview!['status'])} ${existingReview!['status']}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Personal star rating
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          (existingReview!['personalRating'] as num) > index
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 24,
                        );
                      }),
                    ),
                    const SizedBox(height: 12),

                    // Review text
                    if (existingReview!['reviewText'] != null &&
                        existingReview!['reviewText'].toString().isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          existingReview!['reviewText'],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                  ] else ...[
                    // No review yet
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No review yet',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _openReviewDialog,
                            icon: const Icon(Icons.edit),
                            label: const Text('Write a Review'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}