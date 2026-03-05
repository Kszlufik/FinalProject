import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/game.dart';
import 'game_details_screen.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;
  String selectedStatusFilter = 'All';

  final List<String> statusOptions = ['All', 'Playing', 'Completed', 'Dropped'];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final data = await _userService.loadAllReviews();
    if (mounted) {
      setState(() {
        reviews = data;
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredReviews {
    if (selectedStatusFilter == 'All') return reviews;
    return reviews.where((r) => r['status'] == selectedStatusFilter).toList();
  }

  String _statusEmoji(String status) {
    switch (status) {
      case 'Completed': return '✅';
      case 'Playing': return '🎮';
      case 'Dropped': return '❌';
      default: return '🎮';
    }
  }

  Color _statusColor(String status, BuildContext context) {
    switch (status) {
      case 'Completed': return Colors.green.shade100;
      case 'Playing': return Colors.blue.shade100;
      case 'Dropped': return Colors.red.shade100;
      default: return Colors.grey.shade100;
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'Completed': return Colors.green.shade800;
      case 'Playing': return Colors.blue.shade800;
      case 'Dropped': return Colors.red.shade800;
      default: return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reviews'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reviews yet!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Long press any game card to write a review',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 54,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        children: statusOptions.map((status) {
                          final isSelected = selectedStatusFilter == status;
                          final count = status == 'All'
                              ? reviews.length
                              : reviews
                                  .where((r) => r['status'] == status)
                                  .length;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text('$status ($count)'),
                              selected: isSelected,
                              onSelected: (_) => setState(
                                  () => selectedStatusFilter = status),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(height: 1),

                    
                    // Here we put reviwes list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredReviews.length,
                        itemBuilder: (context, index) {
                          final review = filteredReviews[index];
                          final status = review['status'] ?? 'Playing';
                          final personalRating =
                              (review['personalRating'] as num?)?.toDouble() ??
                                  0;
                          final reviewText =
                              review['reviewText']?.toString() ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final game = Game(
                                  id: review['gameId'],
                                  name: review['gameName'] ?? 'Unknown',
                                  backgroundImage: review['imageUrl'] ?? '',
                                  rating: (review['rating'] as num?)
                                          ?.toDouble() ??
                                      0,
                                  released: review['released'] ?? 'Unknown',
                                );
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        GameDetailsScreen(game: game),
                                  ),
                                );

                               // Reload to check if revew was ever editedf 
                                _loadReviews();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [


                                    // Game image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: review['imageUrl'] != null &&
                                              review['imageUrl']
                                                  .toString()
                                                  .isNotEmpty
                                          ? Image.network(
                                              review['imageUrl'],
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _placeholderImage(),
                                            )
                                          : _placeholderImage(),
                                    ),
                                    const SizedBox(width: 16),

                                    
                                    // Review details 
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Game name
                                          Text(
                                            review['gameName'] ?? 'Unknown',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 6),


                                          // Status badge
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: _statusColor(
                                                      status, context),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${_statusEmoji(status)} $status',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: _statusTextColor(
                                                        status),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              // Star rating
                                              Row(
                                                children: List.generate(5,
                                                    (i) {
                                                  return Icon(
                                                    personalRating > i
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    color: Colors.amber,
                                                    size: 16,
                                                  );
                                                }),
                                              ),
                                            ],
                                          ),
                                          // Review text snippet
                                          if (reviewText.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              reviewText,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.videogame_asset, color: Colors.grey.shade400),
    );
  }
}