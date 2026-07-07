import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/data/notification_service.dart';

class AppLocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    return const Locale('en');
  }

  void setLocale(Locale locale) {
    state = locale;
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(
  AppLocaleNotifier.new,
);

class TextScaleFactorNotifier extends Notifier<double> {
  @override
  double build() {
    return 1.0;
  }

  void setScaleFactor(double factor) {
    state = factor.clamp(0.8, 1.6);
  }

  void increase() {
    state = (state + 0.1).clamp(0.8, 1.6);
  }

  void decrease() {
    state = (state - 0.1).clamp(0.8, 1.6);
  }

  void reset() {
    state = 1.0;
  }
}

final textScaleFactorProvider = NotifierProvider<TextScaleFactorNotifier, double>(
  TextScaleFactorNotifier.new,
);

class NotificationsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    return true;
  }

  Future<void> setEnabled(bool enabled, NotificationService notificationService) async {
    state = enabled;
    if (enabled) {
      await notificationService.requestAuthorizationPermission();
    }
  }

  Future<void> toggle(NotificationService notificationService) async {
    await setEnabled(!state, notificationService);
  }
}

final notificationsEnabledProvider =
    NotifierProvider<NotificationsEnabledNotifier, bool>(
  NotificationsEnabledNotifier.new,
);
