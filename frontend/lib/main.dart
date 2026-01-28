import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:frontend/pages/authPage.dart';
import 'package:frontend/pages/homePage.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/auth_service.dart';

void main() async {
  setPathUrlStrategy();
  
  // Initialize auth service
  final authService = AuthService();
  await authService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(authService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Verify token on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().verifyToken();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MRI Analysis',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => _buildHome(),
        '/home': (context) => const HomePage(),
      },
    );
  }

  Widget _buildHome() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoggedIn) {
          return const HomePage();
        } else {
          return const AuthPage();
        }
      },
    );
  }
}