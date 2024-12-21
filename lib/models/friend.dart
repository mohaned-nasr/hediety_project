class Friend {
  final int id;
  final String name;
  final String profilePicUrl;
  final String phoneNumber;
  int eventCount; // Remove `final` to make it mutable.

  Friend({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.profilePicUrl,
    this.eventCount = 0, // Default to 0.
  });

  // Convert a Map (from SQLite) to a Friend instance.
  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      id: map['id'],
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      profilePicUrl: map['profilePicUrl'],
      eventCount: map['eventCount'] ?? 0, // Default to 0 if missing.
    );
  }

  // Convert a Friend instance to a Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'profilePicUrl': profilePicUrl,
      'eventCount': eventCount,
    };
  }
}
