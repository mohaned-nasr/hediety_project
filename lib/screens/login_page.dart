import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'registration_page.dart';
import 'home_page.dart';
import '../models/user.dart' as AppUser; // Alias for custom User model
import '../services/database_helper.dart'; // Import DatabaseHelper

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper dbHelper = DatabaseHelper(); // Initialize DatabaseHelper
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  // Function to handle login
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Authenticate user with Firebase
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Query local database for the logged-in user
        final db = await dbHelper.database;
        final List<Map<String, dynamic>> userMaps = await db.query(
          'users',
          where: 'firebaseId = ?',
          whereArgs: [firebaseUser.uid],
        );

        if (mounted) {
          if (userMaps.isNotEmpty) {
            // Convert database result into custom User object
            AppUser.User currentUser = AppUser.User.fromMap(userMaps.first);

            // Navigate to HomePage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => HomePage(currentUser: currentUser)),
            );
          } else {
            setState(() {
              _errorMessage =
              'User not found in local database. Please register again.';
            });
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if(mounted) {
        setState(() {
          _errorMessage = e.message ?? 'An error occurred. Please try again.';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50, // Light red background
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 50),
              // Logo or Image at the top
              Center(
                child: Image.asset(
                  'assets/wrapped_gift.webp', // Add your asset image path
                  height: 200,
                ),
              ),
              SizedBox(height: 30),

              // Welcome Title
              Text(
                'Welcome to Hedieaty!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Your perfect gift management app',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),

              // Email Input Field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.red.shade700),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red.shade700),
                  ),
                  prefixIcon: Icon(Icons.email, color: Colors.red),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),

              // Password Input Field
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.red.shade700),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red.shade700),
                  ),
                  prefixIcon: Icon(Icons.lock, color: Colors.red),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Loading Indicator or Login Button
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(color: Colors.red),
                )
              else
                ElevatedButton(
                  key: Key('loginButton'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _login,
                  child: Text(
                    'Login',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              SizedBox(height: 10),

              // Registration Navigation
              TextButton(
                key: Key('registerNavigationButton'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegistrationPage()),
                  );
                },
                child: Text(
                  "Don't have an account? Register here",
                  style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
