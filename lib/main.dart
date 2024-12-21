import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Import for FirebaseDatabase
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/event_list_page.dart';
import 'screens/gift_list_page.dart';
import 'screens/gift_details_page.dart';
import 'screens/profile_page.dart';
import 'screens/my_pledged_gifts_page.dart';
import 'models/gift.dart';
import 'models/user.dart' as AppUser; // Alias the custom User model
import 'services/database_helper.dart'; // Import DatabaseHelper
import 'themes/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase with custom Realtime Database URL
  await Firebase.initializeApp();
  deleteDatabaseFile();

  // Set the Firebase Realtime Database URL
  FirebaseDatabase.instance.databaseURL =
  "https://hediaty-project-default-rtdb.europe-west1.firebasedatabase.app";

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hedieaty App',
      theme: buildAppTheme(),
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => AuthWrapper());
          case '/eventList':
            final user = settings.arguments as AppUser.User;
            return MaterialPageRoute(
                builder: (context) => EventListPage(currentUser: user));
          case '/giftList':
            final args = settings.arguments as Map<String, dynamic>;
            final int eventId = args['eventId'];
            final AppUser.User currentUser = args['currentUser'];
            return MaterialPageRoute(
                builder: (context) =>
                    GiftListPage(eventId: eventId, currentUser: currentUser));
          case '/giftDetails':
            final args = settings.arguments as Map<String, dynamic>;
            final gift = settings.arguments as Gift;
            final AppUser.User currentUser = args['currentUser'];
            return MaterialPageRoute(
                builder: (context) =>
                    GiftDetailsPage(gift: gift, currentUser: currentUser));
          case '/profile':
            final user = settings.arguments as AppUser.User; // Use the alias here
            return MaterialPageRoute(
                builder: (context) => ProfilePage(user: user));
          case '/myPledgedGifts':
            final user = settings.arguments as AppUser.User; // Use the alias here
            return MaterialPageRoute(
                builder: (context) => MyPledgedGiftsPage(user: user));
          default:
            assert(false, 'Need to implement ${settings.name}');
            return null;
        }
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          // User is logged in
          return FutureBuilder<AppUser.User?>(
            future: _getCurrentUserFromDatabase(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (userSnapshot.hasData) {
                return HomePage(currentUser: userSnapshot.data!); // Pass currentUser
              }
              return LoginPage(); // Redirect to login if user not found in DB
            },
          );
        }
        // User is not logged in
        return LoginPage();
      },
    );
  }

  Future<AppUser.User?> _getCurrentUserFromDatabase(String firebaseUid) async {
    final dbHelper = DatabaseHelper(); // Instantiate DatabaseHelper
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> userMaps = await db.query(
      'users',
      where: 'firebaseId = ?',
      whereArgs: [firebaseUid],
    );

    if (userMaps.isNotEmpty) {
      return AppUser.User.fromMap(userMaps.first);
    }

    return null; // User not found in local database
  }
}
