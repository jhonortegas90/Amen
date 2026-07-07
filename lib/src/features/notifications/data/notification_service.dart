import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../firebase/firebase_bootstrap.dart';

class NotificationService {
  NotificationService({
    required this.bootstrap,
    this.messaging,
    this.firestore,
  });

  final FirebaseBootstrapResult bootstrap;
  final FirebaseMessaging? messaging;
  final FirebaseFirestore? firestore;

  Future<void> registerDevice(String uid) async {
    if (!bootstrap.isLive) return;

    try {
      final messagingClient = messaging ?? FirebaseMessaging.instance;
      await messagingClient.requestPermission(provisional: true);
      final token = await messagingClient.getToken();
      if (token == null) return;

      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      await (firestore ?? FirebaseFirestore.instance)
          .collection('device_tokens')
          .doc(uid)
          .collection('tokens')
          .doc(token)
          .set({
            'token': token,
            'platform': Platform.operatingSystem,
            'locale': locale.languageCode,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {
      // Notification registration should never block the prayer wall.
    }
  }

  Future<NotificationSettings?> requestAuthorizationPermission() async {
    try {
      final messagingClient = messaging ?? FirebaseMessaging.instance;
      return await messagingClient.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {
      return null;
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(bootstrap: ref.watch(firebaseBootstrapProvider));
});
