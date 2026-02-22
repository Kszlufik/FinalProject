import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Widgets
import '../widgets/filters_bar.dart';
import '../widgets/search_bar.dart';
// Screens
import '../screens/game_details_screen.dart';
import '../screens/favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> games = [];
  List<Map<String, dynamic>> recentlyViewed = [];

  bool isLoading = true;
  bool isNextPageLoading = false;

  Set<int> favoriteGameIds = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String apiKey = '7ebe36a5b43249e995faab2bf81262bf';
  int currentPage = 1;

  // Filters & search
  String sortBy = '-rating';
  String genre = '';
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchGames();
    loadFavorites();
    loadRecentlyViewed();
  }


  // FETCH GAMES LIST

  Future<void> fetchGames({bool nextPage = false}) async {
    if (nextPage) {
      setState(() => isNextPageLoading = true);
      currentPage += 1;
    } else {
      setState(() => isLoading = true);
      currentPage = 1;
      games.clear();
    }

    final queryParameters = {
      'key': apiKey,
      'page_size': '40',
      'page': currentPage.toString(),
      'ordering': sortBy,
      if (genre.isNotEmpty) 'genres': genre,
      if (searchQuery.isNotEmpty) 'search': searchQuery,
    };

    final uri = Uri.https('api.rawg.io', '/api/games', queryParameters);

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          games.addAll(data['results']);
          isLoading = false;
          isNextPageLoading = false;
        });
      } else {
        throw Exception('Failed to load games');
      }
    } catch (e) {
      print("Error fetching games: $e");
      setState(() {
        isLoading = false;
        isNextPageLoading = false;
      });
    }
  }


  // FETCH FULL GAME DETAILS
  Future<Map<String, dynamic>> fetchGameDetails(int id) async {
    final url = 'https://api.rawg.io/api/games/$id?key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch game details');
    }
  }

  // SAVE RECENTLY VIEWED
  Future<void> saveRecentlyViewed(Map<String, dynamic> game) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recentlyViewed')
        .doc(game['id'].toString());

    await docRef.set({
      'gameId': game['id'],
      'name': game['name'],
      'imageUrl': game['background_image'],
      'rating': game['rating'],
      'released': game['released'],
      'viewedAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recentlyViewed')
        .orderBy('viewedAt', descending: true)
        .get();

    if (snapshot.docs.length > 10) {
      for (int i = 10; i < snapshot.docs.length; i++) {
        await snapshot.docs[i].reference.delete();
      }
    }

    loadRecentlyViewed();
  }

  Future<void> loadRecentlyViewed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recentlyViewed')
        .orderBy('viewedAt', descending: true)
        .limit(10)
        .get();

    setState(() {
      recentlyViewed = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

 
  // LOAD FAVORITES
  
  Future<void> loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();

    final ids = snapshot.docs.map((doc) => int.parse(doc.id)).toSet();
    setState(() => favoriteGameIds = ids);
  }

 
  // TOGGLE FAVORITE (Optimistic UI)
 
  Future<void> toggleFavorite(int id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isFav = favoriteGameIds.contains(id);

    setState(() {
      if (isFav) {
        favoriteGameIds.remove(id);
      } else {
        favoriteGameIds.add(id);
      }
    });

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(id.toString());

    try {
      if (isFav) {
        await docRef.delete();
      } else {
        final game = games.firstWhere((g) => g['id'] == id);
        await docRef.set({
          'gameId': id,
          'name': game['name'],
          'imageUrl': game['background_image'],
          'rating': game['rating'],
          'released': game['released'],
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error updating favorite: $e");
      setState(() {
        if (isFav) {
          favoriteGameIds.add(id);
        } else {
          favoriteGameIds.remove(id);
        }
      });
    }
  }

  
  // NAVIGATE TO FAVORITES
 
  void goToFavorites() {
    final favoriteGames =
        games.where((game) => favoriteGameIds.contains(game['id'])).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FavoritesScreen(
          favoriteGames: favoriteGames,
          favorites: favoriteGameIds,
          onToggleFavorite: (int id) {
            toggleFavorite(id);
            setState(() {});
          },
        ),
      ),
    );
  }

 
  // BUILD
  
  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    Widget buildRecentlyViewed() {
      if (recentlyViewed.isEmpty) return const SizedBox();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Recently Viewed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentlyViewed.length,
              itemBuilder: (context, index) {
                final game = recentlyViewed[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 150,
                    child: InkWell(
                      onTap: () async {
                        final details =
                            await fetchGameDetails(game['gameId']);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GameDetailsScreen(
                              name: details['name'] ?? '',
                              imageUrl: details['background_image'] ?? '',
                              rating: (details['rating'] ?? 0).toDouble(),
                              released: details['released'] ?? 'Unknown',
                              description: details['description_raw'] ??
                                  'No description available.',
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.network(
                              game['imageUrl'] ?? '',
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            game['name'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

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
          if (isWideScreen)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Left Panel (space for categories/links)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                  child: GameSearchBar(
                    controller: searchController,
                    onSubmitted: (value) {
                      searchQuery = value;
                      fetchGames();
                    },
                  ),
                ),
                FiltersBar(
                  sortBy: sortBy,
                  genre: genre,
                  onSortChange: (value) {
                    if (value == null) return;
                    sortBy = value;
                    fetchGames();
                  },
                  onGenreChange: (value) {
                    if (value == null) return;
                    genre = value;
                    fetchGames();
                  },
                  onClearFilters: () {
                    sortBy = '-rating';
                    genre = '';
                    searchController.clear();
                    searchQuery = '';
                    fetchGames();
                  },
                ),
                buildRecentlyViewed(),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: games.length + 1,
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.6,
                          ),
                          itemBuilder: (context, index) {
                            if (index == games.length) {
                              return isNextPageLoading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            fetchGames(nextPage: true),
                                        child: const Text("Next Page"),
                                      ),
                                    );
                            }

                            final game = games[index];
                            final id = game['id'];

                            return InkWell(
                              onTap: () async {
                                // Fetch full description
                                final details = await fetchGameDetails(id);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GameDetailsScreen(
                                      name: details['name'] ?? '',
                                      imageUrl:
                                          details['background_image'] ?? '',
                                      rating:
                                          (details['rating'] ?? 0).toDouble(),
                                      released:
                                          details['released'] ?? 'Unknown',
                                      description: details['description_raw'] ??
                                          'No description available.',
                                    ),
                                  ),
                                );

                                saveRecentlyViewed(game);
                              },
                              child: Card(
                                elevation: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Image.network(
                                        game['background_image'] ?? '',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            game['name'] ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            "⭐ ${game['rating']}",
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        icon: Icon(
                                          favoriteGameIds.contains(id)
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: favoriteGameIds.contains(id)
                                              ? Colors.red
                                              : null,
                                        ),
                                        onPressed: () => toggleFavorite(id),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
