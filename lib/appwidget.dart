import 'package:flutter/material.dart';
import 'package:myapp/home.dart';

class AppWidget extends StatelessWidget {

// Suggested code may be subject to a license. Learn more: ~LicenseLog:499594023.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      theme: ThemeData.dark()
    );
  }
}