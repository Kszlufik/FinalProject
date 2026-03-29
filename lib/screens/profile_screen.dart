import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/steam_service.dart';
import 'game_details_screen.dart';
import '../models/game.dart';

// The user's own profile — editable username, bio, avatar colour, stats and tabs
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  // Colour options available for the avatar picker
  static const List<Color> _avatarColors = [
    Color(0xFF00E5FF), Color(0xFF7C3AED), Color(0xFFEC4899), Color(0xFFF97316),
    Color(0xFF10B981), Color(0xFFEAB308), Color(0xFF3B82F6), Color(0xFFEF4444),
  ];

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String get _uid => _auth.currentUser!.uid;

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _favorites = [];
  Map<String, dynamic>? _steamData;

  bool _isLoading = true;
  bool _isLoadingSteam = false;
  int _selectedTab = 0;

  // Inline edit state for username and bio
  bool _isEditingUsername = false;
  bool _isEditingBio = false;
  bool _isSaving = false;
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _editError;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Load profile, reviews and favourites all at once using Future.wait
  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        _db.collection('users').doc(_uid).get(),
        _db.collection('users').doc(_uid).collection('reviews').orderBy('timestamp', descending: true).get(),
        _db.collection('users').doc(_uid).collection('favorites').orderBy('timestamp', descending: true).get(),
      ]);

      final userDoc = results[0] as DocumentSnapshot;
      final reviewsSnap = results[1] as QuerySnapshot;
      final favSnap = results[2] as QuerySnapshot;
      final profile = userDoc.data() as Map<String, dynamic>? ?? {};

      if (mounted) {
        setState(() {
          _profile = profile;
          _reviews = reviewsSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
          _favorites = favSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
          _usernameController.text = profile['username'] ?? '';
          _bioController.text = profile['bio'] ?? '';
          _isLoading = false;
        });
      }

      // If Steam is connected, load the library summary
      if (profile['steamId'] != null) {
        _loadSteam(profile['steamId']);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSteam(String steamId) async {
    setState(() => _isLoadingSteam = true);
    try {
      final steamService = SteamService();
      final data = await steamService.getSteamGames(steamId);
      if (mounted) setState(() { _steamData = data; _isLoadingSteam = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingSteam = false);
    }
  }

  // Save updated username — checks uniqueness in the usernames collection first
  Future<void> _saveUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty || newUsername.length < 3) {
      setState(() => _editError = 'Username must be at least 3 characters.');
      return;
    }
    if (newUsername == _profile?['username']) {
      setState(() => _isEditingUsername = false);
      return;
    }

    setState(() { _isSaving = true; _editError = null; });

    try {
      // Check the usernames lookup collection for conflicts
      final existing = await _db.collection('usernames').doc(newUsername.toLowerCase()).get();
      if (existing.exists) {
        setState(() { _editError = 'That username is already taken.'; _isSaving = false; });
        return;
      }

      // Remove the old username reservation and create a new one
      final oldUsername = _profile?['usernameLower'];
      if (oldUsername != null) {
        await _db.collection('usernames').doc(oldUsername).delete();
      }

      await Future.wait([
        _db.collection('users').doc(_uid).update({
          'username': newUsername,
          'usernameLower': newUsername.toLowerCase(),
        }),
        _db.collection('usernames').doc(newUsername.toLowerCase()).set({'uid': _uid}),
      ]);

      setState(() {
        _profile!['username'] = newUsername;
        _profile!['usernameLower'] = newUsername.toLowerCase();
        _isEditingUsername = false;
        _isSaving = false;
      });
      _showSnack('Username updated!', _green);
    } catch (e) {
      setState(() { _editError = e.toString(); _isSaving = false; });
    }
  }

  // Save bio — straightforward Firestore update
  Future<void> _saveBio() async {
    final bio = _bioController.text.trim();
    setState(() { _isSaving = true; _editError = null; });
    try {
      await _db.collection('users').doc(_uid).update({'bio': bio});
      setState(() { _profile!['bio'] = bio; _isEditingBio = false; _isSaving = false; });
      _showSnack('Bio updated!', _green);
    } catch (e) {
      setState(() { _editError = e.toString(); _isSaving = false; });
    }
  }

  // Save chosen avatar colour as a hex string in Firestore
  Future<void> _saveAvatarColor(Color color) async {
    final colorHex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    try {
      await _db.collection('users').doc(_uid).update({'avatarColor': colorHex});
      setState(() => _profile!['avatarColor'] = colorHex);
      _showSnack('Avatar colour updated!', _green);
    } catch (_) {}
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: _textPrimary)),
      backgroundColor: color.withOpacity(0.2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // Converts hex colour string stored in Firestore into a Flutter Color
  Color _getAvatarColor() {
    final hex = _profile?['avatarColor'];
    if (hex == null) return _accent;
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return _accent;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed': return _green;
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
          title: const Text('My Profile', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
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
                        _buildHeader(),
                        _buildStatsRow(),
                        if (_profile?['steamId'] != null) _buildSteamSummary(),
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

  // Profile header — avatar, username, email, bio, member since date
  Widget _buildHeader() {
    final username = _profile?['username'] ?? _auth.currentUser?.email ?? 'You';
    final email = _profile?['email'] ?? _auth.currentUser?.email ?? '';
    final bio = _profile?['bio'];
    final avatarColor = _getAvatarColor();
    final createdAt = _profile?['createdAt'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar circle — tap to open colour picker
              GestureDetector(
                onTap: _showAvatarColorPicker,
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [avatarColor, avatarColor.withOpacity(0.5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [BoxShadow(color: avatarColor.withOpacity(0.3), blurRadius: 20)],
                      ),
                      child: Center(
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : '?',
                          style: const TextStyle(color: _bg, fontWeight: FontWeight.bold, fontSize: 32),
                        ),
                      ),
                    ),
                    // Paint palette icon to indicate tappable
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _surface2,
                          shape: BoxShape.circle,
                          border: Border.all(color: _border),
                        ),
                        child: const Icon(Icons.palette_outlined, color: _textSecondary, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username — shows inline edit field or display row
                    if (_isEditingUsername)
                      _editField(
                        controller: _usernameController,
                        onSave: _saveUsername,
                        onCancel: () => setState(() { _isEditingUsername = false; _editError = null; _usernameController.text = _profile?['username'] ?? ''; }),
                        hint: 'Username',
                      )
                    else
                      Row(
                        children: [
                          Text(username, style: const TextStyle(color: _textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _isEditingUsername = true),
                            child: const Icon(Icons.edit_outlined, color: _textSecondary, size: 16),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Text(email, style: const TextStyle(color: _textSecondary, fontSize: 13)),
                    if (createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text('Member since ${_formatDate(createdAt)}', style: const TextStyle(color: _textSecondary, fontSize: 11)),
                    ],
                    const SizedBox(height: 10),
                    // Bio — shows inline edit field or tappable text
                    if (_isEditingBio)
                      _editField(
                        controller: _bioController,
                        onSave: _saveBio,
                        onCancel: () => setState(() { _isEditingBio = false; _editError = null; _bioController.text = _profile?['bio'] ?? ''; }),
                        hint: 'Write a short bio...',
                        maxLines: 2,
                      )
                    else
                      GestureDetector(
                        onTap: () => setState(() => _isEditingBio = true),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                bio != null && bio.toString().isNotEmpty ? bio : 'Add a bio...',
                                style: TextStyle(
                                  color: bio != null && bio.toString().isNotEmpty ? _textSecondary : _textSecondary.withOpacity(0.4),
                                  fontSize: 13,
                                  fontStyle: bio == null || bio.toString().isEmpty ? FontStyle.italic : FontStyle.normal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.edit_outlined, color: _textSecondary, size: 14),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Inline error message for edit failures
          if (_editError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_editError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Inline edit field with save and cancel buttons
  Widget _editField({
    required TextEditingController controller,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    required String hint,
    int maxLines = 1,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _textSecondary.withOpacity(0.4), fontSize: 13),
              filled: true,
              fillColor: _surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _accent, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (_isSaving)
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
        else ...[
          // Save button
          GestureDetector(
            onTap: onSave,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: _green.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: _green.withOpacity(0.3))),
              child: const Icon(Icons.check, color: _green, size: 16),
            ),
          ),
          const SizedBox(width: 6),
          // Cancel button
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
              child: const Icon(Icons.close, color: Colors.redAccent, size: 16),
            ),
          ),
        ],
      ],
    );
  }

  // Dialog to pick avatar colour from the preset palette
  void _showAvatarColorPicker() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Choose avatar colour', style: TextStyle(color: _textPrimary, fontSize: 16)),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _avatarColors.map((color) {
            final isSelected = _getAvatarColor() == color;
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _saveAvatarColor(color);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                  boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)] : null,
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Stats bar showing review counts, play statuses, favourites and average rating
  Widget _buildStatsRow() {
    final completed = _reviews.where((r) => r['status'] == 'Completed').length;
    final playing = _reviews.where((r) => r['status'] == 'Playing').length;
    final dropped = _reviews.where((r) => r['status'] == 'Dropped').length;
    final avgRating = _reviews.isNotEmpty
        ? _reviews.map((r) => (r['personalRating'] as num?)?.toDouble() ?? 0).reduce((a, b) => a + b) / _reviews.length
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      color: _bg,
      child: Row(
        children: [
          _statCard('${_reviews.length}', 'Reviews', _accent),
          const SizedBox(width: 8),
          _statCard('$completed', 'Completed', _green),
          const SizedBox(width: 8),
          _statCard('$playing', 'Playing', _accent),
          const SizedBox(width: 8),
          _statCard('$dropped', 'Dropped', Colors.redAccent),
          const SizedBox(width: 8),
          _statCard('${_favorites.length}', 'Favourites', Colors.pinkAccent),
          const SizedBox(width: 8),
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
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: _textSecondary, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  // Small Steam summary card shown when a Steam account is connected
  Widget _buildSteamSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1B2838).withOpacity(0.8)),
      ),
      child: _isLoadingSteam
          ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: _accent, strokeWidth: 2)))
          : _steamData == null
              ? const Text('Could not load Steam data', style: TextStyle(color: _textSecondary, fontSize: 13))
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF1B2838), borderRadius: BorderRadius.circular(8)),
                      child: Image.network('https://store.steampowered.com/favicon.ico', width: 20, height: 20, errorBuilder: (_, __, ___) => const Icon(Icons.videogame_asset, color: _textSecondary, size: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Steam Library', style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('${_steamData!['totalGames'] ?? 0} games · ${_steamData!['totalHours']?.toStringAsFixed(0) ?? 0} hours played', style: const TextStyle(color: _textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _accent.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: _accent.withOpacity(0.2))),
                      child: const Text('Connected', style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
    );
  }

  // Tab switcher between Reviews and Favourites
  Widget _buildTabBar() {
    final tabs = ['Reviews', 'Favourites'];
    return Container(
      color: _surface,
      margin: const EdgeInsets.only(top: 16),
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

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0: return _buildReviews();
      case 1: return _buildFavorites();
      default: return const SizedBox.shrink();
    }
  }

  // List of user's own reviews — tappable to open game details
  Widget _buildReviews() {
    if (_reviews.isEmpty) return _emptyState(Icons.rate_review_outlined, 'No reviews yet', 'Head to a game and write your first review!');
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
            final game = Game(id: review['gameId'] ?? 0, name: review['gameName'] ?? '', backgroundImage: review['imageUrl'] ?? '', rating: 0, released: '');
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

  // Grid of user's favourited games
  Widget _buildFavorites() {
    if (_favorites.isEmpty) return _emptyState(Icons.favorite_outline, 'No favourites yet', 'Heart a game to save it here!');
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
                      if ((fav['rating'] as num?) != null) ...[
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

  // Fallback placeholder for missing game cover images
  Widget _imgPlaceholder() => Container(width: 80, height: 90, color: _surface2, child: const Icon(Icons.videogame_asset, color: _textSecondary, size: 24));

  // Generic empty state for both tabs
  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: _textSecondary.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: _textSecondary, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // Converts a Firestore Timestamp to a readable date string
  String _formatDate(dynamic timestamp) {
    try {
      final dt = (timestamp as Timestamp).toDate();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}