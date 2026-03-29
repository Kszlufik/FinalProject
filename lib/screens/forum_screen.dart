import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Full discussion thread for a specific game
class ForumScreen extends StatefulWidget {
  final int gameId;
  final String gameName;

  const ForumScreen({super.key, required this.gameId, required this.gameName});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  // App colour scheme
  static const _bg = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _surface2 = Color(0xFF1C2333);
  static const _accent = Color(0xFF00E5FF);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _border = Color(0xFF30363D);
  static const _gold = Color(0xFFFFD700);

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _controller = TextEditingController();
  bool _isPosting = false;

  // Shorthand getters used throughout the screen
  String get _uid => _auth.currentUser!.uid;
  String get _gameDocId => widget.gameId.toString();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Post a new comment to this game's forum thread
  Future<void> _postComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);

    try {
      // Fetch username and avatar colour from Firestore profile
      final userDoc = await _db.collection('users').doc(_uid).get();
      final username = userDoc.data()?['username'] ?? _auth.currentUser?.email ?? 'Unknown';
      final avatarColor = userDoc.data()?['avatarColor'] ?? '#00E5FF';

      await _db
          .collection('forums')
          .doc(_gameDocId)
          .collection('posts')
          .add({
        'uid': _uid,
        'username': username,
        'avatarColor': avatarColor,
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'likeCount': 0,
      });

      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  // Toggle like on a post using Firestore array operations
  Future<void> _toggleLike(String postId, List likes) async {
    final ref = _db.collection('forums').doc(_gameDocId).collection('posts').doc(postId);
    if (likes.contains(_uid)) {
      // Already liked — remove like
      await ref.update({
        'likes': FieldValue.arrayRemove([_uid]),
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      // Not liked yet — add like
      await ref.update({
        'likes': FieldValue.arrayUnion([_uid]),
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  // Delete a post after confirmation dialog
  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete comment', style: TextStyle(color: _textPrimary)),
        content: const Text('Are you sure you want to delete this comment?', style: TextStyle(color: _textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: _textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, elevation: 0),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.collection('forums').doc(_gameDocId).collection('posts').doc(postId).delete();
    }
  }

  // Converts hex colour string from Firestore into a Flutter Color
  Color _getAvatarColor(String? hex) {
    if (hex == null) return _accent;
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return _accent;
    }
  }

  // Returns a human readable relative time string
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
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Discussion', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(widget.gameName, style: const TextStyle(color: _textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
          bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: _border)),
        ),
        body: Column(
          children: [
            // Real time post list using Firestore stream
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('forums')
                    .doc(_gameDocId)
                    .collection('posts')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: _accent, strokeWidth: 2)));
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forum_outlined, size: 48, color: _textSecondary.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          const Text('No comments yet', style: TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('Be the first to start the discussion!', style: TextStyle(color: _textSecondary, fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  // Find the post with the most likes to award the top comment badge
                  String? topPostId;
                  int maxLikes = 0;
                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final likes = (data['likeCount'] as num?)?.toInt() ?? 0;
                    if (likes > maxLikes) {
                      maxLikes = likes;
                      topPostId = doc.id;
                    }
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final isTop = doc.id == topPostId && maxLikes > 0;
                      return _buildPostCard(doc.id, data, isTop);
                    },
                  );
                },
              ),
            ),

            // Comment input at the bottom
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: _surface,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: _textPrimary, fontSize: 14),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts...',
                        hintStyle: TextStyle(color: _textSecondary.withOpacity(0.4), fontSize: 13),
                        filled: true,
                        fillColor: _surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Show spinner while posting, send button otherwise
                  _isPosting
                      ? SizedBox(width: 44, height: 44, child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
                      : InkWell(
                          onTap: _postComment,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: _accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.send_rounded, color: _bg, size: 20),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds a single post card — gold border if it's the top comment
  Widget _buildPostCard(String postId, Map<String, dynamic> data, bool isTop) {
    final username = data['username'] ?? 'Unknown';
    final message = data['message'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final likes = List<dynamic>.from(data['likes'] ?? []);
    final likeCount = (data['likeCount'] as num?)?.toInt() ?? 0;
    final avatarColor = _getAvatarColor(data['avatarColor']);
    final isOwn = data['uid'] == _uid;
    final hasLiked = likes.contains(_uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        // Gold border for top comment, normal border otherwise
        border: Border.all(
          color: isTop ? _gold.withOpacity(0.5) : _border,
          width: isTop ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar circle with first letter of username
                Container(
                  width: 32, height: 32,
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
                      style: TextStyle(color: _bg, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(username, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                          // Trophy badge shown only on the top comment
                          if (isTop) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _gold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _gold.withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.emoji_events, color: _gold, size: 11),
                                  SizedBox(width: 3),
                                  Text('Top Comment', style: TextStyle(color: _gold, fontSize: 9, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(_formatTime(timestamp), style: const TextStyle(color: _textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                // Delete button only visible on the user's own posts
                if (isOwn)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: _textSecondary.withOpacity(0.5), size: 18),
                    onPressed: () => _deletePost(postId),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(message, style: const TextStyle(color: _textPrimary, fontSize: 14, height: 1.5)),
            const SizedBox(height: 10),
            // Like button — highlighted if current user has liked this post
            Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(postId, likes),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: hasLiked ? _accent.withOpacity(0.12) : _surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: hasLiked ? _accent.withOpacity(0.4) : _border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                          color: hasLiked ? _accent : _textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$likeCount',
                          style: TextStyle(
                            color: hasLiked ? _accent : _textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}