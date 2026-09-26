import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_strings.dart';
import '../features/shared/placeholder_screen.dart';
import '../features/splash/splash_screen.dart';

/// Pandit app routes - Stage 1 scaffold only.
///
/// Screens for auth, dashboard, bookings, availability, earnings etc.
/// are delivered by later stages; every deferred path currently renders
/// a [PlaceholderScreen].
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (BuildContext context, GoRouterState state) =>
            const PlaceholderScreen(
          title: AppStrings.loginTitle,
          icon: Icons.login_rounded,
        ),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (BuildContext context, GoRouterState state) =>
            const PlaceholderScreen(
          title: AppStrings.dashboardTitle,
          icon: Icons.dashboard_rounded,
        ),
      ),
      GoRoute(
        path: '/bookings',
        name: 'bookings',
        builder: (BuildContext context, GoRouterState state) =>
            const PlaceholderScreen(
          title: 'Booking Requests',
          icon: Icons.receipt_long_rounded,
        ),
      ),
      GoRoute(
        path: '/availability',
        name: 'availability',
        builder: (BuildContext context, GoRouterState state) =>
            const PlaceholderScreen(
          title: 'Availability',
          icon: Icons.event_available_rounded,
        ),
      ),
      GoRoute(
        path: '/earnings',
        name: 'earnings',
        builder: (BuildContext context, GoRouterState state) =>
            const PlaceholderScreen(
          title: 'Earnings',
          icon: Icons.account_balance_wallet_rounded,
        ),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (BuildContext context, GoRouterState state) =>
            const PlaceholderScreen(
          title: 'Profile & Verification',
          icon: Icons.verified_user_rounded,
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (BuildContext context, GoRouterState state) =>
            const PlaceholderScreen(
          title: 'Settings',
          icon: Icons.settings_rounded,
        ),
      ),
    ],
  );
}
