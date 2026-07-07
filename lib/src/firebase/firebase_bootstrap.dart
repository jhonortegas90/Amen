import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'firebase_options.dart';

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({required this.isLive, this.error});

  final bool isLive;
  final Object? error;
}

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<FirebaseBootstrapResult> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      const useEmulator = bool.fromEnvironment(
        'USE_FIREBASE_EMULATOR',
        defaultValue: false,
      );
      if (useEmulator) {
        // macOS/iOS Simulator uses localhost, Android Emulator uses 10.0.2.2
        final host = !kIsWeb && Platform.isAndroid ? '10.0.2.2' : 'localhost';
        try {
          FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
          FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
          FirebaseStorage.instance.useStorageEmulator(host, 9199);
          await FirebaseAuth.instance.useAuthEmulator(host, 9099);
          debugPrint('Connected to Firebase Emulators at $host');
        } catch (e) {
          debugPrint('Failed to connect to Firebase Emulators: $e');
        }
      }

      try {
        if (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS)) {
          await FirebaseAppCheck.instance.activate(
            providerAndroid: kDebugMode
                ? AndroidDebugProvider()
                : AndroidPlayIntegrityProvider(),
            providerApple: kDebugMode
                ? AppleDebugProvider()
                : AppleDeviceCheckProvider(),
          );
        }
      } catch (appCheckError) {
        // App check might fail on desktop or unsupported environments; ignore in debug
        if (kDebugMode) {
          debugPrint(
            'AppCheck failed to initialize in debug mode (ignored): $appCheckError',
          );
        } else {
          rethrow;
        }
      }

      return const FirebaseBootstrapResult(isLive: true);
    } catch (error) {
      debugPrint('Amen is running in demo mode: $error');
      return FirebaseBootstrapResult(isLive: false, error: error);
    }
  }
}

final firebaseBootstrapProvider = Provider<FirebaseBootstrapResult>(
  (_) => const FirebaseBootstrapResult(isLive: false),
);
