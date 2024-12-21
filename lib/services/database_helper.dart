import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/gift.dart';

/// Deletes the local database file
void deleteDatabaseFile() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'hedieaty.db');
  await deleteDatabase(path); // Deletes the database file
  print("Local database file deleted successfully.");
}

class DatabaseHelper {
  final DatabaseReference _firebaseDb = FirebaseDatabase.instance.ref();
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  /// Sync gift data to Firebase
  Future<void> syncGiftToFirebase(Gift gift) async {
    try {
      print("Syncing gift to Firebase: ${gift.toMap()}");
      await _firebaseDb.child('gifts/${gift.id}').set(gift.toMap());
      print("Gift synced to Firebase successfully!");
    } catch (e) {
      print("Error syncing gift to Firebase: $e");
    }
  }

  /// Delete gift from Firebase
  Future<void> deleteGiftFromFirebase(int giftId) async {
    try {
      print("Deleting gift with ID $giftId from Firebase.");
      await _firebaseDb.child('gifts/$giftId').remove();
      print("Gift deleted from Firebase successfully!");
    } catch (e) {
      print("Error deleting gift from Firebase: $e");
    }
  }

  /// Fetch real-time gift updates from Firebase
  Stream<List<Gift>> getGiftsStream() {
    return _firebaseDb.child('gifts').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        print("No gifts found in Firebase.");
        return [];
      }
      print("Fetched gifts from Firebase: $data");
      return data.values.map((e) => Gift.fromFirebase(Map<String, dynamic>.from(e), '')).toList();
    });
  }

  /// Access the local SQLite database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the local SQLite database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hedieaty.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Handle database creation
  Future<void> _onCreate(Database db, int version) async {
    // Create `users` table
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      phoneNumber TEXT NOT NULL UNIQUE,
      firebaseId TEXT NOT NULL UNIQUE
    )
    ''');

    // Create `friends` table
    await db.execute('''
    CREATE TABLE friends (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phoneNumber TEXT NOT NULL,
      profilePicUrl TEXT DEFAULT '',
      userId INTEGER NOT NULL,
      eventCount INTEGER DEFAULT 0,
      FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
    )
    ''');

    // Create `events` table
    await db.execute('''
    CREATE TABLE events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      date TEXT NOT NULL,
      location TEXT,
      category TEXT,
      description TEXT,
      status TEXT CHECK(status IN ('upcoming', 'current', 'past')) NOT NULL,
      userId INTEGER NOT NULL,
      FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
    )
    ''');

    // Create `gifts` table
    await db.execute('''
    CREATE TABLE gifts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      category TEXT,
      price REAL,
      status TEXT CHECK(status IN ('available', 'pledged', 'purchased')) NOT NULL,
      imageUrl TEXT DEFAULT '',
      eventId INTEGER NOT NULL,
      userId INTEGER NOT NULL,
      pledgedTo INTEGER,
      FOREIGN KEY(eventId) REFERENCES events(id) ON DELETE CASCADE,
      FOREIGN KEY(userId) REFERENCES users(id) ON DELETE CASCADE
    )
    ''');

    print("Database created successfully!");

    // Indexes for optimized queries
    await db.execute('CREATE INDEX idx_users_id ON users(id)');
    await db.execute('CREATE INDEX idx_events_userId ON events(userId)');
    await db.execute('CREATE INDEX idx_gifts_eventId ON gifts(eventId)');
    await db.execute('CREATE INDEX idx_gifts_status ON gifts(status)');
  }

  /// Insert a gift into the local database
  Future<void> insertGift(Gift gift) async {
    final db = await database;
    await db.insert(
      'gifts',
      gift.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("Gift inserted into SQLite successfully: ${gift.toMap()}");
  }

  /// Fetch all gifts from the local database
  Future<List<Gift>> getAllGifts() async {
    final db = await database;
    final List<Map<String, dynamic>> giftMaps = await db.query('gifts');
    print("Fetched gifts from SQLite: $giftMaps");
    return giftMaps.map((map) => Gift.fromMap(map)).toList();
  }

  /// Update a gift in the local database
  Future<void> updateGift(Gift gift) async {
    final db = await database;
    await db.update(
      'gifts',
      gift.toMap(),
      where: 'id = ?',
      whereArgs: [gift.id],
    );
    print("Gift updated in SQLite successfully: ${gift.toMap()}");
  }
  Future<List<Map<String, dynamic>>> fetchGiftsPledgedByFriends(int userId) async {
    final db = await database;

    // Query to fetch gifts pledged to the user's friends
    return await db.rawQuery('''
    SELECT g.*, u.name AS friendName
    FROM gifts g
    LEFT JOIN users u ON g.pledgedTo = u.id
    WHERE g.userId = ? AND g.pledgedTo IS NOT NULL
  ''', [userId]);
  }

  /// Delete a gift from the local database
  Future<void> deleteGift(int giftId) async {
    final db = await database;
    await db.delete(
      'gifts',
      where: 'id = ?',
      whereArgs: [giftId],
    );
    print("Gift deleted from SQLite successfully: ID $giftId");
  }
}
