import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../navigation/main_navigation.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/property/property_detail_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../models/property.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: _AuthListenable(authCubit),
    redirect: (context, state) {
      final authState = authCubit.state;
      final loc = state.matchedLocation;
      final onSplash = loc == '/splash';
      final onOnboarding = loc == '/onboarding';
      final onAuth = loc.startsWith('/auth');
      final onHome = loc == '/home';

      // Still checking token — stay on splash
      if (authState is AuthInitial || authState is AuthLoading) {
        return onSplash ? null : '/splash';
      }

      // Logged in — go straight to home from splash/onboarding/auth
      if (authState is AuthAuthenticated) {
        if (onSplash || onOnboarding || onAuth) return '/home';
        return null;
      }

      // Not logged in
      if (authState is AuthUnauthenticated) {
        // Return visitor: skip onboarding, go straight to home (guest mode)
        if (onSplash) {
          return authState.onboardingSeen ? '/home' : '/onboarding';
        }
        // Allow browsing home as a guest, and auth/onboarding screens
        if (onHome || onOnboarding || onAuth) return null;
        return '/onboarding';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, __) => const MainNavigation()),
      GoRoute(
        path: '/property/:id',
        builder: (_, state) {
          final property = state.extra as Property;
          return PropertyDetailScreen(property: property);
        },
      ),
    ],
  );
}

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(AuthCubit cubit) {
    cubit.stream.listen((_) => notifyListeners());
  }
}
