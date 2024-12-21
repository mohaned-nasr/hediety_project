import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    primarySwatch: Colors.red,
    primaryColor: Colors.red.shade700,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.red,
      accentColor: Colors.red.shade200, // Secondary color
    ),
    scaffoldBackgroundColor: Colors.red.shade50,

    // Updated TextTheme
    textTheme: TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red.shade700),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red.shade600),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
    ),

    // Input Fields
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500),
      prefixIconColor: Colors.red.shade700,
    ),

    // Button Styles
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        textStyle: TextStyle(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.red.shade700,
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.red.shade700,
      elevation: 4,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.red.shade700,
      foregroundColor: Colors.white,
    ),

    // Divider Styling
    dividerTheme: DividerThemeData(
      color: Colors.red.shade200,
      thickness: 1,
    ),

    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.all(Colors.red.shade700),
      checkColor: MaterialStateProperty.all(Colors.white),
    ),

    // Icon Theme
    iconTheme: IconThemeData(color: Colors.red.shade700, size: 24),
  );
}
