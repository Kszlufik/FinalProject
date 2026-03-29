import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game.dart';
import 'game_details_screen.dart';

// Shows a friend's public profile — their reviews, favourites and stats
class FriendProfileScreen extends StatefulWidget {
  final String friendUid;
  final String username;

  const FriendProfileScreen({super.key, required this.friendUid, required this.username});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  // App colour scheme
  static const _bg = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _surface2 = Color(0xFF1C2333);
  static const _accent = Color(0xFF00E5FF);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _border = Color(0xFF30363D);
  static const _gold = Color(0xFFFFD700);
  static const _green = Color(0xFF4ADE80);

  final _db = FirebaseFirestore.instance;

  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Load profile, reviews and favourites in parallel using Future.wait
  Future<void> _loadProfile() async {
    try {
      final results = await Future.wait([
        _db.collection('users').doc(widget.friendUid).get(),
        _db.collection('users').doc(widget.friendUid).collection('reviews').orderBy('timestamp', descending: true).limit(20).get(),
        _db.collection('users').doc(widget.friendUid).collection('favorites').orderBy('timestamp', descending: true).limit(20).get(),
      ]);

      final userDoc = results[0] as DocumentSnapshot;
      final reviewsSnap = results[1] as QuerySnapshot;
      final favoritesSnap = results[2] as QuerySnapshot;

      if (mounted) {
        setState(() {
          _userProfile = userDoc.data() as Map<String, dynamic>?;
          _reviews = reviewsSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
          _favorites = favoritesSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Returns colour based on play status
  Color _statusColor(String status) {
    switch (status) {
      case 'Completed': return _green;
      case 'Playing': return _accent;
      case 'Dropped': return Colors.redAccent;
      default: return _textSecondary;
    }
  }

  // Returns emoji based on play status
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
          title: Text(widget.username, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: _border)),
        ),
        body: _isLoading
            ? Center(child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: _accent, strokeWidth: 2)))
            : SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(),
                        _buildStatsRow(),
                        _buildTabBar(),
                        _buildTabContent(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // Header showing avatar, username, email and currently playing game if any
  Widget _buildProfileHeader() {
    final email = _userProfile?['email'] ?? '';
    final username = _userProfile?['username'] ?? widget.username;

    // Check if the friend is currently playing anything
    final playing = _reviews.where((r) => r['status'] == 'Playing').toList();
    final currentGame = playing.isNotEmpty ? playing.first['gameName'] : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          // Avatar circle with first letter of username
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_accent, _accent.withOpacity(0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: _accent.withOpacity(0.25), blurRadius: 16)],
            ),
            child: Center(
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: const TextStyle(color: _bg, fontWeight: FontWeight.bold, fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: const TextStyle(color: _textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: _textSecondary, fontSize: 13)),
                // Show currently playing badge if applicable
                if (currentGame != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _accent.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Green pulsing dot to indicate active status
                        Container(width: 7, height: 7, decoration: BoxDecoration(color: _green, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _green.withOpacity(0.6), blurRadius: 4)])),
                        const SizedBox(width: 6),
                        Text('Playing: $currentGame', style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Stats bar showing review count, completed, playing, favourites and average rating
  Widget _buildStatsRow() {
    final completed = _reviews.where((r) => r['status'] == 'Completed').length;
    final playing = _reviews.where((r) => r['status'] == 'Playing').length;
    final avgRating = _reviews.isNotEmpty
        ? _reviews.map((r) => (r['personalRating'] as num?)?.toDouble() ?? 0).reduce((a, b) => a + b) / _reviews.length
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      color: _bg,
      child: Row(
        children: [
          _statCard('${_reviews.length}', 'Reviews', _accent),
          const SizedBox(width: 10),
          _statCard('$completed', 'Completed', _green),
          const SizedBox(width: 10),
          _statCard('$playing', 'Playing', _accent),
          const SizedBox(width: 10),
          _statCard('${_favorites.length}', 'Favourites', Colors.redAccent),
          const SizedBox(width: 10),
          _statCard(avgRating > 0 ? '${avgRating.toStringAsFixed(1)}★' : '-', 'Avg Rating', _gold),
        ],
      ),
    );
  }

  // Individual stat card widget
  Widget _statCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: _textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // Tab selector for Reviews and Favourites
  Widget _buildTabBar() {
    final tabs = ['Reviews', 'Favourites'];
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final i = e.key;
          final label = e.value;
          final isSelected = _selectedTab == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _accent.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? _accent.withOpacity(0.4) : _border),
              ),
              child: Text(label, style: TextStyle(color: isSelected ? _accent : _textSecondary, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Switches between reviews and favourites tab content
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0: return _buildReviews();
      case 1: return _buildFavorites();
      default: return const SizedBox.shrink();
    }
  }

