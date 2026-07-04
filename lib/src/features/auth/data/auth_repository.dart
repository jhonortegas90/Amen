import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../firebase/firebase_bootstrap.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.isAnonymous,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  final String uid;
  final bool isAnonymous;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  static const demoUser = AppUser(
    uid: 'demo-local-author',
    isAnonymous: true,
    displayName: 'Pilgrim',
  );
}

class AuthRepository {
  AuthRepository({
    required this.bootstrap,
    this.firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : googleSignIn = googleSignIn ?? GoogleSignIn();

  static const demoUid = 'demo-local-author';

  final FirebaseBootstrapResult bootstrap;
  final FirebaseAuth? firebaseAuth;
  final GoogleSignIn googleSignIn;

  FirebaseAuth get _auth => firebaseAuth ?? FirebaseAuth.instance;

  bool get isLive => bootstrap.isLive;

  String? get currentUid {
    if (!isLive) return demoUid;
    return _auth.currentUser?.uid;
  }

  AppUser? get currentUser {
    if (!isLive) return AppUser.demoUser;
    final user = _auth.currentUser;
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      isAnonymous: user.isAnonymous,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
  }

  Stream<AppUser?> authStateChanges() {
    if (!isLive) {
      return Stream.value(AppUser.demoUser);
    }
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return AppUser(
        uid: user.uid,
        isAnonymous: user.isAnonymous,
        displayName: user.displayName,
        email: user.email,
        photoUrl: user.photoURL,
      );
    });
  }

  Future<String> ensureSignedIn() async {
    if (!isLive) return demoUid;

    final existing = _auth.currentUser;
    if (existing != null) return existing.uid;

    final credential = await _auth.signInAnonymously();
    return credential.user?.uid ?? demoUid;
  }

  /// Sign in with Google (OAuth 2.0)
  Future<UserCredential?> signInWithGoogle() async {
    if (!isLive) return null;

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    if (googleAuth.idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google did not return an ID token for Firebase sign-in.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _linkAnonymousOrSignIn(credential);
  }

  /// Sign in with Apple (OAuth 2.0)
  Future<UserCredential?> signInWithApple() async {
    if (!isLive) return null;

    if (!_usesNativeAppleSignIn) {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
      return _linkAnonymousOrSignInWithProvider(provider);
    }

    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    if (appleCredential.identityToken == null) {
      throw FirebaseAuthException(
        code: 'missing-apple-id-token',
        message: 'Apple did not return an identity token for Firebase sign-in.',
      );
    }

    final OAuthProvider oauthProvider = OAuthProvider('apple.com');
    final credential = oauthProvider.credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
      rawNonce: rawNonce,
    );

    final userCredential = await _linkAnonymousOrSignIn(credential);
    final displayName = _appleDisplayName(appleCredential);
    final user = userCredential?.user;
    if (displayName != null &&
        displayName.isNotEmpty &&
        (user?.displayName == null || user!.displayName!.isEmpty)) {
      await user?.updateDisplayName(displayName);
    }

    return userCredential;
  }

  Future<void> signOut() async {
    if (!isLive) return;
    await googleSignIn.signOut();
    await _auth.signOut();
    await ensureSignedIn();
  }

  Future<UserCredential?> _linkAnonymousOrSignIn(
    AuthCredential credential,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      try {
        return await currentUser.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          return _auth.signInWithCredential(credential);
        }
        rethrow;
      }
    }

    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential?> _linkAnonymousOrSignInWithProvider(
    AuthProvider provider,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      try {
        if (kIsWeb) {
          return currentUser.linkWithPopup(provider);
        }
        return currentUser.linkWithProvider(provider);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          if (kIsWeb) {
            return _auth.signInWithPopup(provider);
          }
          return _auth.signInWithProvider(provider);
        }
        rethrow;
      }
    }

    if (kIsWeb) {
      return _auth.signInWithPopup(provider);
    }
    return _auth.signInWithProvider(provider);
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String? _appleDisplayName(AuthorizationCredentialAppleID credential) {
    final parts = [
      credential.givenName?.trim(),
      credential.familyName?.trim(),
    ].where((part) => part != null && part.isNotEmpty).cast<String>();
    final name = parts.join(' ').trim();
    return name.isEmpty ? null : name;
  }

  bool get _usesNativeAppleSignIn =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(bootstrap: ref.watch(firebaseBootstrapProvider));
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});
