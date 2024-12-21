import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../screens/event_list_page.dart'; // Navigate to EventListPage instead of GiftListPage
import '../models/user.dart';

class FriendTile extends StatelessWidget {
  final Friend friend;
  final User currentUser;

  FriendTile({required this.friend, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: friend.profilePicUrl.isNotEmpty
            ? NetworkImage(friend.profilePicUrl)
            : AssetImage('assets/default_avatar.webp') as ImageProvider,
      ),
      title: Text(friend.name),
      subtitle: Row(
        children: [
          Icon(Icons.event, size: 16, color: Colors.blue),
          SizedBox(width: 4),
          Text(
            friend.eventCount > 0
                ? "Upcoming Events: ${friend.eventCount}"
                : "No Upcoming Events",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
      trailing: Icon(Icons.arrow_forward),
      onTap: () {
        print("Navigating to events for friendId: ${friend.id} (currentUser: ${currentUser.id})");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventListPage(
              currentUser: currentUser, // Pass the current user
              friendId: friend.id, // Pass the friend's ID to view their events
            ),
          ),
        );
      },
    );
  }
}
