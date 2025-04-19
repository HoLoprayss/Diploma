import 'package:flutter/material.dart';
import 'package:realm/realm.dart';

import 'MainScreen.dart';
import 'SplashScreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/main': (context) => MainScreen(),
      },
    );
  }
}