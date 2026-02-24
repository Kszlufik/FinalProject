import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Services
import '../services/rawg_service.dart';
import '../services/user_service.dart';

// Widgets
import '../widgets/search_bar.dart';
import '../widgets/filters_bar.dart';
import '../widgets/game_grid.dart';
import '../widgets/recently_viewed_list.dart';
import '../widgets/left_panel.dart';

// Screens
import '../screens/game_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RawgService rawgService = RawgService();
  final UserService userService = UserService();

  List<dynamic> games = [];
  List<Map<String, dynamic>> recentlyViewed = [];
  Set<int> favoriteGameIds = {};

  bool isLoading = true;
  bool isNextPageLoading = false;
  int currentPage = 1;

  // Filters & search
  String sortBy = '-rating';
  String genre = '';
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await fetchGames();
    await loadFavorites();
    await loadRecentlyViewed();
  }

  Future<void> fetchGames({bool nextPage = false}) async {
    if (nextPage) {
      setState(() => isNextPageLoading = true);
      currentPage += 1;
    } else {
      setState(() {
        isLoading = true;
        currentPage = 1;
        games.clear();
      });
    }

    final result = await rawgService.fetchGames(
      page: currentPage,
      sortBy: sortBy,
      genre: genre,
      search: searchQuery,
    );

    setState(() {
      games.addAll(result);
      isLoading = false;
      isNextPageLoading = false;
    });
  }

  Future<void> loadFavorites() async {
    final ids = await userService.loadFavorites();
    setState(() => favoriteGameIds = ids);
  }

  Future<void> loadRecentlyViewed() async {
    final list = await userService.loadRecentlyViewed();
    setState(() => recentlyViewed = list);
  }

  void goToFavorites() {
    userService.goToFavorites(
        context, games, favoriteGameIds, () => loadFavorites());
  }

  void onSearch(String query) {
    searchQuery = query;
    fetchGames();
  }

  void onSortChange(String? value) {
    if (value == null) return;
    sortBy = value;
    fetchGames();
  }

  void onGenreChange(String? value) {
    if (value == null) return;
    genre = value;
    fetchGames();
  }

  void onClearFilters() {
    sortBy = '-rating';
    genre = '';
    searchController.clear();
    searchQuery = '';
    fetchGames();
  }

  Future<void> _navigateToGameDetails(Map<String, dynamic> game) async {
    if (!mounted) return;

    // Fetch full game details for description 
    Map<String, dynamic> fullGame;
    try {
      fullGame = await rawgService.fetchGameDetails(game['id'])
          .timeout(const Duration(seconds: 5), onTimeout: () => Map<String, dynamic>.from(game));
    } catch (e) {
      fullGame = Map<String, dynamic>.from(game);
    }

    if (!mounted) return;

    // Navigate first so user isn't waiting
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameDetailsScreen(
          name: fullGame['name'] ?? '',
          imageUrl: fullGame['background_image'] ?? '',
          rating: (fullGame['rating'] ?? 0).toDouble(),
          released: fullGame['released'] ?? 'Unknown',
          description: fullGame['description_raw'] ?? 'No description available.',
        ),
      ),
    );

    // Save to Firestore with timeoutthis was sdthe culprit in games not navigating to games details sscreen 
    userService.saveRecentlyViewed(fullGame)
        .timeout(const Duration(seconds: 5), onTimeout: () {})
        .then((_) {
          if (mounted) loadRecentlyViewed();
        })
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PlayPal'),
        actions: [
          IconButton(
            onPressed: goToFavorites,
            icon: const Icon(Icons.favorite),
          ),
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWideScreen) const LeftPanel(),
          Expanded(
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GameSearchBar(
                    controller: searchController,
                    onSubmitted: onSearch,
                  ),
                ),
                // Filters bar
                FiltersBar(
                  sortBy: sortBy,
                  genre: genre,
                  onSortChange: onSortChange,
                  onGenreChange: onGenreChange,
                  onClearFilters: onClearFilters,
                ),
                // Recently viewed
                RecentlyViewedList(
                  recentlyViewed: recentlyViewed,
                  onTapGame: (game) => _navigateToGameDetails(game),
                ),
                // Game grid
                Expanded(
                  child: GameGrid(
                    games: games,
                    favorites: favoriteGameIds,
                    isLoading: isLoading,
                    isNextPageLoading: isNextPageLoading,
                    onNextPage: () => fetchGames(nextPage: true),
                    onToggleFavorite: (id) async {
                      await userService.toggleFavorite(
                          id, games, favoriteGameIds);
                      if (!mounted) return;
                      setState(() {});
                    },
                    onTapGame: (game) => _navigateToGameDetails(game),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}