  // List of the friend's reviews with status badge and star rating
  Widget _buildReviews() {
    if (_reviews.isEmpty) {
      return _emptyState(Icons.rate_review_outlined, 'No reviews yet');
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        final status = review['status'] ?? 'Playing';
        final rating = (review['personalRating'] as num?)?.toDouble() ?? 0;
        final statusColor = _statusColor(status);

        return GestureDetector(
          onTap: () {
            // Tap to open that game's details screen
            final game = Game(
              id: review['gameId'] ?? 0,
              name: review['gameName'] ?? '',
              backgroundImage: review['imageUrl'] ?? '',
              rating: 0,
              released: '',
            );
            Navigator.push(context, MaterialPageRoute(builder: (_) => GameDetailsScreen(game: game)));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
                  child: review['imageUrl'] != null && review['imageUrl'].toString().isNotEmpty
                      ? Image.network(review['imageUrl'], width: 80, height: 90, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imgPlaceholder())
                      : _imgPlaceholder(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(review['gameName'] ?? 'Unknown', style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.3))),
                              child: Text('${_statusEmoji(status)} $status', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const Spacer(),
                            Row(children: List.generate(5, (i) => Icon(rating > i ? Icons.star_rounded : Icons.star_outline_rounded, color: rating > i ? _gold : _textSecondary.withOpacity(0.3), size: 13))),
                          ],
                        ),
                        if ((review['reviewText'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(review['reviewText'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _textSecondary, fontSize: 11, height: 1.4)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Grid of the friend's favourited games
  Widget _buildFavorites() {
    if (_favorites.isEmpty) return _emptyState(Icons.favorite_outline, 'No favourites yet');
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final fav = _favorites[index];
        return GestureDetector(
          onTap: () {
            final game = Game(id: fav['gameId'] ?? 0, name: fav['name'] ?? '', backgroundImage: fav['imageUrl'] ?? '', rating: (fav['rating'] as num?)?.toDouble() ?? 0, released: fav['released'] ?? '');
            Navigator.push(context, MaterialPageRoute(builder: (_) => GameDetailsScreen(game: game)));
          },
          child: Container(
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                  child: fav['imageUrl'] != null && fav['imageUrl'].toString().isNotEmpty
                      ? Image.network(fav['imageUrl'], height: 100, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 100, color: _surface2))
                      : Container(height: 100, color: _surface2, child: const Icon(Icons.videogame_asset, color: _textSecondary)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fav['name'] ?? 'Unknown', style: const TextStyle(color: _textPrimary, fontSize: 11, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                      if ((fav['rating'] as num?)?.toDouble() != null) ...[
                        const SizedBox(height: 4),
                        Row(children: [const Icon(Icons.star_rounded, color: _gold, size: 11), const SizedBox(width: 2), Text('${(fav['rating'] as num).toStringAsFixed(1)}', style: const TextStyle(color: _gold, fontSize: 10))]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Fallback image for missing game covers
  Widget _imgPlaceholder() => Container(width: 80, height: 90, color: _surface2, child: const Icon(Icons.videogame_asset, color: _textSecondary, size: 24));

  // Generic empty state widget used by both tabs
  Widget _emptyState(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: _textSecondary.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: _textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}