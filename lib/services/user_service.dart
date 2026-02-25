import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game.dart';
import '../screens/favorites_screen.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Real-time favorites stream
  Stream<Set<int>> favoriteIdsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => int.parse(doc.id)).toSet());
  }

 
  // Load favorites from Firestore
  Future<Set<int>> loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();

    final ids = snapshot.docs.map((doc) => int.parse(doc.id)).toSet();

    // Save locally
    await saveFavoritesLocally(ids);

    return ids;
  }

  //Toggle favorite status
  
  Future<void> toggleFavorite(int id, List<Game> games, Set<int> favoriteIds) async {
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
      final game = games.firstWhere((g) => g.id == id, orElse: () => Game(
        id: id,
        name: 'Unknown',
        backgroundImage: '',
        rating: 0,
        released: 'Unknown',
      ));

      await docRef.set({
        'gameId': id,
        'name': game.name,
        'imageUrl': game.backgroundImage,
        'rating': game.rating,
        'released': game.released,
        'timestamp': FieldValue.serverTimestamp(),
      });

      favoriteIds.add(id);
    }

    // Update local cache
    await saveFavoritesLocally(favoriteIds);
  }

  // Save recently viewed game
  Future<void> saveRecentlyViewed(Game game) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recentlyViewed')
        .doc(game.id.toString());

    await docRef.set({
      'id': game.id,
      'name': game.name,
      'background_image': game.backgroundImage,
      'rating': game.rating,
      'released': game.released,
      'description_raw': game.description ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Load recently viewed games
 
  Future<List<Game>> loadRecentlyViewed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recentlyViewed')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => Game.fromJson(doc.data())).toList();
  }

  
  // Local caching with SharedPreferences
  
  Future<void> saveFavoritesLocally(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favorites', ids.map((e) => e.toString()).toList());
  }

  Future<Set<int>> loadFavoritesLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorites') ?? [];
    return list.map((e) => int.parse(e)).toSet();
  }


  // Navigate to favorites screen
 
  void goToFavorites(
      BuildContext context,
      List<Game> games,
      Set<int> favorites,
      VoidCallback refreshFavorites) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FavoritesScreen(
          favoriteGames: games.where((game) => favorites.contains(game.id)).toList(),
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
