import 'package:flutter/material.dart';
import '../models/event.dart';
import '../screens/gift_list_page.dart';
import '../services/database_helper.dart';
import '../models/user.dart';

class EventTile extends StatelessWidget {
  final Event event;
  final User currentUser;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final int? friendEventOwnerId; // Optional friend's ID for friend's events

  EventTile({
    required this.event,
    required this.currentUser,
    required this.onDelete,
    required this.onEdit,
    this.friendEventOwnerId,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFriendEvent = friendEventOwnerId != null; // Determine if this is a friend's event

    return ListTile(
      leading: Icon(Icons.event, color: isFriendEvent ? Colors.blue : Colors.green),
      title: Text(event.name),
      subtitle: Text('${event.date.toLocal()} at ${event.location}'),
      trailing: isFriendEvent
          ? null // Hide edit and delete options for friend's events
          : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showEditEventDialog(context),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GiftListPage(
              eventId: event.id,
              currentUser: currentUser,
              friendEventOwnerId: friendEventOwnerId, // Pass friend's userId if applicable
            ),
          ),
        );
      },
    );
  }

  void _showEditEventDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController(text: event.name);
    TextEditingController locationController = TextEditingController(text: event.location);
    TextEditingController descriptionController = TextEditingController(text: event.description);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(labelText: 'Location'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final db = await DatabaseHelper().database;
                await db.update(
                  'events',
                  {
                    'name': nameController.text,
                    'location': locationController.text,
                    'description': descriptionController.text,
                  },
                  where: 'id = ?',
                  whereArgs: [event.id],
                );
                onEdit(); // Refresh the list
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this event?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final db = await DatabaseHelper().database;
                await db.delete(
                  'events',
                  where: 'id = ?',
                  whereArgs: [event.id],
                );
                onDelete(); // Refresh the list
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
