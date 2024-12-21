import 'package:flutter/material.dart';
import '../models/gift.dart';
import '../services/database_helper.dart';
import '../models/user.dart';
import 'gift_details_page.dart';

class GiftsPledgedToMePage extends StatefulWidget {
  final User currentUser;

  GiftsPledgedToMePage({required this.currentUser});

  @override
  _GiftsPledgedToMePageState createState() => _GiftsPledgedToMePageState();
}

class _GiftsPledgedToMePageState extends State<GiftsPledgedToMePage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> pledgedGiftsWithFriend = [];

  @override
  void initState() {
    super.initState();
    loadPledgedGifts();
  }

  /// Fetch gifts pledged by friends of the current user
  Future<List<Map<String, dynamic>>> fetchGiftsPledgedByFriends(int userId) async {
    try {
      final db = await dbHelper.database;
      // Log the friends of the current user
      final List<Map<String, dynamic>> friends = await db.rawQuery('''
      SELECT id FROM friends WHERE userId = ?
    ''', [userId]);
      print("Friends of userId $userId: $friends");

      final List<Map<String, dynamic>> pledgedGifts = await db.rawQuery('''
      SELECT * FROM gifts WHERE status = 'pledged'
    ''');
      print("Pledged gifts: $pledgedGifts");



      // Fetch gifts pledged by the current user's friends
      final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT g.*, u.name AS friendName
      FROM gifts g
      INNER JOIN users u ON g.pledgedTo = u.id
      WHERE g.pledgedTo IN (
        SELECT id
        FROM friends
        WHERE userId = ?
      )
      AND g.status = 'pledged'
    ''', [userId]);

      print("Gifts pledged by friends: $result"); // Debug log
      return result;
    } catch (e) {
      print("Error fetching gifts pledged by friends: $e");
      return [];
    }
  }


  /// Load pledged gifts into the state
  void loadPledgedGifts() async {
    try {
      // Fetch gifts pledged by friends
      final List<Map<String, dynamic>> giftMaps = await fetchGiftsPledgedByFriends(widget.currentUser.id);

      setState(() {
        pledgedGiftsWithFriend = giftMaps;
      });

      print("Loaded pledged gifts: $pledgedGiftsWithFriend"); // Debug log
    } catch (e) {
      print("Error loading pledged gifts: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gifts Pledged to Me"),
      ),
      body: pledgedGiftsWithFriend.isEmpty
          ? Center(
        child: Text(
          "No gifts have been pledged by your friends.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: pledgedGiftsWithFriend.length,
        itemBuilder: (context, index) {
          final giftMap = pledgedGiftsWithFriend[index];
          final Gift gift = Gift.fromMap(giftMap);
          final String friendName = giftMap['friendName'] ?? "Unknown";

          return ListTile(
            leading: Icon(Icons.card_giftcard, color: Colors.green),
            title: Text(gift.name),
            subtitle: Text(
              'Category: ${gift.category}, Price: \$${gift.price.toStringAsFixed(2)}\n'
                  'Pledged by: $friendName',
            ),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              // Navigate to gift details
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GiftDetailsPage(
                    gift: gift,
                    currentUser: widget.currentUser,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
