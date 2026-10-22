import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_home.dart';
import 'screens/user/user_home.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/startup/firebase_setup_screen.dart';
import 'theme/nosh_theme.dart';

/// Entry point — initialises Firebase then runs the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startupError;
  try {
    await Firebase.initializeApp();
  } catch (error, stackTrace) {
    startupError = _firebaseStartupMessage(error);
    debugPrint('Firebase initialization failed: $error\n$stackTrace');
  }
  runApp(NoshBistroApp(startupErrorMessage: startupError));
}

String _firebaseStartupMessage(Object error) {
  if (kIsWeb && error is AssertionError) {
    return 'Firebase Web options are missing. Register a Web app in your '
        'Firebase project and run `flutterfire configure` to generate '
        'firebase_options.dart.';
  }
  return 'Firebase could not be initialized on this device. Check the '
      'platform configuration and run `flutterfire configure`.';
}

class NoshBistroApp extends StatelessWidget {
  const NoshBistroApp({super.key, this.startupErrorMessage});

  final String? startupErrorMessage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nosh Bistro',
      debugShowCheckedModeBanner: false,
      theme: NoshTheme.theme,
      home: startupErrorMessage == null
          ? const SplashScreen()
          : FirebaseSetupScreen(message: startupErrorMessage!),
    );
  }
}

/// Listens to Firebase Auth state changes.
/// • Signed out  → LoginScreen
/// • Signed in   → fetches role from Firestore → AdminHome or UserHome
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // While waiting for auth state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _SplashLoader();
        }

        final user = authSnapshot.data;

        // Not logged in → show login
        if (user == null) return const LoginScreen();

        // Logged in → load role from Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const _SplashLoader();
            }

            if (roleSnapshot.hasError || !roleSnapshot.hasData) {
              // Firestore unreachable — default to customer view
              return const UserHome();
            }

            final role = roleSnapshot.data?.data() as Map<String, dynamic>?;
            final userRole = role?['role'] ?? 'customer';

            if (userRole == 'admin') return const AdminHome();
            return const UserHome();
          },
        );
      },
    );
  }
}

/// Full-screen loading indicator shown while auth/role resolves.
class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1C110A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_fire_department,
              color: Color(0xFFFF6D00),
              size: 48,
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Color(0xFFFF6D00), strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
