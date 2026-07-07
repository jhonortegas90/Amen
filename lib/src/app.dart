import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'design_system/amen_theme.dart';
import 'features/ads/data/ads_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/notifications/data/notification_service.dart';
import 'features/profile/data/profile_settings_provider.dart';
import 'localization/app_localizations.dart';
import 'routing/app_router.dart';

class AmenApp extends ConsumerStatefulWidget {
  const AmenApp({super.key});

  @override
  ConsumerState<AmenApp> createState() => _AmenAppState();
}

class _AmenAppState extends ConsumerState<AmenApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        final auth = ref.read(authRepositoryProvider);
        final uid = await auth.ensureSignedIn();
        await ref.read(notificationServiceProvider).registerDevice(uid);
      } catch (error) {
        debugPrint('Startup auth/notification setup skipped: $error');
      }
      await ref.read(adsServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final selectedLocale = ref.watch(appLocaleProvider);
    final textScaleFactor = ref.watch(textScaleFactorProvider);

    return MaterialApp.router(
      title: 'Amen',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AmenTheme.dark,
      darkTheme: AmenTheme.dark,
      themeMode: ThemeMode.dark,
      locale: selectedLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: false,
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
