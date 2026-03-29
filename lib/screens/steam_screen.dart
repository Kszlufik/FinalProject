import 'package:flutter/material.dart';
import '../services/steam_service.dart';

// Steam integration screen — connect account, browse library and view achievements
class SteamScreen extends StatefulWidget {
  const SteamScreen({super.key});

  @override
  State<SteamScreen> createState() => _SteamScreenState();
}

class _SteamScreenState extends State<SteamScreen> {
  final SteamService _steamService = SteamService();
  final TextEditingController _steamIdController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // App colour scheme
  static const _bg = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _surface2 = Color(0xFF1C2333);
  static const _accent = Color(0xFF00E5FF);
  static const _accentDim = Color(0xFF00B8D4);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _gold = Color(0xFFFFD700);
  static const _border = Color(0xFF30363D);

  String? steamId;
  Map<String, dynamic>? profile;
  Map<String, dynamic>? gamesData;
  Map<String, dynamic>? achievementsData;

  bool isLoadingProfile = false;
  bool isLoadingGames = false;
  bool isLoadingAchievements = false;
  String? errorMessage;
  int? selectedAppId;
  String? selectedGameName;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSavedSteamId();
  }

  @override
  void dispose() {
    _steamIdController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Load previously saved Steam ID from Firestore on screen open
  Future<void> _loadSavedSteamId() async {
    final saved = await _steamService.loadSteamId();
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() => steamId = saved);
      _steamIdController.text = saved;
      await _loadProfile(saved);
    }
  }

  // Load Steam profile via Cloud Function — saves ID on success
  Future<void> _loadProfile(String id) async {
    setState(() { isLoadingProfile = true; errorMessage = null; });
    try {
      final p = await _steamService.getSteamProfile(id);
      await _steamService.saveSteamId(id);
      setState(() { profile = p; steamId = id; isLoadingProfile = false; });
      await _loadGames(id);
    } catch (e) {
      setState(() {
        isLoadingProfile = false;
        errorMessage = 'Could not load Steam profile. Check your ID and make sure your profile is public.';
      });
    }
  }

  // Load the user's full Steam game library
  Future<void> _loadGames(String id) async {
    setState(() => isLoadingGames = true);
    try {
      final data = await _steamService.getSteamGames(id);
      setState(() { gamesData = data; isLoadingGames = false; });
    } catch (e) {
      setState(() { isLoadingGames = false; });
    }
  }

  // Toggle achievement panel for a game — collapse if already selected
  Future<void> _loadAchievements(int appId, String gameName) async {
    if (selectedAppId == appId) {
      setState(() { selectedAppId = null; selectedGameName = null; achievementsData = null; });
      return;
    }
    setState(() {
      isLoadingAchievements = true;
      selectedAppId = appId;
      selectedGameName = gameName;
      achievementsData = null;
      errorMessage = null;
    });
    try {
      final data = await _steamService.getSteamAchievements(steamId!, appId);
      setState(() { achievementsData = data; isLoadingAchievements = false; });
    } catch (e) {
      setState(() { isLoadingAchievements = false; achievementsData = null; });
    }
  }

  void _onConnect() {
    final id = _steamIdController.text.trim();
    if (id.isEmpty) return;
    _loadProfile(id);
  }

  // Clear all Steam data and remove saved ID from Firestore
  void _onDisconnect() {
    setState(() {
      steamId = null; profile = null; gamesData = null;
      achievementsData = null; selectedAppId = null;
      selectedGameName = null; searchQuery = '';
      _steamIdController.clear(); _searchController.clear();
    });
    _steamService.saveSteamId('');
  }

  // Filter game list by search query
  List<dynamic> get filteredGames {
    if (gamesData == null) return [];
    final games = gamesData!['games'] as List;
    if (searchQuery.isEmpty) return games;
    return games.where((g) =>
        g['name'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();
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
                child: const Icon(Icons.videogame_asset, color: _accent, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Steam', style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _border),
          ),
          // Disconnect button only visible when connected
          actions: [
            if (profile != null)
              TextButton.icon(
                onPressed: _onDisconnect,
                icon: const Icon(Icons.link_off, color: Colors.redAccent, size: 16),
                label: const Text('Disconnect', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (profile == null && !isLoadingProfile) _buildConnectCard(),
                  if (errorMessage != null) _buildError(),
                  if (isLoadingProfile) _buildLoadingState('Loading Steam profile...'),
                  if (profile != null) ...[
                    _buildProfileHero(),
                    const SizedBox(height: 16),
                    _buildStatsBar(),
                    const SizedBox(height: 28),
                    _buildGamesSection(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Input card for entering Steam ID before connecting
  Widget _buildConnectCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _accent.withOpacity(0.05), blurRadius: 30)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _accent.withOpacity(0.3)),
                ),
                child: const Icon(Icons.videogame_asset, color: _accent, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Connect Steam', style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Link your library, games & achievements', style: TextStyle(color: _textSecondary, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Your Steam ID', style: TextStyle(color: _textSecondary, fontSize: 12, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _steamIdController,
                  style: const TextStyle(color: _textPrimary),
                  decoration: InputDecoration(
                    hintText: '76561198000000000 or profile URL',
                    hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5), fontSize: 13),
                    filled: true,
                    fillColor: _bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _accent, width: 1.5)),
                    prefixIcon: const Icon(Icons.tag, color: _textSecondary, size: 18),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onSubmitted: (_) => _onConnect(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoadingProfile ? null : _onConnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: _bg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: const Text('Connect', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Find your Steam ID at steamid.io  •  Profile must be set to Public',
            style: TextStyle(color: _textSecondary.withOpacity(0.6), fontSize: 11),
          ),
        ],
      ),
    );
  }

  // Red error banner
  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
        ],
      ),
    );
  }

  // Spinner shown while profile or games are loading
  Widget _buildLoadingState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: _textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // Profile card showing Steam avatar, username and country
  Widget _buildProfileHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          // Avatar with cyan glow ring
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _accent, width: 2),
              boxShadow: [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 12)],
            ),
            child: ClipOval(
              child: Image.network(
                profile!['avatar'] ?? '',
                width: 72, height: 72, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 72, height: 72, color: _surface2,
                  child: const Icon(Icons.person, color: _textSecondary, size: 36),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile!['username'] ?? 'Unknown', style: const TextStyle(color: _textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accent.withOpacity(0.3)),
                      ),
                      child: const Text('Steam', style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    if (profile!['countryCode'] != null && profile!['countryCode'].toString().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text('📍 ${profile!['countryCode']}', style: const TextStyle(color: _textSecondary, fontSize: 13)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Stats bar showing total games, played games and total hours
  Widget _buildStatsBar() {
    if (gamesData == null) return const SizedBox.shrink();
    final totalGames = gamesData!['totalGames'] ?? 0;
    final totalHours = gamesData!['totalHours'] ?? 0;
    final playedGames = gamesData!['playedGames'] ?? 0;

    return Row(
      children: [
        _buildStatCard(Icons.library_books_outlined, '$totalGames', 'Total Games', _accent),
        const SizedBox(width: 10),
        _buildStatCard(Icons.play_circle_outline, '$playedGames', 'Played', const Color(0xFF4ADE80)),
        const SizedBox(width: 10),
        _buildStatCard(Icons.timer_outlined, '${totalHours}h', 'Hours', const Color(0xFFFBBF24)),
      ],
    );
  }

  // Individual stat card widget
  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(color: _textSecondary, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Game library section with search and expandable achievement rows
  Widget _buildGamesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('GAME LIBRARY', style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        // Game search field
        TextField(
          controller: _searchController,
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
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: _textSecondary, size: 16),
                    onPressed: () { _searchController.clear(); setState(() => searchQuery = ''); })
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (v) => setState(() => searchQuery = v),
        ),
        const SizedBox(height: 12),
        if (isLoadingGames)
          _buildLoadingState('Loading your library...')
        else if (gamesData != null) ...[
          Text('${filteredGames.length} games', style: const TextStyle(color: _textSecondary, fontSize: 12)),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredGames.length,
            itemBuilder: (context, index) {
              final game = filteredGames[index];
              final isSelected = selectedAppId == game['appId'];
              return _buildGameRow(game, isSelected);
            },
          ),
        ],
      ],
    );
  }

  // Individual game row — tap to expand achievements panel
  Widget _buildGameRow(Map<dynamic, dynamic> game, bool isSelected) {
    final headerUrl = game['headerUrl']?.toString() ?? '';
    final hours = game['playtimeHours'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? _surface2 : _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? _accent.withOpacity(0.5) : _border),
        boxShadow: isSelected ? [BoxShadow(color: _accent.withOpacity(0.08), blurRadius: 12)] : [],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _loadAchievements(game['appId'], game['name']),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Game header image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: headerUrl.isNotEmpty
                        ? Image.network(
                            headerUrl,
                            width: 80, height: 37, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _gameIconFallback(game),
                          )
                        : _gameIconFallback(game),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(game['name'], style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text(
                          hours > 0 ? '${hours}h played' : 'Never played',
                          style: TextStyle(color: hours > 0 ? _textSecondary : _textSecondary.withOpacity(0.4), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Hours badge
                  if (hours > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _accent.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                      child: Text('${hours}h', style: const TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(width: 8),
                  // Chevron indicates expandable content
                  Icon(
                    isSelected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: isSelected ? _accent : _textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Achievements expand when game is selected
          if (isSelected) _buildAchievementsPanel(),
        ],
      ),
    );
  }

  // Fallback when Steam header image fails to load
  Widget _gameIconFallback(Map<dynamic, dynamic> game) {
    final iconUrl = game['iconUrl']?.toString() ?? '';
    return iconUrl.isNotEmpty
        ? Image.network(iconUrl, width: 80, height: 37, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(width: 80, height: 37, color: _surface2, child: const Icon(Icons.videogame_asset, color: _textSecondary, size: 20)))
        : Container(width: 80, height: 37, color: _surface2, child: const Icon(Icons.videogame_asset, color: _textSecondary, size: 20));
  }

  // Expanded achievement panel shown under a selected game
  Widget _buildAchievementsPanel() {
    if (isLoadingAchievements) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: _accent, strokeWidth: 2))),
      );
    }

    if (achievementsData == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No achievements available for this game.', style: TextStyle(color: _textSecondary, fontSize: 13)),
      );
    }

    final total = achievementsData!['total'] as int;
    final unlocked = achievementsData!['unlocked'] as int;
    final percentage = achievementsData!['percentage'] as int;
    final achievements = achievementsData!['achievements'] as List;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: _border, margin: const EdgeInsets.only(bottom: 14)),
          // Achievement count and completion percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ACHIEVEMENTS', style: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Row(
                children: [
                  Text('$unlocked / $total', style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: percentage >= 100 ? _gold.withOpacity(0.15) : _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$percentage%', style: TextStyle(color: percentage >= 100 ? _gold : _accent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar — gold when 100% complete
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? unlocked / total : 0,
              minHeight: 6,
              backgroundColor: _border,
              valueColor: AlwaysStoppedAnimation<Color>(percentage >= 100 ? _gold : _accent),
            ),
          ),
          const SizedBox(height: 16),
          // Individual achievement rows
          ...achievements.map((a) => _buildAchievementRow(a)),
        ],
      ),
    );
  }

  // Single achievement row — icon, name, description and unlock date
  Widget _buildAchievementRow(dynamic a) {
    final achieved = a['achieved'] as bool? ?? false;
    final displayName = a['displayName']?.toString() ?? a['apiName']?.toString() ?? 'Unknown';
    final description = a['description']?.toString() ?? '';
    final icon = a['icon']?.toString() ?? '';
    final iconGray = a['iconGray']?.toString() ?? '';
    // Use colour icon if unlocked, greyed out icon if locked
    final iconToShow = achieved ? icon : iconGray;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Achievement icon with gold glow when unlocked
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: achieved ? [BoxShadow(color: _gold.withOpacity(0.3), blurRadius: 8)] : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: iconToShow.isNotEmpty
                  ? Image.network(iconToShow, width: 36, height: 36, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _surface2,
                        child: Icon(achieved ? Icons.emoji_events : Icons.lock_outline, color: achieved ? _gold : _textSecondary, size: 18),
                      ))
                  : Container(
                      color: _surface2,
                      child: Icon(achieved ? Icons.emoji_events : Icons.lock_outline, color: achieved ? _gold : _textSecondary, size: 18),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: achieved ? _textPrimary : _textSecondary,
                    fontSize: 13,
                    fontWeight: achieved ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (description.isNotEmpty)
                  Text(description, style: TextStyle(color: _textSecondary.withOpacity(0.6), fontSize: 11)),
              ],
            ),
          ),
          // Unlock date shown on the right for unlocked achievements
          if (achieved && a['unlockedAt'] != null)
            Text(_formatDate(a['unlockedAt'].toString()), style: TextStyle(color: _textSecondary.withOpacity(0.5), fontSize: 11)),
        ],
      ),
    );
  }

  // Converts ISO date string to readable format
  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
}