import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/gift.dart';
import '../services/database_helper.dart';
import 'gift_details_page.dart';

class MyPledgedGiftsPage extends StatefulWidget {
  final User user;

  MyPledgedGiftsPage({required this.user});

  @override
  _MyPledgedGiftsPageState createState() => _MyPledgedGiftsPageState();
}

class _MyPledgedGiftsPageState extends State<MyPledgedGiftsPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Gift> pledgedGifts = [];
  late Stream<List<Gift>> pledgedGiftsStream;
  StreamSubscription<List<Gift>>? _subscription;

  @override
  void initState() {
    super.initState();
    _listenToPledgedGifts();
  }

  /// Listen to pledged gifts updates from Firebase
  void _listenToPledgedGifts() {
    pledgedGiftsStream = dbHelper.getGiftsStream().map((gifts) {
      return gifts.where((gift) {
        print("Checking gift: ${gift.toMap()}");
        return gift.status == 'pledged' &&
            gift.pledgedTo == widget.user.id;
      }).toList();
    });


    _subscription = pledgedGiftsStream.listen((gifts) {
      print("Filtered pledged gifts: ${gifts.map((g) => g.toMap())}");
      setState(() {
        pledgedGifts = gifts;
      });
    });
  }


  @override
  void dispose() {
    // Clean up the subscription to avoid memory leaks
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Pledged Gifts"),
      ),
      body: pledgedGifts.isEmpty
          ? Center(
        child: Text(
          "You have no pledged gifts.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: pledgedGifts.length,
        itemBuilder: (context, index) {
          final gift = pledgedGifts[index];
          return ListTile(
            leading: Icon(Icons.card_giftcard, color: Colors.green),
            title: Text(gift.name),
            subtitle: Text('Category: ${gift.category}, Price: ${gift.price}'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    GiftDetailsPage(gift: gift, currentUser: widget.user),
              ),
            ),
          );
        },
      ),
    );
  }
}
