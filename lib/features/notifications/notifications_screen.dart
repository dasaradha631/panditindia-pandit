import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/misc_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/pandit_profile_provider.dart';
import '../app_tab.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.onNavigate});

  /// Pane switch handed over by the push site (the header bell in
  /// `main_shell.dart`, the menu drawer) so a tapped alert can jump straight
  /// to the screen that owns it — web `handleSelectNotification`. When the
  /// route was pushed without it (profile screen) a tap only marks read.
  final void Function(AppTab tab)? onNavigate;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationsProvider? _notifs;

  String get _recipientId {
    final auth = context.read<AuthProvider>();
    // Rows are keyed by the loginpage id (`system_notifications.recipient_id`),
    // so prefer it and only fall back to the display name when the session
    // was restored without one.
    if (auth.session?.id != null) return '${auth.session!.id}';
    final profile = context.read<PanditProfileProvider>().profile;
    return profile?.fullName ??
        auth.session?.name ??
        auth.session?.username ??
        '';
  }

  @override
  void initState() {
    super.initState();
    // Captured while the element is still active: dispose() runs during
    // tree teardown, when `context.read()` would throw "Looking up a
    // deactivated widget's ancestor is unsafe".
    _notifs = context.read<NotificationsProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // screen already closed
      final p = _notifs!;
      final id = _recipientId;
      p.load(id);
      p.startPolling(id);
    });
  }

  @override
  void dispose() {
    _notifs?.stopPolling();
    super.dispose();
  }

  IconData _iconFor(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'booking':
      case 'assignment':
        return Icons.assignment_turned_in_outlined;
      case 'payment':
      case 'payout':
      case 'dakshina':
        return Icons.currency_rupee_rounded;
      case 'review':
        return Icons.star_outline_rounded;
      case 'samagri':
        return Icons.inventory_2_outlined;
      case 'gps':
      case 'tracking':
        return Icons.broadcast_on_personal_outlined;
      case 'ritual':
        return Icons.local_fire_department_outlined;
      default:
        return Icons.notifications_rounded;
    }
  }

  /// Web parity (`PanditDashboardPage.jsx:221-234`): keyword route from the
  /// alert payload to the pane that owns it, in the same keyword order.
  AppTab _destinationFor(AppNotification n) {
    final text = '${n.title ?? ''} ${n.message ?? ''} ${n.type ?? ''}'.toLowerCase();
    if (text.contains('active') || text.contains('ritual') || text.contains('journey')) {
      return AppTab.schedule;
    }
    if (text.contains('gps') || text.contains('navigation') || text.contains('route')) {
      return AppTab.live;
    }
    if (text.contains('completed') || text.contains('dakshina') || text.contains('payout')) {
      return AppTab.earnings;
    }
    if (text.contains('samagri')) return AppTab.samagri;
    if (text.contains('review') || text.contains('blessing')) return AppTab.blessings;
    return AppTab.schedule;
  }

  /// Fresh alerts read as "2h ago"; anything older than a day flips to the
  /// absolute date so the archive stays scannable (web panel does the same).
  String _timestamp(AppNotification n) {
    final raw = n.createdAt;
    if (raw == null || raw.isEmpty) return '';
    final d = DateTime.tryParse(raw) ?? DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (d == null) return Fmt.relative(raw);
    if (DateTime.now().difference(d).inHours < 24) return Fmt.relative(raw);
    return Fmt.date(raw);
  }

  /// Tap marks the alert read (`NotificationPanel.jsx:130-133`), then jumps to
  /// its destination pane and closes this screen (the web panel closes too).
  /// Without [NotificationsScreen.onNavigate] there is no booking-details
  /// route on mobile, so marking read is all a tap can do.
  void _open(NotificationsProvider p, AppNotification n) {
    p.markRead(n);
    final onNavigate = widget.onNavigate;
    if (onNavigate == null) return;
    onNavigate(_destinationFor(n));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NotificationsProvider>();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: GradientAppBar(
        title: 'Notifications',
        actions: [
          if (p.items.isNotEmpty)
            TextButton(
              onPressed: () => p.markAllRead(),
              child: const Text('MARK ALL',
                  style: TextStyle(
                      color: AppColors.accent, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.white,
            onSelected: (v) async {
              if (v == 'clear') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: const Text('Clear all notifications?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear All', style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                );
                if (ok == true && mounted) p.clearAll();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear', child: Text('Clear all notifications')),
            ],
          ),
        ],
      ),
      body: p.loading && p.items.isEmpty
          ? const LoadingView(label: 'Loading notifications...')
          : p.items.isEmpty
              ? const EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No notifications',
                  subtitle: 'New assignments and ceremony updates will show up here.',
                )
              : RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () => p.load(p.recipientId),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    itemCount: p.items.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        i < p.items.length ? _tile(p, p.items[i]) : _footerActions(p),
                  ),
                ),
    );
  }

  /// Bottom-of-list bulk actions (web panel footer parity).
  Widget _footerActions(NotificationsProvider p) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: p.markAllRead,
              icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.accent),
              label: const Text('Mark All Read',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.accent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(0, 42),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: const Text('Clear all notifications?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear All', style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                );
                if (ok == true && mounted) p.clearAll();
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
              label: const Text('Clear All',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(0, 42),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(NotificationsProvider p, AppNotification n) {
    return Dismissible(
      key: ValueKey('pandit-notif-${n.id ?? n.createdAt ?? n.title}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => p.remove(n),
      child: Material(
        color: n.isRead ? Colors.white : AppColors.accentLight,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _open(p, n),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: n.isRead ? AppColors.border : AppColors.accent.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(_iconFor(n.type), size: 19, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title ?? 'Notification',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: n.isRead ? FontWeight.w700 : FontWeight.w900,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(n.message ?? '',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.45)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(_timestamp(n),
                              style: const TextStyle(
                                  fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                          if (n.bookingId != null) ...[
                            const SizedBox(width: 8),
                            const Text('•', style: TextStyle(color: AppColors.textMuted)),
                            const SizedBox(width: 8),
                            Text(AppStatus.displayBookingId(n.bookingId),
                                style: const TextStyle(
                                    fontSize: 10.5, color: AppColors.accent, fontWeight: FontWeight.w800)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
