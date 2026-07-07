import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/motion/water_ripple_page_route.dart';
import '../features/admin/presentation/admin_catalog_screen.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/shell/presentation/app_shell.dart';

class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier(this._ref) {
    _ref.listen<AsyncValue<AppUser?>>(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

final authStateNotifierProvider = Provider<AuthStateNotifier>((ref) {
  return AuthStateNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authStateNotifierProvider);
  final browserPath = kIsWeb ? Uri.base.path : '';
  final initialLocation = kIsWeb && browserPath.isNotEmpty && browserPath != '/'
      ? browserPath
      : '/onboarding';

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authNotifier,
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const AppShell(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminCatalogScreen(),
      ),
      GoRoute(
        path: '/library',
        name: 'library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => buildWaterRipplePage(
          context: context,
          state: state,
          child: const NotificationsScreen(),
        ),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final user = authState.value;
      final isLoggedIn = user != null && !user.isAnonymous;
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (isLoggedIn && isOnboarding) {
        return '/';
      }

      return null;
    },
  );
});
