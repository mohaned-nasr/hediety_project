import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_helper.dart';
import 'my_pledged_gifts_page.dart';
import 'event_list_page.dart';
import 'gift_list_page.dart';
import 'gifts_pledged_to_me_page.dart'; // Import the new page
import 'login_page.dart'; // Import LoginPage for logout navigation
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class ProfilePage extends StatefulWidget {
  final User user;

  ProfilePage({required this.user});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
  }

  void _updateUserInfo() async {
    final db = await dbHelper.database;

    await db.update(
      'users',
      {
        'name': _nameController.text,
        'email': _emailController.text,
      },
      where: 'id = ?',
      whereArgs: [widget.user.id],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User information updated!')),
    );
    setState(() {
      widget.user.name = _nameController.text;
      widget.user.email = _emailController.text;
    });
  }

  void _logout() async {
    try {
      await firebase_auth.FirebaseAuth.instance.signOut(); // Sign out from Firebase
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to LoginPage
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit User Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateUserInfo();
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Notification Settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text("Receive Event Reminders"),
                value: true,
                onChanged: (value) {
                  // Placeholder for toggling notifications
                },
              ),
              SwitchListTile(
                title: Text("Receive Gift Updates"),
                value: true,
                onChanged: (value) {
                  // Placeholder for toggling notifications
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
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
        title: Text("User Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Info Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                title: Text(
                  widget.user.name,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                subtitle: Text(
                  widget.user.email,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                trailing: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                onTap: _showEditDialog,
              ),
            ),
            SizedBox(height: 16),

            // Action Buttons
            Expanded(
              child: ListView(
                children: [
                  _buildActionCard(
                    context,
                    icon: Icons.event,
                    title: "Manage My Events",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EventListPage(currentUser: widget.user)),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.volunteer_activism,
                    title: "My Pledged Gifts",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyPledgedGiftsPage(user: widget.user)),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.receipt,
                    title: "Gifts Pledged to Me",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GiftsPledgedToMePage(currentUser: widget.user),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.notifications,
                    title: "Notification Settings",
                    onTap: _showNotificationSettings,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: Icon(Icons.logout),
          label: Text("Logout"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error, // Red for emphasis
            foregroundColor: Theme.of(context).colorScheme.onError, // Contrast text color
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _logout,
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

}
