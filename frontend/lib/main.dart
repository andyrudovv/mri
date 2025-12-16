import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:frontend/pages/authPage.dart';
import 'package:frontend/pages/homePage.dart';

void main() {
  setPathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MRI analisys',
      debugShowCheckedModeBanner: false,

      initialRoute: '/',
      routes: {
        '/': (context) => AuthPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}