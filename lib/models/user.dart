import 'event.dart';
import 'gift.dart';

class User {
  final int id;
  String name;
  String email;
  String phoneNumber; // Add phone number field
  List<Event> events; // User's created events
  List<Gift> pledgedGifts; // Gifts that user has pledged

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber, // Add phone number
    required this.events,
    required this.pledgedGifts,
  });

  // Convert a Map (from SQLite) to a User instance
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phoneNumber: map['phoneNumber'], // Map phoneNumber
      events: [], // Events will need to be fetched separately
      pledgedGifts: [], // Pledged gifts will need to be fetched separately
    );
  }

  // Convert a User instance to a Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber, // Include phoneNumber
    };
  }
}
