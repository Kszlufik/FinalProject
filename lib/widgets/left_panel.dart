import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/profile_screen.dart';

class LeftPanel extends StatefulWidget {
  final Function(String platform) onPlatformChange;
  final Function(String sortBy, String dates) onPresetChange;
  final String selectedPlatform;
  final String selectedPreset;
  final VoidCallback? onProfileTap;

  const LeftPanel({
    super.key,
    required this.onPlatformChange,
    required this.onPresetChange,
    required this.selectedPlatform,
    required this.selectedPreset,
    this.onProfileTap,
  });

  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel> {
  static const _bg = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _accent = Color(0xFF00E5FF);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _border = Color(0xFF30363D);

  int favoritesCount = 0;
  String userEmail = '';
  String username = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    userEmail = user.email ?? '';
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final favSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();
    if (mounted) {
      setState(() {
        favoritesCount = favSnapshot.docs.length;
        username = userDoc.data()?['username'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return Container(
      width: 220,
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
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
                    boxShadow: [BoxShadow(color: _accent.withOpacity(0.2), blurRadius: 12)],
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
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('DISCOVER'),
                  ...presets.map((preset) => _buildPresetTile(
                    label: preset['label']!,
                    icon: preset['icon']!,
                    isSelected: widget.selectedPreset == preset['label'],
                    onTap: () => widget.onPresetChange(preset['sortBy']!, preset['dates']!),
                  )),
                  _divider(),
                  _sectionLabel('PLATFORMS'),
                  ...platforms.map((p) => _buildPlatformTile(
                    label: p['label']!,
                    icon: p['icon']!,
                    isSelected: widget.selectedPlatform == p['id'],
                    onTap: () => widget.onPlatformChange(p['id']!),
                  )),
                ],
              ),
            ),
          ),

          _buildUserFooter(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _textSecondary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      color: _border,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildPresetTile({
    required String label,
    required String icon,
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
          border: Border.all(
            color: isSelected ? _accent.withOpacity(0.4) : Colors.transparent,
          ),
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
            if (isSelected) ...[
              const Spacer(),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _accent.withOpacity(0.8), blurRadius: 4)],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformTile({
    required String label,
    required String icon,
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
          border: Border.all(
            color: isSelected ? _accent.withOpacity(0.4) : Colors.transparent,
          ),
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
            if (isSelected) ...[
              const Spacer(),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: _accent,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _accent.withOpacity(0.8), blurRadius: 4)],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserFooter() {
    final displayName = username.isNotEmpty ? username : userEmail;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: widget.onProfileTap,
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
                  initial,
                  style: const TextStyle(
                    color: Color(0xFF0D1117),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.redAccent, size: 11),
                      const SizedBox(width: 3),
                      Text(
                        '$favoritesCount saved',
                        style: const TextStyle(fontSize: 11, color: _textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}