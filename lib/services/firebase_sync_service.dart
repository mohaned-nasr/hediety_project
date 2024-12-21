import 'package:firebase_database/firebase_database.dart';
import '../models/gift.dart';

class FirebaseSyncService {
  final DatabaseReference _firebaseDb = FirebaseDatabase.instance.ref();

  Future<void> syncLocalGifts(List<Gift> localGifts) async {
    for (Gift gift in localGifts) {
      await _firebaseDb.child('gifts/${gift.id}').set(gift.toMap());
    }
  }

  Future<void> syncGiftToFirebase(Gift gift) async {
    try {
      print("Syncing gift to Firebase: ${gift.toMap()}");
      await _firebaseDb.child('gifts/${gift.id}').set(gift.toMap());
      print("Gift synced to Firebase successfully!");
    } catch (e) {
      print("Error syncing gift to Firebase: $e");
    }
  }

  Stream<List<Gift>> fetchGiftsStream() {
    return _firebaseDb.child('gifts').onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.entries.map((e) => Gift.fromFirebase(Map<String, dynamic>.from(e.value), e.key)).toList();
    });
  }

  /// Fetch all gifts from Firebase and return as a list.
  Future<List<Gift>> fetchAllGifts() async {
    try {
      final snapshot = await _firebaseDb.child('gifts').get();
      if (!snapshot.exists) {
        print("No gifts found in Firebase.");
        return [];
      }
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      final gifts = data.entries.map((e) {
        print("Fetched gift from Firebase: ${e.value}");
        return Gift.fromFirebase(Map<String, dynamic>.from(e.value), e.key);
      }).toList();
      print("All gifts fetched successfully: $gifts");
      return gifts;
    } catch (e) {
      print("Error fetching gifts from Firebase: $e");
      return [];
    }
  }
}
