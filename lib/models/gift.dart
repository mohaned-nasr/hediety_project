class Gift {
  final int id;
  String _name;
  String _category;
  double _price;
  String _status; // e.g., "available", "pledged", "purchased"
  String _imageUrl; // URL to the gift's image
  int _eventId;
  int _userId;
  final String? firebaseKey;
  int? pledgedTo;

  Gift({
    this.firebaseKey,
    required this.id,
    required String name,
    required String category,
    required double price,
    required String status,
    required int eventId,
    required int userId,
    String imageUrl = '',
    this.pledgedTo,
  })
      : _name = name,
        _category = category,
        _price = price,
        _status = status,
        _eventId = eventId,
        _userId = userId,
        _imageUrl = imageUrl;

  // Getters
  String get name => _name;

  String get category => _category;

  double get price => _price;

  String get status => _status;

  String get imageUrl => _imageUrl;

  int get eventId => _eventId;

  int get userId => _userId;

  // Setters with restrictions for pledged gifts
  set name(String value) {
    if (_status != 'pledged') _name = value;
  }

  set category(String value) {
    if (_status != 'pledged') _category = value;
  }

  set price(double value) {
    if (_status != 'pledged') _price = value;
  }

  set status(String value) {
    if (_status != 'pledged') _status = value;
  }

  set imageUrl(String value) {
    if (_status != 'pledged') _imageUrl = value;
  }

  // Convert a Map (from SQLite) to a Gift instance
  factory Gift.fromMap(Map<String, dynamic> map) {
    return Gift(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      price: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : map['price'],
      // Safely handle int to double conversion
      status: map['status'],
      eventId: map['eventId'],
      userId: map['userId'],
      pledgedTo: map['pledgedTo'],
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  // Convert a Gift instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': _name,
      'category': _category,
      'price': _price,
      'status': _status,
      'eventId': _eventId,
      'userId': _userId,
      'imageUrl': _imageUrl,
      'pledgedTo': pledgedTo, // Ensure pledgedTo is included
    };
  }


  // Convert Firebase data to a Gift instance
  factory Gift.fromFirebase(Map<String, dynamic> data, String key) {
    return Gift(
      firebaseKey: key,
      id: data['id'],
      name: data['name'],
      category: data['category'],
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : data['price'],
      status: data['status'],
      eventId: data['eventId'],
      userId: data['userId'],
      pledgedTo: data['pledgedTo'],
      // Ensure pledgedTo is deserialized
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}