import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static final Future<void> _googleSignInInitialization = _googleSignIn
      .initialize();

  static Future<String> signInWithGoogle() async {
    final UserCredential credential;
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      credential = await FirebaseAuth.instance.signInWithPopup(provider);
    } else {
      await _googleSignInInitialization;
      if (!_googleSignIn.supportsAuthenticate()) {
        throw UnsupportedError(
          'Google sign-in is not supported on this platform.',
        );
      }

      await _googleSignIn.signOut();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google did not return an ID token.',
        );
      }

      credential = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    }

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'missing-user',
        message: 'Firebase did not return a signed-in user.',
      );
    }
    return resolveRole(user);
  }

  static Future<String> resolveRole(User user) async {
    final userDocument = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    return FirebaseFirestore.instance.runTransaction<String>((
      transaction,
    ) async {
      final snapshot = await transaction.get(userDocument);
      final data = snapshot.data();
      if (!snapshot.exists) {
        transaction.set(userDocument, {
          'email': user.email ?? '',
          'displayName': user.displayName,
          'photoUrl': user.photoURL,
          'role': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
        });
        return 'customer';
      }

      final role = data?['role'];
      if (role is! String || role.isEmpty) {
        return 'customer';
      }
      return role == 'admin' ? 'admin' : 'customer';
    });
  }

  static Future<void> sendPasswordReset(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }
}
