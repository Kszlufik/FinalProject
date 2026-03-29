import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/rawg_service.dart';
import 'package:playpal/services/user_service.dart';
import '../widgets/game_grid.dart';
import '../widgets/filters_bar.dart';
import '../widgets/recently_viewed_list.dart';
import '../widgets/left_panel.dart';
import '../screens/game_details_screen.dart';
import '../screens/reviews_screen.dart';
import '../screens/steam_screen.dart';
import '../screens/friends_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/feed_screen.dart';
import '../models/game.dart';

// Main screen — handles game discovery, feed tab, navigation and filters
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // App colour scheme
  static const _bg = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _accent = Color(0xFF00E5FF);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _border = Color(0xFF30363D);

  // Key needed to open/close the mobile drawer programmatically
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final RawgService rawgService = RawgService();
  final UserService userService = UserService();

  List<Game> games = [];
  List<Game> recentlyViewed = [];
  Set<int> favoriteGameIds = {};
  Set<int> reviewedGameIds = {};
  int _pendingRequestCount = 0;
  int _selectedTab = 0; // 0 = Discover, 1 = Feed

  bool isLoading = true;
  bool isNextPageLoading = false;
  int currentPage = 1;

  // Filter and sort state
  String sortBy = '-rating';
  String genre = '';
  String searchQuery = '';
  String platform = '';
  String dates = '';
  String selectedPreset = 'Top Rated';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchGames();
    loadFavorites();
    loadReviewedGameIds();
    loadRecentlyViewed();
    _loadPendingRequests();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Load count of pending friend requests for the orange badge on the friends button
  Future<void> _loadPendingRequests() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('friendRequests')
          .get();
      if (mounted) setState(() => _pendingRequestCount = snap.docs.length);
    } catch (_) {}
  }

  Future<void> loadFavorites() async {
    final ids = await userService.loadFavorites();
    if (mounted) setState(() => favoriteGameIds = ids);
  }

  Future<void> loadReviewedGameIds() async {
    final ids = await userService.loadReviewedGameIds();
    if (mounted) setState(() => reviewedGameIds = ids);
  }

  // Fetches games from RAWG — supports pagination via nextPage flag
  Future<void> fetchGames({bool nextPage = false}) async {
    if (nextPage) {
      if (isNextPageLoading) return;
      setState(() => isNextPageLoading = true);
      currentPage += 1;
    } else {
      // Fresh load — reset page and clear existing results
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
      platform: platform,
      dates: dates,
    );

    setState(() {
      games.addAll(result.map((json) => Game.fromJson(json)).toList());
      isLoading = false;
      isNextPageLoading = false;
    });
  }

  Future<void> loadRecentlyViewed() async {
    final list = await userService.loadRecentlyViewed();
    setState(() => recentlyViewed = list);
  }

  void goToFavorites() {
    userService.goToFavorites(context, favoriteGameIds, () => loadFavorites());
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

  // Resets all filters back to defaults
  void onClearFilters() {
    sortBy = '-rating';
    genre = '';
    platform = '';
    dates = '';
    selectedPreset = 'Top Rated';
    searchController.clear();
    searchQuery = '';
    fetchGames();
  }

  void onPlatformChange(String newPlatform) {
    setState(() => platform = newPlatform);
    fetchGames();
  }

  void onPresetChange(String newSortBy, String newDates) {
    setState(() {
      sortBy = newSortBy;
      dates = newDates;
      selectedPreset = '';
    });
    fetchGames();
  }

  // Fetches full game details before navigating — falls back to basic data on timeout
  Future<void> _navigateToGameDetails(Game game) async {
    if (!mounted) return;
    Game fullGame;
    try {
      final json = await rawgService
          .fetchGameDetails(game.id)
          .timeout(const Duration(seconds: 5), onTimeout: () => {});
      fullGame = Game.fromJson({...json, 'id': game.id, 'name': game.name});
    } catch (_) {
      fullGame = game;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameDetailsScreen(game: fullGame)),
    );
    // Refresh reviewed IDs and recently viewed when returning from details
    if (mounted) loadReviewedGameIds();
    userService
        .saveRecentlyViewed(fullGame)
        .timeout(const Duration(seconds: 5), onTimeout: () {})
        .then((_) {
          if (mounted) loadRecentlyViewed();
        })
        .catchError((_) {});
  }

  // Reload pending request count when returning from friends screen
  Future<void> _goToFriends() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FriendsScreen()),
    );
    if (mounted) _loadPendingRequests();
  }

  Future<void> _goToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  // Sign out with confirmation dialog
  Future<void> _confirmSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign out', style: TextStyle(color: _textPrimary)),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm == true) FirebaseAuth.instance.signOut();
  }

  // Mobile drawer — replaces the left panel on screens under 900px
  Widget _buildMobileDrawer() {
    final now = DateTime.now();
    final thisYear = '${now.year}-01-01,${now.year}-12-31';
    final last30Days =
        '${now.subtract(const Duration(days: 30)).toIso8601String().substring(0, 10)},${now.toIso8601String().substring(0, 10)}';
    final next90Days =
        '${now.toIso8601String().substring(0, 10)},${now.add(const Duration(days: 90)).toIso8601String().substring(0, 10)}';

    final presets = [
      {'label': 'Top Rated', 'sortBy': '-rating', 'dates': '', 'icon': '⭐'},
      {'label': 'Most Popular', 'sortBy': '-added', 'dates': '', 'icon': '🔥'},
      {'label': 'New Releases', 'sortBy': '-released', 'dates': last30Days, 'icon': '🆕'},
      {'label': 'Coming Soon', 'sortBy': '-added', 'dates': next90Days, 'icon': '🚀'},
      {'label': 'Best of ${now.year}', 'sortBy': '-rating', 'dates': thisYear, 'icon': '🏆'},
    ];

    final platforms = [
      {'label': 'All Platforms', 'id': '', 'icon': '🌐'},
      {'label': 'PC', 'id': '4', 'icon': '🖥️'},
      {'label': 'PlayStation', 'id': '187,18', 'icon': '🎮'},
      {'label': 'Xbox', 'id': '186,1', 'icon': '🟩'},
      {'label': 'Nintendo', 'id': '7', 'icon': '🔴'},
      {'label': 'Mobile', 'id': '21,3', 'icon': '📱'},
    ];

    return Drawer(
      backgroundColor: _bg,
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drawer header with PlayPal logo
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accent.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.sports_esports, color: _accent, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'PlayPal',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Discover presets section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: Text(
                      'DISCOVER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  ...presets.map((p) => _drawerTile(
                    icon: p['icon']!,
                    label: p['label']!,
                    isSelected: selectedPreset == p['label'],
                    onTap: () {
                      onPresetChange(p['sortBy']!, p['dates']!);
                      _scaffoldKey.currentState?.closeDrawer();
                    },
                  )),
                  Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4)),
                  // Platform filter section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: Text(
                      'PLATFORMS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  ...platforms.map((p) => _drawerTile(
                    icon: p['icon']!,
                    label: p['label']!,
                    isSelected: platform == p['id'],
                    onTap: () {
                      onPlatformChange(p['id']!);
                      _scaffoldKey.currentState?.closeDrawer();
                    },
                  )),
                  Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4)),
                  // Navigation links section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: Text(
                      'NAVIGATE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  _drawerTile(
                    icon: '🎮',
                    label: 'Steam',
                    isSelected: false,
                    onTap: () {
                      _scaffoldKey.currentState?.closeDrawer();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SteamScreen()));
                    },
                  ),
                  _drawerTile(
                    icon: '⭐',
                    label: 'My Reviews',
                    isSelected: false,
                    onTap: () async {
                      _scaffoldKey.currentState?.closeDrawer();
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsScreen()));
                      if (mounted) loadReviewedGameIds();
                    },
                  ),
                  _drawerTile(
                    icon: '❤️',
                    label: 'Favourites',
                    isSelected: false,
                    onTap: () {
                      _scaffoldKey.currentState?.closeDrawer();
                      goToFavorites();
                    },
                  ),
                ],
              ),
            ),
          ),
          // Profile shortcut at the bottom of the drawer
          GestureDetector(
            onTap: () {
              _scaffoldKey.currentState?.closeDrawer();
              _goToProfile();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [_accent, _accent.withOpacity(0.5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (FirebaseAuth.instance.currentUser?.email ?? '?')[0].toUpperCase(),
                        style: const TextStyle(color: _bg, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      FirebaseAuth.instance.currentUser?.email ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: _textPrimary),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: _textSecondary, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable drawer navigation tile with selected state highlight
  Widget _drawerTile({
    required String icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? _accent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? _accent.withOpacity(0.4) : Colors.transparent),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? _accent : _textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            // Small dot indicator for selected item
            if (isSelected) ...[
              const Spacer(),
              Container(
                width: 5, height: 5,
                decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Switch between desktop (left panel) and mobile (drawer) at 900px
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(primary: _accent, surface: _surface),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _bg,
        drawer: !isWideScreen ? _buildMobileDrawer() : null,
        body: Row(
          children: [
            // Left panel only shown on wide screens
            if (isWideScreen)
              LeftPanel(
                onPlatformChange: onPlatformChange,
                onPresetChange: onPresetChange,
                selectedPlatform: platform,
                selectedPreset: selectedPreset,
                onProfileTap: _goToProfile,
              ),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(isWideScreen),
                  // Discover / Feed tab switcher
                  Container(
                    color: _surface,
                    child: Row(
                      children: [
                        _buildTab('Discover', 0),
                        _buildTab('Feed', 1),
                      ],
                    ),
                  ),
                  Container(height: 1, color: _border),
                  Expanded(
                    child: _selectedTab == 0
                        ? Column(
                            children: [
                              _buildSearchAndFilters(),
                              if (recentlyViewed.isNotEmpty)
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    textTheme: Theme.of(context).textTheme.apply(bodyColor: _textPrimary),
                                  ),
                                  child: RecentlyViewedList(
                                    recentlyViewed: recentlyViewed,
                                    onTapGame: _navigateToGameDetails,
                                  ),
                                ),
                              Expanded(
                                child: GameGrid(
                                  games: games,
                                  favorites: favoriteGameIds,
                                  reviewedGameIds: reviewedGameIds,
                                  isLoading: isLoading,
                                  isNextPageLoading: isNextPageLoading,
                                  onNextPage: () => fetchGames(nextPage: true),
                                  onToggleFavorite: (id) async {
                                    await userService.toggleFavorite(id, games, favoriteGameIds);
                                    await loadFavorites();
                                  },
                                  onTapGame: _navigateToGameDetails,
                                  onReviewSaved: () => loadReviewedGameIds(),
                                ),
                              ),
                            ],
                          )
                        // UniqueKey forces FeedScreen to rebuild and reload every time the tab is opened
                        : FeedScreen(key: UniqueKey()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tab button with animated underline indicator
  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: isSelected ? _accent : Colors.transparent, width: 2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _accent : _textSecondary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Top navigation bar — adapts padding and button sizes for narrow screens
  Widget _buildTopBar(bool isWideScreen) {
    final isNarrow = MediaQuery.of(context).size.width < 400;

    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 16),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          // Hamburger menu only on mobile
          if (!isWideScreen) ...[
            IconButton(
              icon: const Icon(Icons.menu, color: _accent, size: 22),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              tooltip: 'Menu',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            SizedBox(width: isNarrow ? 4 : 8),
          ],
          Expanded(
            child: Text(
              'PlayPal',
              style: TextStyle(
                color: _textPrimary,
                fontSize: isNarrow ? 14 : 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Mobile shows fewer buttons to avoid overflow on narrow screens
          if (!isWideScreen) ...[
            _topBarButton(icon: Icons.person_outline, tooltip: 'My Profile', onTap: _goToProfile),
            SizedBox(width: isNarrow ? 2 : 4),
            _friendsButton(),
            SizedBox(width: isNarrow ? 2 : 4),
            _topBarButton(icon: Icons.logout_outlined, tooltip: 'Sign out', onTap: _confirmSignOut, color: _textSecondary),
          ] else ...[
            // Desktop shows all buttons
            _topBarButton(icon: Icons.person_outline, tooltip: 'My Profile', onTap: _goToProfile),
            const SizedBox(width: 4),
            _friendsButton(),
            const SizedBox(width: 4),
            _topBarButton(
              icon: Icons.videogame_asset_outlined,
              tooltip: 'Steam',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SteamScreen())),
            ),
            const SizedBox(width: 4),
            _topBarButton(
              icon: Icons.rate_review_outlined,
              tooltip: 'My Reviews',
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsScreen()));
                if (mounted) loadReviewedGameIds();
              },
            ),
            const SizedBox(width: 4),
            _topBarButton(icon: Icons.favorite_outline, tooltip: 'Favourites', onTap: goToFavorites, color: Colors.redAccent),
            const SizedBox(width: 4),
            _topBarButton(icon: Icons.logout_outlined, tooltip: 'Sign out', onTap: _confirmSignOut, color: _textSecondary),
          ],
        ],
      ),
    );
  }

  // Friends button with orange notification badge for pending requests
  Widget _friendsButton() {
    final isNarrow = MediaQuery.of(context).size.width < 400;
    return Tooltip(
      message: 'Friends',
      child: InkWell(
        onTap: _goToFriends,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: EdgeInsets.all(isNarrow ? 6 : 8),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.people_outline, color: _accent, size: isNarrow ? 18 : 20),
            ),
            // Badge only shows when there are pending requests
            if (_pendingRequestCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: _bg, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$_pendingRequestCount',
                    style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Reusable top bar icon button — scales down on narrow screens
  Widget _topBarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = _accent,
  }) {
    final isNarrow = MediaQuery.of(context).size.width < 400;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(isNarrow ? 6 : 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: isNarrow ? 18 : 20),
        ),
      ),
    );
  }

  // Search bar and filters bar below it
  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      color: _bg,
      child: Column(
        children: [
          TextField(
            controller: searchController,
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search games...',
              hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5), fontSize: 13),
              filled: true,
              fillColor: _surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent, width: 1.5)),
              prefixIcon: const Icon(Icons.search, color: _textSecondary, size: 18),
              // Clear button appears when there is an active search query
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: _textSecondary, size: 16),
                      onPressed: () {
                        searchController.clear();
                        onSearch('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onSubmitted: onSearch,
          ),
          const SizedBox(height: 6),
          // Filters bar with sort and genre dropdowns
          Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: _accent, surface: _surface),
              chipTheme: ChipThemeData(
                backgroundColor: _surface,
                selectedColor: _accent.withOpacity(0.2),
                labelStyle: const TextStyle(color: _textSecondary, fontSize: 12),
                secondaryLabelStyle: const TextStyle(color: _accent, fontSize: 12),
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              dropdownMenuTheme: DropdownMenuThemeData(
                menuStyle: MenuStyle(backgroundColor: WidgetStatePropertyAll(_surface)),
              ),
            ),
            child: FiltersBar(
              sortBy: sortBy,
              genre: genre,
              onSortChange: onSortChange,
              onGenreChange: onGenreChange,
              onClearFilters: onClearFilters,
            ),
          ),
        ],
      ),
    );
  }
}