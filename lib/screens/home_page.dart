import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Alias FirebaseAuth's User
import '../widgets/friend_tile.dart';
import '../models/friend.dart';
import '../models/user.dart'; // Import your custom User model
import '../services/database_helper.dart';
import 'event_list_page.dart';
import 'profile_page.dart'; // Import ProfilePage
import 'gift_list_page.dart';

class HomePage extends StatefulWidget {
  final User currentUser; // Add `currentUser` as a required parameter

  HomePage({required this.currentUser}); // Updated constructor to include this

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Friend> friendsList = [];
  List<Friend> displayedFriends = [];

  @override
  void initState() {
    super.initState();
    loadFriends();
  }

  void loadFriends() async {
    final db = await dbHelper.database;

    print("Loading friends for userId: ${widget.currentUser.id}"); // Debugging


    final List<Map<String, dynamic>> friends = await db.query(
      'friends',
      where: 'userId = ?', // Filter by userId
      whereArgs: [widget.currentUser.id],
    );
    print("Friends fetched: $friends"); // Debugging
    // Fetch event counts for friends associated with the logged-in user
    List<Map<String, dynamic>> eventCounts = await db.rawQuery('''
    SELECT friends.id AS friendId, COUNT(events.id) AS eventCount
    FROM friends
    LEFT JOIN events ON events.userId = friends.id
    WHERE friends.userId = ? AND events.status = 'upcoming'
    GROUP BY friends.id
  ''', [widget.currentUser.id]);

    print("Event Counts: $eventCounts"); // Debugging

    Map<int, int> friendEventCountMap = {
      for (var e in eventCounts) e['friendId'] as int: e['eventCount'] as int
    };

    setState(() {
      friendsList = friends.map((f) {
        final friend = Friend.fromMap(f);
        friend.eventCount = friendEventCountMap[friend.id] ?? 0;
        return friend;
      }).toList();
      displayedFriends = friendsList;
    });
  }

  void filterSearchResults(String query) {
    if (query.isEmpty) {
      setState(() {
        displayedFriends = friendsList;
      });
      return;
    }
    List<Friend> filtered = friendsList.where((f) {
      return f.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
    setState(() {
      displayedFriends = filtered;
    });
  }


  void _showAddFriendDialog() async {
    TextEditingController nameController = TextEditingController();
    TextEditingController phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add a Friend"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: Key('friendNameField'),
                controller: nameController,
                decoration: InputDecoration(labelText: "Name"),
              ),
              TextField(
                key: Key('friendPhoneField'),
                controller: phoneController,
                decoration: InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
              ),
              ElevatedButton(
                key: Key('addFriendButton'),
                onPressed: _addFriendFromContacts,
                child: Text('Add from Contacts'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final phoneNumber = phoneController.text.trim();

                if (name.isNotEmpty &&
                    phoneNumber.isNotEmpty) {
                  final db = await dbHelper.database;

                  print("Adding friend with phoneNumber: $phoneNumber for userId: ${widget.currentUser.id}");

                  // Debugging: Print all users before inserting friends
                  final allUsers = await db.query('users');
                  print('All Users Table: $allUsers'); // Prints current users table state
                          // Check if the phone number already exists in 'users'
                  List<Map<String, dynamic>> existingUsers = await db.query(
                    'users',
                    where: 'phoneNumber = ?',
                    whereArgs: [phoneNumber],
                  );
                  print('Existing User: $existingUsers');
                  int friendUserId = existingUsers.isNotEmpty
                      ? existingUsers.first['id']
                      : widget.currentUser.id;


                  print('Friend Added: $name, Phone: $phoneNumber');


                  await db.insert('friends', {
                    'name': name,
                    'profilePicUrl': '',
                    'userId': widget.currentUser.id,
                    'eventCount': 0,
                    'phoneNumber': phoneNumber,
                  });


                  if (existingUsers.isNotEmpty) {
                    await db.insert('friends', {
                      'name': widget.currentUser.name,
                      'phoneNumber': widget.currentUser.phoneNumber,
                      'profilePicUrl': '',
                      'userId': friendUserId,
                      'eventCount': 0,
                    });
                  }

                  loadFriends();
                  Navigator.pop(context);
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _addFriendFromContacts() async {
    if (await Permission.contacts.isGranted) {
      _fetchContacts();
    } else {
      final status = await Permission.contacts.request();
      if (status.isGranted) {
        _fetchContacts();
      } else if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enable contacts permission in app settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                openAppSettings();
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission to access contacts was denied.')),
        );
      }
    }
  }

  void _fetchContacts() async {
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: false,
      );

      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return ListView(
            children: contacts.map((contact) {
              return ListTile(
                title: Text(contact.displayName ?? 'Unknown'),
                onTap: () async {
                  final db = await dbHelper.database;
                  await db.insert('friends', {
                    'name': contact.displayName ?? 'Unknown',
                    'profilePicUrl': '',
                    'userId': widget.currentUser.id,
                    'eventCount': 0,
                  });
                  loadFriends();
                  Navigator.pop(context);
                },
              );
            }).toList(),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load contacts: $e')),
      );
    }
  }

  void _showAddEventDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController locationController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController categoryController = TextEditingController();
    String status = 'upcoming'; // Default status
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: Key('eventNameField'),
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Event Name'),
                ),
                TextField(
                  key: Key('eventLocationField'),
                  controller: locationController,
                  decoration: InputDecoration(labelText: 'Location'),
                ),
                TextField(
                  key: Key('eventDescriptionField'),
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  key: Key('eventCategoryField'),
                  controller: categoryController,
                  decoration: InputDecoration(labelText: 'Category'),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                  child: Text(
                      'Select Date: ${selectedDate.toLocal().toString().split(' ')[0]}'),
                ),
                DropdownButton<String>(
                  value: status,
                  items: ['upcoming', 'current', 'past']
                      .map((value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.capitalize()),
                  ))
                      .toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        status = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              key: Key('addEventButton'),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              key: Key('addFriendButton'),
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    locationController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  try {
                    final db = await dbHelper.database;
                    await db.insert('events', {
                      'name': nameController.text,
                      'location': locationController.text,
                      'description': descriptionController.text,
                      'category': categoryController.text,
                      'date': selectedDate.toIso8601String(),
                      'status': status,
                      'userId': widget.currentUser.id,
                    });

                    Navigator.pop(context); // Close the dialog
                    // Optionally refresh events or perform further actions
                  } catch (e) {
                    print('Error inserting event: $e'); // Debugging log
                  }
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(user: widget.currentUser),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: filterSearchResults,
              decoration: InputDecoration(
                labelText: "Search",
                hintText: "Search for friends",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    key: Key('createEventButton'),
                    icon: Icon(Icons.add),
                    label: Text('Create Event'),
                    onPressed: _showAddEventDialog,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.list_alt),
                    label: Text('Event List'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventListPage(
                            currentUser: widget.currentUser,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: displayedFriends.isEmpty
                ? Center(
              child: Text(
                'No friends found.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: displayedFriends.length,
              itemBuilder: (context, index) {
                var friend = displayedFriends[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FriendTile(
                    friend: friend,
                    currentUser: widget.currentUser,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: Key('addFriendButton'),
        onPressed: _showAddFriendDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Friend',
      ),
    );
  }

}
