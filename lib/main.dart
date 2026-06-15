import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Explicitly importing application screen contexts
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/admin_home.dart';
import 'screens/patient_home_refactored.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medliy Healthcare Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B),
          primary: const Color(0xFF00796B),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const AuthScreen(),
        '/admin_home': (context) => const AdminHomeScreen(),
        '/patient_home': (context) => const PatientHomeScreenRefactored(),
      },
    );
  }
}
