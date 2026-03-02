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
  static const _bg = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _surface2 = Color(0xFF1C2333);
  static const _accent = Color(0xFF00E5FF);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _border = Color(0xFF30363D);
  static const _gold = Color(0xFFFFD700);

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
    if (mounted) setState(() { reviews = data; isLoading = false; });
  }

  List<Map<String, dynamic>> get filteredReviews {
    if (selectedStatusFilter == 'All') return reviews;
    return reviews.where((r) => r['status'] == selectedStatusFilter).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed': return const Color(0xFF4ADE80);
      case 'Playing': return _accent;
      case 'Dropped': return Colors.redAccent;
      default: return _textSecondary;
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

  int _countForStatus(String status) {
    if (status == 'All') return reviews.length;
    return reviews.where((r) => r['status'] == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(primary: _accent, surface: _surface),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: _textSecondary, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.rate_review, color: _accent, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('My Reviews', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _border),
          ),
        ),
        body: isLoading
            ? Center(child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: _accent, strokeWidth: 2)))
            : reviews.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                      _buildStatsBar(),
                      _buildStatusFilters(),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredReviews.length,
                          itemBuilder: (context, index) => _buildReviewCard(filteredReviews[index]),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildStatsBar() {
    final completed = reviews.where((r) => r['status'] == 'Completed').length;
    final playing = reviews.where((r) => r['status'] == 'Playing').length;
    final dropped = reviews.where((r) => r['status'] == 'Dropped').length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: _surface,
      child: Row(
        children: [
          _statPill('${reviews.length}', 'Total', _accent),
          const SizedBox(width: 8),
          _statPill('$completed', 'Completed', const Color(0xFF4ADE80)),
          const SizedBox(width: 8),
          _statPill('$playing', 'Playing', _accent),
          const SizedBox(width: 8),
          _statPill('$dropped', 'Dropped', Colors.redAccent),
        ],
      ),
    );
  }

  Widget _statPill(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: _textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Container(
      height: 52,
      color: _bg,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: statusOptions.map((status) {
          final isSelected = selectedStatusFilter == status;
          final count = _countForStatus(status);
          final color = status == 'All' ? _accent : _statusColor(status);
          return GestureDetector(
            onTap: () => setState(() => selectedStatusFilter = status),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? color.withOpacity(0.5) : _border),
              ),
              child: Text(
                '$status  $count',
                style: TextStyle(
                  color: isSelected ? color : _textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final status = review['status'] ?? 'Playing';
    final personalRating = (review['personalRating'] as num?)?.toDouble() ?? 0;
    final reviewText = review['reviewText']?.toString() ?? '';
    final statusColor = _statusColor(status);

    return GestureDetector(
      onTap: () async {
        final game = Game(
          id: review['gameId'],
          name: review['gameName'] ?? 'Unknown',
          backgroundImage: review['imageUrl'] ?? '',
          rating: (review['rating'] as num?)?.toDouble() ?? 0,
          released: review['released'] ?? '',
        );
        await Navigator.push(context, MaterialPageRoute(builder: (_) => GameDetailsScreen(game: game)));
        _loadReviews();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game image
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
              child: review['imageUrl'] != null && review['imageUrl'].toString().isNotEmpty
                  ? Image.network(
                      review['imageUrl'],
                      width: 90,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['gameName'] ?? 'Unknown',
                      style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            '${_statusEmoji(status)} $status',
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        // Stars
                        Row(
                          children: List.generate(5, (i) => Icon(
                            personalRating > i ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: personalRating > i ? _gold : _textSecondary.withOpacity(0.3),
                            size: 15,
                          )),
                        ),
                      ],
                    ),
                    if (reviewText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        reviewText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _textSecondary, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 14),
              child: Icon(Icons.chevron_right, color: _textSecondary.withOpacity(0.4), size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 90,
      height: 110,
      color: _surface2,
      child: const Icon(Icons.videogame_asset, color: _textSecondary, size: 28),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: _accent.withOpacity(0.2)),
            ),
            child: const Icon(Icons.rate_review_outlined, size: 48, color: _accent),
          ),
          const SizedBox(height: 20),
          const Text('No reviews yet', style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Long press any game card to write a review', style: TextStyle(color: _textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}