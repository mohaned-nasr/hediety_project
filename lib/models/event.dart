class Event {
  final int id;
  final String name;
  final DateTime date;
  final String location;
  final String description;
  final int userId; // ID of the event creator

  Event({
    required this.id,
    required this.name,
    required this.date,
    required this.location,
    required this.description,
    required this.userId,
  });

  // Convert a Map (from SQLite) to an Event instance
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      name: map['name'],
      date: DateTime.parse(map['date']),
      location: map['location'],
      description: map['description'],
      userId: map['userId'],
    );
  }

  // Convert an Event instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'location': location,
      'description': description,
      'userId': userId,
    };
  }
}
