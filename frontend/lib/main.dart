import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:frontend/pages/authPage.dart';
import 'package:frontend/pages/homePage.dart';
import 'package:frontend/pages/profilePage.dart';
import 'package:frontend/pages/patientHomePage.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/patient_auth_provider.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/patient_auth_service.dart';

void main() async {
  setPathUrlStrategy();

  // Initialize auth services
  final authService = AuthService();
  final patientAuthService = PatientAuthService();
  await authService.init();
  await patientAuthService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(authService),
        ),
        ChangeNotifierProvider(
          create: (context) => PatientAuthProvider(patientAuthService),
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
    // Verify tokens on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().verifyToken();
      context.read<PatientAuthProvider>().init();
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
        '/profile': (context) => const ProfilePage(),
        '/patient-home': (context) => const PatientHomePage(),
      },
    );
  }

  Widget _buildHome() {
    return Consumer2<AuthProvider, PatientAuthProvider>(
      builder: (context, authProvider, patientAuthProvider, _) {
        if (authProvider.isLoggedIn) {
          return const HomePage();
        } else if (patientAuthProvider.isLoggedIn) {
          return const PatientHomePage();
        } else {
          return const AuthPage();
        }
      },
    );
  }
}