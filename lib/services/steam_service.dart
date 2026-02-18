import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SteamService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save Steam ID to Firestore
  
  Future<void> saveSteamId(String steamId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({'steamId': steamId}, SetOptions(merge: true));
  }


  // Load Steam ID from Firestore
 
  Future<String?> loadSteamId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data()?['steamId'] as String?;
  }

  // Get Steam Profile
 
  Future<Map<String, dynamic>> getSteamProfile(String steamId) async {
    final result = await _functions
        .httpsCallable('getSteamProfile')
        .call({'steamId': steamId});
    return Map<String, dynamic>.from(result.data);
  }

  // Get Owned Games
  
  Future<Map<String, dynamic>> getSteamGames(String steamId) async {
    final result = await _functions
        .httpsCallable('getSteamGames')
        .call({'steamId': steamId});
    return Map<String, dynamic>.from(result.data);
  }

  
  // Get Achievements for a game
  
  Future<Map<String, dynamic>> getSteamAchievements(
      String steamId, int appId) async {
    final result = await _functions
        .httpsCallable('getSteamAchievements')
        .call({'steamId': steamId, 'appId': appId});
    return Map<String, dynamic>.from(result.data);
  }
}