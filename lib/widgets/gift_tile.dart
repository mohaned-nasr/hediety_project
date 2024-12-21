import 'package:flutter/material.dart';
import '../models/gift.dart';
import '../models/user.dart'; // Import User model
import '../screens/gift_details_page.dart';

class GiftTile extends StatelessWidget {
  final Gift gift;
  final User currentUser; // Add currentUser parameter
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPledge;

  GiftTile({
    required this.gift,
    required this.currentUser, // Accept currentUser as a parameter
    this.onEdit,
    this.onDelete,
    this.onPledge,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.card_giftcard, color: _getStatusColor(gift.status)),
      title: Text(gift.name),
      subtitle: Text(
        'Category: ${gift.category}, Price: \$${gift.price.toStringAsFixed(2)}',
        style: TextStyle(color: _getStatusColor(gift.status)), // Consistent with leading icon
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEdit != null)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          if (onPledge != null)
            IconButton(
              icon: Icon(Icons.check_circle, color: Colors.green),
              onPressed: onPledge,
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GiftDetailsPage(gift: gift, currentUser: currentUser),
          ),
        );
      },
    );
  }

  /// Return the color based on the gift's status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pledged':
        return Colors.green; // Green for pledged
      case 'purchased':
        return Colors.red; // Red for purchased
      case 'available':
        return Colors.blue; // Blue for available
      default:
        return Colors.grey; // Grey for unknown
    }
  }
}
