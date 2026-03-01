import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeftPanel extends StatefulWidget {
  final Function(String platform) onPlatformChange;
  final Function(String sortBy, String dates) onPresetChange;
  final String selectedPlatform;
  final String selectedPreset;

  const LeftPanel({
    super.key,
    required this.onPlatformChange,
    required this.onPresetChange,
    required this.selectedPlatform,
    required this.selectedPreset,
  });

  @override
  State<LeftPanel> createState() => _LeftPanelState();
}

class _LeftPanelState extends State<LeftPanel> {
  int favoritesCount = 0;
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    userEmail = user.email ?? '';

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();

    if (mounted) {
      setState(() => favoritesCount = snapshot.docs.length);
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
      {'label': 'Top Rated', 'sortBy': '-rating', 'dates': ''},
      {'label': 'Most Popular', 'sortBy': '-added', 'dates': ''},
      {'label': 'New Releases', 'sortBy': '-released', 'dates': last30Days},
      {'label': 'Coming Soon', 'sortBy': '-added', 'dates': next90Days},
      {'label': 'Best of ${now.year}', 'sortBy': '-rating', 'dates': thisYear},
    ];

    final platforms = [
      {'label': 'All Platforms', 'id': ''},
      {'label': '🖥️  PC', 'id': '4'},
      {'label': '🎮  PlayStation', 'id': '187,18'},
      {'label': '🟩  Xbox', 'id': '186,1'},
      {'label': '🔴  Nintendo', 'id': '7'},
      {'label': '📱  Mobile', 'id': '21,3'},
    ];

    return Container(
      width: 220,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Presets section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'DISCOVER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...presets.map((preset) {
            final isSelected = widget.selectedPreset == preset['label'];
            return ListTile(
              dense: true,
              selected: isSelected,
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Text(
                preset['label']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () => widget.onPresetChange(
                preset['sortBy']!,
                preset['dates']!,
              ),
            );
          }),

          const Divider(height: 24),

          // Platforms section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'PLATFORMS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...platforms.map((platform) {
            final isSelected = widget.selectedPlatform == platform['id'];
            return ListTile(
              dense: true,
              selected: isSelected,
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Text(
                platform['label']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () => widget.onPlatformChange(platform['id']!),
            );
          }),

          const Spacer(),
          const Divider(),

          // User info section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    userEmail.isNotEmpty ? userEmail[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userEmail,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '❤️ $favoritesCount saved',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
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