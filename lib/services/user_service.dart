import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/favorites_screen.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Load favorite game IDs for current user
  Future<Set<int>> loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();

    return snapshot.docs.map((doc) => int.parse(doc.id)).toSet();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(
      int id, List<dynamic> games, Set<int> favoriteIds) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(id.toString());

    if (favoriteIds.contains(id)) {
      await docRef.delete();
      favoriteIds.remove(id);
    } else {
      // ✅ Guard against game not found to avoid StateError crash
      final results = games.where((g) => g['id'] == id).toList();
      if (results.isEmpty) return;
      final game = results.first;

      await docRef.set({
        'gameId': id,
        'name': game['name'],
        'imageUrl': game['background_image'],
        'rating': game['rating'],
        'released': game['released'],
        'timestamp': FieldValue.serverTimestamp(),
      });
      favoriteIds.add(id);
    }
  }

  /// Save recently viewed game (expects full game data from fetchGameDetails)
  Future<void> saveRecentlyViewed(Map<String, dynamic> game) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final gameId = game['id'];
    if (gameId == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recentlyViewed')
        .doc(gameId.toString());

    // ✅ Save only known serializable fields — including description_raw
    //    now that we fetch full game details before saving
    await docRef.set({
      'id': gameId,
      'name': game['name'],
      'background_image': game['background_image'],
      'rating': game['rating'],
      'released': game['released'],
      'description_raw': game['description_raw'] ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Load recently viewed games
  Future<List<Map<String, dynamic>>> loadRecentlyViewed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recentlyViewed')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Navigate to favorites screen
  void goToFavorites(
      BuildContext context,
      List<dynamic> games,
      Set<int> favorites,
      VoidCallback refreshFavorites) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FavoritesScreen(
          favoriteGames:
              games.where((game) => favorites.contains(game['id'])).toList(),
          favorites: favorites,
          onToggleFavorite: (id) async {
            await toggleFavorite(id, games, favorites);
            refreshFavorites();
          },
        ),
      ),
    );
  }
}