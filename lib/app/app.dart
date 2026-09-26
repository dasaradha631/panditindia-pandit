import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';
import 'theme/theme.dart';

/// Application root for the Pandit / Acharya companion app.
class PanditIndiaPanditApp extends StatefulWidget {
  const PanditIndiaPanditApp({super.key, this.router});

  /// Injectable for widget tests / previews.
  final GoRouter? router;

  @override
  State<PanditIndiaPanditApp> createState() => _PanditIndiaPanditAppState();
}

class _PanditIndiaPanditAppState extends State<PanditIndiaPanditApp> {
  late final GoRouter _router = widget.router ?? createRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PanditIndia Pandit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
