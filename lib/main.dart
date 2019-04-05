import 'package:flutter/material.dart';
import 'constants/constants.dart';
import 'screens/Login.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Chat',
      theme: ThemeData(primaryColor: themeColor),
      home: LoginScreen(title: 'Firebase Chat'),
      debugShowCheckedModeBanner: false,
    );
  }
}
