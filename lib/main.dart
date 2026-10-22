import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_home.dart';
import 'screens/user/user_home.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/startup/firebase_setup_screen.dart';
import 'theme/nosh_theme.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';

/// Entry point — initialises Firebase then runs the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startupError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _roleUserId;
  Future<String>? _roleFuture;

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

        if (_roleUserId != user.uid || _roleFuture == null) {
          _roleUserId = user.uid;
          _roleFuture = AuthService.resolveRole(user);
        }

        return FutureBuilder<String>(
          key: ValueKey(user.uid),
          future: _roleFuture,
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const _SplashLoader();
            }

            if (roleSnapshot.hasError || !roleSnapshot.hasData) {
              return _AccountRoleErrorScreen(
                onRetry: () =>
                    setState(() => _roleFuture = AuthService.resolveRole(user)),
              );
            }

            if (roleSnapshot.data == 'admin') return const AdminHome();
            return const UserHome();
          },
        );
      },
    );
  }
}

class _AccountRoleErrorScreen extends StatefulWidget {
  const _AccountRoleErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  State<_AccountRoleErrorScreen> createState() =>
      _AccountRoleErrorScreenState();
}

class _AccountRoleErrorScreenState extends State<_AccountRoleErrorScreen> {
  String? _signOutError;

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _signOutError = error.message ?? error.code);
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _signOutError = error.message ?? error.code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C110A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFFF6D00),
                size: 42,
              ),
              const SizedBox(height: 16),
              const Text(
                'Could not load your account details.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your connection and Firestore access, then try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              if (_signOutError != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Sign out failed: $_signOutError',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: widget.onRetry,
                child: const Text('Try again'),
              ),
              TextButton(onPressed: _signOut, child: const Text('Sign out')),
            ],
          ),
        ),
      ),
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
