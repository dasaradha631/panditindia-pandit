import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/misc_models.dart';
import '../services/notification_service.dart';

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider({this.recipientType = 'pandit'});

  final String recipientType;
  final NotificationService _service = NotificationService();

  List<AppNotification> items = [];
  String recipientId = '';
  Timer? _pollTimer;
  bool loading = false;

  int get unreadCount => items.where((n) => !n.isRead).length;

  Future<void> load(String id) async {
    recipientId = id;
    if (id.isEmpty) return;
    loading = items.isEmpty;
    final list = await _service.list(recipientType: recipientType, recipientId: id);
    final changed = list.length != items.length ||
        list.any((n) => n.isRead != (items.any((o) => o.id == n.id && o.isRead)));
    items = list;
    loading = false;
    if (changed) notifyListeners();
  }

  Future<void> markRead(AppNotification n) async {
    if (n.id == null || n.isRead) return;
    final idx = items.indexWhere((e) => e.id == n.id);
    if (idx < 0) return; // a poll dropped it between the tile building and the tap
    items[idx] = AppNotification(
      id: n.id,
      title: n.title,
      message: n.message,
      type: n.type,
      isRead: true,
      bookingId: n.bookingId,
      createdAt: n.createdAt,
    );
    notifyListeners();
    await _service.markRead(n.id!);
  }

  Future<void> markAllRead() async {
    items = items
        .map((n) => AppNotification(
              id: n.id,
              title: n.title,
              message: n.message,
              type: n.type,
              isRead: true,
              bookingId: n.bookingId,
              createdAt: n.createdAt,
            ))
        .toList();
    notifyListeners();
    await _service.markAllRead(recipientType: recipientType, recipientId: recipientId);
  }

  Future<void> remove(AppNotification n) async {
    items = items.where((e) => e.id != n.id).toList();
    notifyListeners();
    if (n.id != null) await _service.remove(n.id!);
  }

  Future<void> clearAll() async {
    items = [];
    notifyListeners();
    await _service.clearAll(recipientType: recipientType, recipientId: recipientId);
  }

  void startPolling(String id) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) => load(id));
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
