import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/login_screen.dart';
import '../../providers/auth_provider.dart';
import '../widgets/common.dart';

/// Hosts the session-expiry reactions for the whole app.
///
/// * [AuthProvider.onIdleExpired] — the 15-minute inactivity timer signed the
///   Acharya out; route to the sign-in screen with an explanation instead of
///   leaving stale, empty screens.
/// * [AuthProvider.onSessionConflict] — the backend rejected the token because
///   the account was signed in on another browser/device (single-session
///   enforcement, web parity with the `session-conflict` event).
///
/// Also re-verifies the session with `GET /session-check` whenever the app
/// returns to the foreground (web parity: the focus/visibility listeners).
class SessionGuard extends StatefulWidget {
  const SessionGuard({super.key, required this.navigatorKey, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    AuthProvider.onIdleExpired = _handleIdleExpired;
    AuthProvider.onSessionConflict = _handleSessionConflict;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    if (AuthProvider.onIdleExpired == _handleIdleExpired) {
      AuthProvider.onIdleExpired = null;
    }
    if (AuthProvider.onSessionConflict == _handleSessionConflict) {
      AuthProvider.onSessionConflict = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final ctx = widget.navigatorKey.currentContext;
      if (ctx == null) return;
      // Web parity: focus/visibility re-check when the user comes back.
      ctx.read<AuthProvider>().verifySessionNow();
    }
  }

  void _routeToLogin() {
    final nav = widget.navigatorKey.currentState;
    if (nav == null) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _handleIdleExpired() {
    final ctx = widget.navigatorKey.currentContext;
    _routeToLogin();
    if (ctx == null) return;
    showAppToast(
      ctx,
      'You were signed out after 15 minutes of inactivity. Please sign in again.',
      type: ToastType.warning,
      title: 'Session Expired',
    );
  }

  void _handleSessionConflict(String message) {
    final ctx = widget.navigatorKey.currentContext;
    _routeToLogin();
    if (ctx == null) return;
    showAppToast(
      ctx,
      message.isNotEmpty
          ? message
          : 'Your account has been signed in from another browser or device. Please sign in again.',
      type: ToastType.warning,
      title: 'Signed Out',
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
