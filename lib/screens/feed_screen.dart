import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/game_details_screen.dart';
import '../models/game.dart';

// Shows a feed of recent activity from the user's friends
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // App colour scheme
  static const _bg = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _accent = Color(0xFF00E5FF);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _border = Color(0xFF30363D);
  static const _gold = Color(0xFFFFD700);
  static const _green = Color(0xFF4ADE80);

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  bool _hasFriends = false;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    try {
      final uid = _auth.currentUser!.uid;

      // Get the current user's friend list
      final friendsSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('friends')
          .get();

      final friendUids = friendsSnap.docs.map((d) => d['uid'] as String).toList();

      if (friendUids.isEmpty) {
        if (mounted) setState(() { _isLoading = false; _hasFriends = false; });
        return;
      }

      _hasFriends = true;

      // Include own activity in the feed as well
      final allUids = [...friendUids, uid];

      List<Map<String, dynamic>> allActivities = [];

      // Firestore whereIn only supports 10 values at a time so we chunk the list
      for (int i = 0; i < allUids.length; i += 10) {
        final chunk = allUids.sublist(i, i + 10 > allUids.length ? allUids.length : i + 10);
        try {
          final snap = await _db
              .collection('activity')
              .where('uid', whereIn: chunk)
              .orderBy('timestamp', descending: true)
              .limit(50)
              .get();
          allActivities.addAll(snap.docs.map((d) => d.data()));
        } catch (e) {
          // Skip chunk if index not ready yet
        }
      }

      // Sort combined results by timestamp since we merged multiple chunks
      allActivities.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          // Only show the 30 most recent activities
          _activities = allActivities.take(30).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Converts a hex colour string stored in Firestore into a Flutter Color
  Color _getAvatarColor(String? hex) {
    if (hex == null) return _accent;
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return _accent;
    }
  }

  // Returns a human readable time string like "5m ago" or "2d ago"
  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final dt = timestamp.toDate();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // Builds the activity description text shown on each card
  String _activityText(Map<String, dynamic> activity) {
    final type = activity['type'] ?? '';
    final gameName = activity['gameName'] ?? 'a game';
    final status = activity['status'];
    if (type == 'reviewed') {
      if (status != null) return 'marked $gameName as $status';
      return 'reviewed $gameName';
    }
    if (type == 'favourited') return 'favourited $gameName';
    return 'did something with $gameName';
  }

  // Returns a colour based on the play status
  Color _statusColor(String? status) {
    switch (status) {
      case 'Completed': return _green;
      case 'Playing': return _accent;
      case 'Dropped': return Colors.redAccent;
      default: return _textSecondary;
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
        body: _isLoading
            ? Center(child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: _accent, strokeWidth: 2)))
            : !_hasFriends
                ? _buildNoFriends()
                : _activities.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadFeed,
                        color: _accent,
                        backgroundColor: _surface,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _activities.length,
                          itemBuilder: (context, index) => _buildActivityCard(_activities[index]),
                        ),
                      ),
      ),
    );
  }

  // Builds a single activity card — tapping navigates to that game's details
  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final username = activity['username'] ?? 'Unknown';
    final avatarColor = _getAvatarColor(activity['avatarColor']);
    final timestamp = activity['timestamp'] as Timestamp?;
    final gameImage = activity['gameImage'] ?? '';
    final gameName = activity['gameName'] ?? '';
    final rating = (activity['rating'] as num?)?.toDouble();
    final status = activity['status'] as String?;
    final type = activity['type'] ?? '';
    final gameId = activity['gameId'] ?? 0;

    return GestureDetector(
      onTap: () {
        // Navigate to game details when card is tapped
        final game = Game(
          id: gameId,
          name: gameName,
          backgroundImage: gameImage,
          rating: rating ?? 0,
          released: '',
        );
        Navigator.push(context, MaterialPageRoute(builder: (_) => GameDetailsScreen(game: game)));
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
            // Game cover image on the left
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: gameImage.isNotEmpty
                  ? Image.network(gameImage, width: 80, height: 100, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPlaceholder())
                  : _imgPlaceholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // User avatar circle with first letter of username
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [avatarColor, avatarColor.withOpacity(0.5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              username.isNotEmpty ? username[0].toUpperCase() : '?',
                              style: TextStyle(color: _bg, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Username bold + activity description
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: username, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Segoe UI')),
                                TextSpan(text: ' ${_activityText(activity)}', style: const TextStyle(color: _textSecondary, fontSize: 13, fontFamily: 'Segoe UI')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(gameName, style: const TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    // Bottom row — status badge, star rating, heart icon, timestamp
                    Row(
                      children: [
                        if (status != null && type == 'reviewed')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _statusColor(status).withOpacity(0.3)),
                            ),
                            child: Text(status, style: TextStyle(color: _statusColor(status), fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        if (rating != null && rating > 0 && type == 'reviewed') ...[
                          const SizedBox(width: 8),
                          Row(
                            children: List.generate(5, (i) => Icon(
                              rating > i ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: rating > i ? _gold : _textSecondary.withOpacity(0.3),
                              size: 12,
                            )),
                          ),
                        ],
                        if (type == 'favourited')
                          const Icon(Icons.favorite, color: Colors.redAccent, size: 14),
                        const Spacer(),
                        Text(_formatTime(timestamp), style: const TextStyle(color: _textSecondary, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fallback image when game cover fails to load
  Widget _imgPlaceholder() => Container(
    width: 80, height: 100, color: const Color(0xFF1C2333),
    child: const Icon(Icons.videogame_asset, color: _textSecondary, size: 24),
  );

  // Shown when user has no friends added yet
  Widget _buildNoFriends() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: _accent.withOpacity(0.15)),
              ),
              child: const Icon(Icons.people_outline, size: 40, color: _accent),
            ),
            const SizedBox(height: 16),
            const Text('No friends yet', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Add friends to see their activity here', style: TextStyle(color: _textSecondary, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // Shown when friends exist but none have any activity yet
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: _accent.withOpacity(0.15)),
              ),
              child: const Icon(Icons.dynamic_feed_outlined, size: 40, color: _accent),
            ),
            const SizedBox(height: 16),
            const Text('No activity yet', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('When your friends review or favourite games it will show up here', style: TextStyle(color: _textSecondary, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}