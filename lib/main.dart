import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'MainScreen.dart';
import 'SplashScreen.dart';
import 'theme/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'MEALSAFE',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.getTheme(),
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => SplashScreen(),
            '/main': (context) => MainScreen(),
          },
        );
      },
    );
  }
}