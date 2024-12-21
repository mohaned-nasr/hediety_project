import 'dart:async';
import 'package:flutter/material.dart';
import '../models/gift.dart';
import '../models/user.dart';
import '../services/database_helper.dart';
//import '../services/notifi_service.dart';
import '../widgets/gift_tile.dart';

class GiftListPage extends StatefulWidget {
  final int eventId;
  final User currentUser;
  final int? friendEventOwnerId;
  //StreamSubscription? _giftSubscription;

  GiftListPage({
    required this.eventId,
    required this.currentUser,
    this.friendEventOwnerId,
  });

  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  StreamSubscription? _giftSubscription;
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Gift> gifts = [];
  String _sortCriteria = 'name';

  @override
  void initState() {
    super.initState();
    _listenToGifts();
  }

  /// Listen to real-time gift updates
  void _listenToGifts() {
    _giftSubscription = dbHelper.getGiftsStream().listen((fetchedGifts) {
      print("Fetched gifts: ${fetchedGifts.map((g) => g.toMap())}");
      if (mounted) {
        setState(() {
          gifts = fetchedGifts.where((gift) => gift.eventId == widget.eventId).toList();
        });

        // Notify gift list creator about status changes
        /*for (var gift in fetchedGifts) {
          if (gift.eventId == widget.eventId && gift.status == 'pledged') {
            if (gift.userId == widget.currentUser.id) {
              // In-app notification for gift creator
              NotificationService().showNotification(
                title: 'Gift Pledged!',
                body: '${gift.name} has been pledged!',
              );
            }
          }
        }*/
      } else {
        print("Widget is not mounted, skipping updates.");
      }
    });
  }


  @override
  void dispose() {
    _giftSubscription?.cancel();
    super.dispose();
  }

  /// Sort gifts
  void _sortGifts(String criteria) {
    setState(() {
      _sortCriteria = criteria;
      gifts.sort((a, b) {
        switch (criteria) {
          case 'category':
            return a.category.compareTo(b.category);
          case 'status':
            return a.status.compareTo(b.status);
          default:
            return a.name.compareTo(b.name);
        }
      });
    });
  }

  /// Add/Edit gift dialog
  void _showAddEditGiftDialog(BuildContext context, Gift? gift) {
    TextEditingController nameController = TextEditingController(text: gift?.name ?? '');
    TextEditingController categoryController = TextEditingController(text: gift?.category ?? '');
    TextEditingController priceController = TextEditingController(
      text: gift?.price != null ? gift!.price.toString() : '',
    );
    String status = gift?.status ?? 'available';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(gift == null ? "Add Gift" : "Edit Gift"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(labelText: 'Category'),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: InputDecoration(labelText: 'Status'),
                  items: ['available', 'pledged', 'purchased']
                      .map((value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.capitalize()),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        status = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text("Save"),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final newGift = Gift(
                    id: gift?.id ?? DateTime.now().millisecondsSinceEpoch,
                    name: nameController.text,
                    category: categoryController.text,
                    price: double.parse(priceController.text),
                    status: status,
                    eventId: widget.eventId,
                    userId: widget.currentUser.id,
                  );

                  print("Saving gift: ${newGift.toMap()}");
                  await dbHelper.syncGiftToFirebase(newGift); // Sync to Firebase
                  Navigator.of(context).pop();
                  setState(() {
                    gifts.add(newGift);
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Show delete confirmation
  void _showDeleteConfirmation(BuildContext context, Gift gift) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Gift'),
          content: Text('Are you sure you want to delete this gift?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                try {
                  await dbHelper.deleteGiftFromFirebase(gift.id);
                  setState(() {
                    gifts.removeWhere((g) => g.id == gift.id);
                  });
                  Navigator.pop(context);
                } catch (e) {
                  print('Error deleting gift: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete gift.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFriendView = widget.friendEventOwnerId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFriendView ? 'Friend\'s Gifts' : 'Your Gifts'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _sortGifts,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              PopupMenuItem(value: 'category', child: Text('Sort by Category')),
              PopupMenuItem(value: 'status', child: Text('Sort by Status')),
            ],
          ),
        ],
      ),
      body: gifts.isEmpty
          ? Center(
        child: Text(
          'No gifts available.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      )
          : ListView.builder(
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          return GiftTile(
            gift: gift,
            currentUser: widget.currentUser,
            onEdit: isFriendView || gift.status == 'pledged'
                ? null
                : () => _showAddEditGiftDialog(context, gift),
            onDelete: isFriendView ? null : () => _showDeleteConfirmation(context, gift),
          );
        },
      ),
      floatingActionButton: isFriendView
          ? null
          : FloatingActionButton(
        onPressed: () => _showAddEditGiftDialog(context, null),
        child: Icon(Icons.add),
        tooltip: 'Add Gift',
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return this.isNotEmpty ? '${this[0].toUpperCase()}${this.substring(1)}' : '';
  }
}
