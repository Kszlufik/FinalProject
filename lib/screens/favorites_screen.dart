import 'package:flutter/material.dart';
import '../models/game.dart';
import '../widgets/game_card.dart';
import '../services/user_service.dart';
import 'game_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final Set<int> favorites;
  final Function(int) onToggleFavorite;

  const FavoritesScreen({
    super.key,
    required this.favorites,
    required this.onToggleFavorite,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const _bg = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _accent = Color(0xFF00E5FF);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _border = Color(0xFF30363D);

  final UserService _userService = UserService();
  List<Game> favoriteGames = [];
  Set<int> reviewedGameIds = {};
  bool isLoading = true;
  String selectedPlatformFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final games = await _userService.loadFavoriteGames();
    final ids = await _userService.loadReviewedGameIds();
    if (mounted) {
      setState(() {
        favoriteGames = games;
        reviewedGameIds = ids;
        isLoading = false;
      });
    }
  }

  List<String> get availablePlatforms {
    final all = favoriteGames.expand((g) => g.platforms).toSet().toList()..sort();
    return ['All', ...all];
  }

  List<Game> get filteredGames {
    if (selectedPlatformFilter == 'All') return favoriteGames;
    return favoriteGames.where((g) => g.platforms.contains(selectedPlatformFilter)).toList();
  }

  String _platformEmoji(String platform) {
    if (platform.toLowerCase().contains('pc')) return '🖥️';
    if (platform.toLowerCase().contains('playstation')) return '🎮';
    if (platform.toLowerCase().contains('xbox')) return '🟩';
    if (platform.toLowerCase().contains('nintendo')) return '🔴';
    if (platform.toLowerCase().contains('ios') || platform.toLowerCase().contains('android')) return '📱';
    return '🎮';
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
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.favorite, color: Colors.redAccent, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Favourites', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _border),
          ),
        ),
        body: isLoading
            ? Center(child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: _accent, strokeWidth: 2)))
            : favoriteGames.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                      if (availablePlatforms.length > 1) _buildPlatformFilters(),
                      // Count bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                        child: Row(
                          children: [
                            Text(
                              '${filteredGames.length} games',
                              style: const TextStyle(color: _textSecondary, fontSize: 12),
                            ),
                            const Spacer(),
                            const Icon(Icons.favorite, color: Colors.redAccent, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${favoriteGames.length} total',
                              style: const TextStyle(color: _textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 0.55,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredGames.length,
                          itemBuilder: (context, index) {
                            final game = filteredGames[index];
                            return GameCard(
                              gameId: game.id,
                              gameName: game.name,
                              name: game.name,
                              imageUrl: game.backgroundImage,
                              rating: game.rating,
                              released: game.released,
                              isFavorite: widget.favorites.contains(game.id),
                              hasReview: reviewedGameIds.contains(game.id),
                              onFavoriteToggle: () async {
                                await widget.onToggleFavorite(game.id);
                                await _loadData();
                              },
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => GameDetailsScreen(game: game)),
                                );
                                await _loadData();
                              },
                              onReviewSaved: () => _loadData(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildPlatformFilters() {
    return Container(
      height: 52,
      color: _bg,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: availablePlatforms.map((platform) {
          final isSelected = selectedPlatformFilter == platform;
          return GestureDetector(
            onTap: () => setState(() => selectedPlatformFilter = platform),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? _accent.withOpacity(0.15) : _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? _accent.withOpacity(0.5) : _border),
              ),
              child: Text(
                platform == 'All' ? '🌐  All' : '${_platformEmoji(platform)}  $platform',
                style: TextStyle(
                  color: isSelected ? _accent : _textSecondary,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
            ),
            child: const Icon(Icons.favorite_outline, size: 48, color: Colors.redAccent),
          ),
          const SizedBox(height: 20),
          const Text('No favourites yet', style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tap the heart on any game to save it here', style: TextStyle(color: _textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}