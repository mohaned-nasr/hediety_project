import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../widgets/event_tile.dart';
import '../services/database_helper.dart';
import 'gift_list_page.dart';

class EventListPage extends StatefulWidget {
  final User currentUser;
  final int? friendId; // Optional friendId for viewing another user's events

  EventListPage({required this.currentUser, this.friendId});

  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Event> events = [];
  String _sortCriteria = 'name'; // Default sorting criteria

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  void loadEvents() async {
    final db = await dbHelper.database;

    // Determine whose events to load (current user or friend)
    int userIdToQuery = widget.friendId ?? widget.currentUser.id;

    print('Loading events for userId: $userIdToQuery'); // Debugging

    // Fetch events for the appropriate user
    final List<Map<String, dynamic>> eventMaps = await db.query(
      'events',
      where: 'userId = ?',
      whereArgs: [userIdToQuery],
      orderBy: _sortCriteria,
    );

    print('Events fetched for userId $userIdToQuery: $eventMaps'); // Debugging

    setState(() {
      events = eventMaps.map((e) => Event.fromMap(e)).toList();
    });
  }


  void _sortEvents(String criteria) {
    setState(() {
      _sortCriteria = criteria; // Update sorting criteria
      loadEvents(); // Reload events with the new sort order
    });
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
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Event Name'),
                ),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(labelText: 'Location'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                TextField(
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
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
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
                    loadEvents(); // Refresh event list
                    Navigator.pop(context); // Close the dialog
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
    final isFriendView = widget.friendId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isFriendView ? 'Friend\'s Events' : 'Your Events',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortCriteria,
                icon: Icon(Icons.sort, color: Colors.white),
                dropdownColor: Theme.of(context).colorScheme.primary,
                items: [
                  DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                  DropdownMenuItem(value: 'category', child: Text('Sort by Category')),
                  DropdownMenuItem(value: 'status', child: Text('Sort by Status')),
                ],
                onChanged: (value) {
                  if (value != null) _sortEvents(value);
                },
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: events.isEmpty
            ? Center(
          child: Text(
            'No events available.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
          ),
        )
            : ListView.separated(
          itemCount: events.length,
          separatorBuilder: (context, index) => Divider(
            thickness: 1,
            color: Theme.of(context).dividerTheme.color,
          ),
          itemBuilder: (context, index) {
            final event = events[index];
            return EventTile(
              event: event,
              currentUser: widget.currentUser,
              onDelete: () => loadEvents(),
              onEdit: () => loadEvents(),
              friendEventOwnerId: widget.friendId,
            );
          },
        ),
      ),
      floatingActionButton: isFriendView
          ? null
          : FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Event',
      ),
    );
  }

}



