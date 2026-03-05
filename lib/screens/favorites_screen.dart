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
    final allPlatforms = favoriteGames
        .expand((g) => g.platforms)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...allPlatforms];
  }

  List<Game> get filteredGames {
    if (selectedPlatformFilter == 'All') return favoriteGames;
    return favoriteGames
        .where((g) => g.platforms.contains(selectedPlatformFilter))
        .toList();
  }

  String _platformEmoji(String platform) {
    if (platform.toLowerCase().contains('pc')) return '🖥️';
    if (platform.toLowerCase().contains('playstation')) return '🎮';
    if (platform.toLowerCase().contains('xbox')) return '🟩';
    if (platform.toLowerCase().contains('nintendo')) return '🔴';
    if (platform.toLowerCase().contains('ios') ||
        platform.toLowerCase().contains('android')) return '📱';
    return '🎮';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteGames.isEmpty
              ? const Center(child: Text('No favorites yet!'))
              : Column(
                  children: [
                    if (availablePlatforms.length > 1)
                      SizedBox(
                        height: 50,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: availablePlatforms.map((platform) {
                            final isSelected = selectedPlatformFilter == platform;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                              child: FilterChip(
                                label: Text(
                                  platform == 'All'
                                      ? 'All'
                                      : '${_platformEmoji(platform)} $platform',
                                ),
                                selected: isSelected,
                                onSelected: (_) => setState(
                                    () => selectedPlatformFilter = platform),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          childAspectRatio: 0.55,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
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
                                MaterialPageRoute(
                                  builder: (_) =>
                                      GameDetailsScreen(game: game),
                                ),
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
    );
  }
}