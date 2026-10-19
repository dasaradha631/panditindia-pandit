import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/l10n/app_l10n.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/common.dart';
import '../models/booking.dart';
import '../providers/assignments_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/pandit_profile_provider.dart';
import 'auth/auth_design.dart';
import 'blessings/blessings_screen.dart';
import 'completed/completed_screen.dart';
import 'dakshina/dakshina_screen.dart';
import 'home/acharya_drawer.dart';
import 'home/home_screen.dart';
import 'live/live_nav_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/pandit_profile_screen.dart';
import 'profile/support_screen.dart';
import 'samagri/samagri_screen.dart';
import 'app_tab.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// Shell hosting the dark operations top bar, left menu drawer, the seven
/// panes of the Acharya console and the bottom navigation.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AppTab tab = AppTab.schedule;
  String? _liveBookingId;

  /// Pulse loop behind the Live-tab GPS ping (web `PanditBottomNav.jsx`
  /// `animate-ping` dot), running only while a ritual streams its location.
  late final AnimationController _gpsPing;

  /// Previously visited panes so the system back gesture steps backwards
  /// through each screen the user came through (like the web app's browser
  /// back) instead of closing the app outright.
  final List<AppTab> _history = [];

  /// Providers captured while the element is still active: dispose() runs
  /// during tree teardown, when `context.read()` would throw
  /// "Looking up a deactivated widget's ancestor is unsafe".
  AssignmentsProvider? _assignments;
  NotificationsProvider? _notifications;

  @override
  void initState() {
    super.initState();
    _assignments = context.read<AssignmentsProvider>();
    _notifications = context.read<NotificationsProvider>();
    _gpsPing = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return; // logged out before the first frame was drawn
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    final profileP = context.read<PanditProfileProvider>();
    final assignments = _assignments!;
    final notifs = _notifications!;

    await profileP.load();
    if (!mounted) return;
    assignments.panditName =
        profileP.profile?.fullName ?? auth.session?.name ?? auth.session?.username ?? '';
    await assignments.load(showSpinner: true);
    if (!mounted) return;
    assignments.startPolling();
    // Assignment alerts are stored under the loginpage id the admin assign
    // endpoint resolves (`pandit_profiles.user_id`); the old display-name
    // filter matched no rows, so nothing ever arrived on this portal.
    final recipientId =
        auth.session?.id != null ? '${auth.session!.id}' : assignments.panditName;
    notifs.load(recipientId);
    notifs.startPolling(recipientId);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _gpsPing.dispose();
    _assignments?.stopPolling();
    _notifications?.stopPolling();
    super.dispose();
  }

  void _go(AppTab next) {
    if (next == tab) return;
    setState(() {
      _history.add(tab);
      tab = next;
    });
  }

  void _goFromDrawer(AppTab next) {
    Navigator.of(context).pop();
    _go(next);
  }

  void _openLive(Booking booking) {
    setState(() {
      if (tab != AppTab.live) _history.add(tab);
      _liveBookingId = '${booking.bookingId}';
      tab = AppTab.live;
    });
  }

  /// System back: return to the previous pane, then to the first pane, and
  /// only exit once the user has stepped all the way back to where they began.
  void _handleBack() {
    if (_history.isNotEmpty) {
      setState(() => tab = _history.removeLast());
      return;
    }
    if (tab != AppTab.schedule) {
      setState(() => tab = AppTab.schedule);
      return;
    }
    SystemNavigator.pop();
  }

  /// Starts or stops the Live-tab GPS ping between frames so the ticker is
  /// never kicked off in the middle of a build.
  void _syncGpsPing(bool active) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (active) {
        if (!_gpsPing.isAnimating) _gpsPing.repeat();
      } else if (_gpsPing.isAnimating) {
        _gpsPing.stop();
      }
    });
  }

  Future<void> _signOut() async {
    if (!await performSignOut(context)) return;
    if (!mounted) return;
    context.read<AssignmentsProvider>().stopPolling();
    context.read<NotificationsProvider>().stopPolling();
  }

  @override
  Widget build(BuildContext context) {
    final assignments = context.watch<AssignmentsProvider>();
    final notifs = context.watch<NotificationsProvider>();
    final profileP = context.watch<PanditProfileProvider>();
    final auth = context.watch<AuthProvider>();
    final prof = profileP.profile;
    final gpsActive = assignments.currentRitual?.isTracking == true;
    _syncGpsPing(gpsActive);

    final screens = [
      HomeScreen(onNavigate: _go, onOpenLiveNav: _openLive),
      CompletedScreen(onNavigate: _go),
      DakshinaScreen(onNavigate: _go),
      SamagriScreen(onNavigate: _go),
      LiveNavScreen(onNavigate: _go, initialBookingId: _liveBookingId),
      BlessingsScreen(onNavigate: _go),
      const PanditProfileScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.cream,
        drawer: AcharyaDrawer(
          current: tab,
          onSelect: _goFromDrawer,
          onNavigate: _go,
          onSupport: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportScreen()));
          },
          onSignOut: _signOut,
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _topBar(notifs.unreadCount, prof?.profilePhotoUrl, prof?.fullName ?? auth.session?.name),
              Expanded(child: IndexedStack(index: tab.index, children: screens)),
            ],
          ),
        ),
        bottomNavigationBar: _bottomNav(assignments.pendingCount, gpsActive),
      ),
    );
  }

  Widget _topBar(int unread, String? photoUrl, String? name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        border: Border(bottom: BorderSide(color: Color(0xFF0E3B4F), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Design G: the avatar leads the bar and opens the menu drawer.
              TopBarAvatar(
                photoUrl: photoUrl,
                name: name,
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Jai Shri Ram,',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Acharya console',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const HeaderLanguagePill(),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      key: const ValueKey<String>('header-alerts'),
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => NotificationsScreen(onNavigate: _go)),
                      ),
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: Colors.white
                                    .withValues(alpha: 0.9),
                                width: 1.2),
                          ),
                          child: Text('$unread',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Web parity (`PanditHeader.jsx`): live IST clock + Vedic day on
          // one line, availability selector right beneath (stacked on
          // narrow phones, side-by-side when there is room).
          LayoutBuilder(
            builder: (context, constraints) {
              const clock = HeaderClockPill();
              const status = HeaderStatusPill();
              if (constraints.maxWidth >= 470) {
                return Row(
                  children: [
                    const Expanded(child: clock),
                    const SizedBox(width: 8),
                    status,
                  ],
                );
              }
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  clock,
                  SizedBox(height: 6),
                  status,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Seven-slot bar (web `PanditBottomNav.jsx`): the five mobile tabs stay
  /// where they are, with the glowing Dakshina/payout FAB in the middle and
  /// the drawer's Menu button at the far right.
  Widget _bottomNav(int pendingCount, bool gpsActive) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x1A021F2C), blurRadius: 14, offset: Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _navItem(
                tab: AppTab.schedule,
                icon: Icons.event_available_outlined,
                activeIcon: Icons.event_available_rounded,
                label: context.tr('nav.puja'),
                badge: pendingCount,
              ),
              _navItem(
                tab: AppTab.live,
                icon: Icons.podcasts_outlined,
                activeIcon: Icons.podcasts_rounded,
                label: context.tr('nav.live'),
                ping: gpsActive,
              ),
              _navItem(
                tab: AppTab.completed,
                icon: Icons.fact_check_outlined,
                activeIcon: Icons.fact_check_rounded,
                label: context.tr('nav.completed'),
              ),
              _payoutFab(),
              _navItem(
                tab: AppTab.blessings,
                icon: Icons.volunteer_activism_outlined,
                activeIcon: Icons.volunteer_activism_rounded,
                label: context.tr('nav.blessings'),
              ),
              _navItem(
                tab: AppTab.profile,
                icon: Icons.badge_outlined,
                activeIcon: Icons.badge_rounded,
                label: context.tr('nav.profile'),
              ),
              _navItem(
                icon: Icons.menu_rounded,
                activeIcon: Icons.menu_rounded,
                label: context.tr('nav.menu'),
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Center glowing quick action from the web bar: opens the Dakshina &
  /// payouts ledger, which the shell already owns as a pane.
  Widget _payoutFab() {
    final selected = tab == AppTab.earnings;
    return SizedBox(
      width: 56,
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, -16),
          child: Semantics(
            button: true,
            label: 'Request Dakshina Payout',
            // The glow sits on a plain decoration outside the Material: ink
            // features are clipped to the Material box and would cut it off.
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.55),
                    blurRadius: selected ? 16 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _go(AppTab.earnings),
                  child: Ink(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.accent, Color(0xFFFBBF24), AppColors.gold],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : const Color(0xFFFDE68A),
                        width: 2.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 21,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Rose dot pulsing while the current ritual streams GPS, the mobile form of
  /// the web bar's `animate-ping` indicator.
  Widget _gpsPingDot() {
    return AnimatedBuilder(
      animation: _gpsPing,
      builder: (context, child) {
        final t = _gpsPing.value;
        return Opacity(
          opacity: 1 - t,
          child: Transform.scale(scale: 1 + t * 1.5, child: child),
        );
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
      ),
    );
  }

  Widget _navItem({
    AppTab? tab,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badge = 0,
    bool ping = false,
    VoidCallback? onTap,
  }) {
    final selected = tab != null && this.tab == tab && onTap == null;
    Widget child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(selected ? activeIcon : icon, size: 22, color: selected ? AppColors.accent : AppColors.textMuted),
        const SizedBox(height: 3),
        // Scale-down keeps the nine-letter labels ("COMPLETED", "BLESSINGS")
        // inside the ~60px cells this seven-slot bar leaves on a 412px phone.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 8.6,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: selected ? AppColors.accent : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );

    if (badge > 0 || ping) {
      child = Stack(
        clipBehavior: Clip.none,
        // Keep the icon/label centered in the tab cell when the badge or GPS
        // dot overlays — without this the Stack's default topStart alignment
        // left-shifts the Puja button the moment a pending puja arrives.
        alignment: Alignment.center,
        children: [
          child,
          if (badge > 0)
            Positioned(
              right: 22,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$badge',
                    style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900)),
              ),
            ),
          if (ping) Positioned(right: 20, top: 8, child: _gpsPingDot()),
        ],
      );
    }

    // The Menu entry ships without a tab, so only fall back to _go when the
    // caller actually passed one.
    VoidCallback? handle = onTap;
    if (handle == null && tab != null) {
      final target = tab;
      handle = () => _go(target);
    }

    return Expanded(
      child: InkWell(
        onTap: handle,
        child: child,
      ),
    );
  }
}


/// Round profile initial (or photo) shown at the top right of the operations
/// top bar. The letter is centred explicitly with a [Center] inside a tight
/// 40x40 box so it can never drift towards a corner.
class TopBarAvatar extends StatelessWidget {
  const TopBarAvatar({super.key, this.photoUrl, this.name, this.onTap});

  final String? photoUrl;
  final String? name;
  final VoidCallback? onTap;

  static const Key avatarKey = ValueKey<String>('topbar-avatar');
  static const Key letterKey = ValueKey<String>('topbar-avatar-letter');

  String get letter {
    final clean = (name ?? '').trim();
    return clean.isEmpty ? 'A' : clean.substring(0, 1).toUpperCase();
  }

  bool get _hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  Widget _fallbackLetter() {
    return Center(
      child: Text(
        letter,
        key: letterKey,
        textAlign: TextAlign.center,
        textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false, applyHeightToLastDescent: false),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.0,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: avatarKey,
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.85), width: 1.6),
          ),
          child: _hasPhoto
              ? ClipOval(
                  child: Image.network(
                    photoUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallbackLetter(),
                  ),
                )
              : _fallbackLetter(),
        ),
      ),
    );
  }
}

/// Amber live-clock pill from the web `PanditHeader.jsx`: `13/10/2026 •
/// 03:09:27 PM IST` plus the Vedic weekday chip (`Shukravara (Fri)`),
/// re-rendered every second in IST regardless of the device timezone.
class HeaderClockPill extends StatefulWidget {
  const HeaderClockPill({super.key});

  @override
  State<HeaderClockPill> createState() => _HeaderClockPillState();
}

class _HeaderClockPillState extends State<HeaderClockPill> {
  static const List<String> _vedicDays = [
    'Bhanuvara (Sun)',
    'Somavara (Mon)',
    'Mangalavara (Tue)',
    'Budhavara (Wed)',
    'Guruvara (Thu)',
    'Shukravara (Fri)',
    'Shanivara (Sat)',
  ];

  static const List<String> _monthNames = [
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december',
  ];

  late Timer _timer;
  late DateTime _ist;

  static DateTime _nowIst() =>
      DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

  @override
  void initState() {
    super.initState();
    _ist = _nowIst();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _ist = _nowIst());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  String get _clock {
    final h24 = _ist.hour;
    final h12 = ((h24 + 11) % 12) + 1;
    // QA: date as `14/october/2026` (day/month-name/year) + `hh:mm:ss AM/PM IST`.
    return '${_ist.day}/${_monthNames[_ist.month - 1]}/${_ist.year} • '
        '${_pad(h12)}:${_pad(_ist.minute)}:${_pad(_ist.second)} '
        '${h24 < 12 ? 'AM' : 'PM'} IST';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('header-clock'),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1),
      ),
      child: Row(
        children: [
          const Text('🪔', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _clock,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, Color(0xFFFBBF24)],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _vedicDays[_ist.weekday % 7],
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Availability selector mirrored from `PanditHeader.jsx` — the same three
/// options (`available` / `busy` / `leave`), pinned to busy while a ritual
/// is running, persisted through `PATCH /pandit/status`.
class HeaderStatusPill extends StatelessWidget {
  const HeaderStatusPill({super.key});

  static const Map<String, String> _labels = {
    'available': '🟢 Available for Pujas',
    'busy': '🔴 In Active Ritual',
    'leave': '⚪ On Anusthana / Leave',
  };

  static Color _dotColor(String status) {
    if (status == 'busy') return const Color(0xFFF43F5E);
    if (status == 'leave') return const Color(0xFF94A3B8);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<PanditProfileProvider>();
    final assignments = context.watch<AssignmentsProvider>();
    final ritualActive = assignments.currentRitual != null;
    final stored = profile.availability;
    final selected = ritualActive
        ? 'busy'
        : (_labels.containsKey(stored) ? stored : 'available');
    final dot = _dotColor(selected);

    return Container(
      key: const ValueKey<String>('header-status'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.75),
          width: 1.3,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            'Status:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 2),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected,
              isDense: true,
              dropdownColor: Colors.white,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 17,
                color: dot,
              ),
              selectedItemBuilder: (_) => [
                for (final key in _labels.keys)
                  Center(
                    child: Text(
                      _labels[key]!,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: key == 'busy'
                            ? const Color(0xFFF43F5E)
                            : Colors.white,
                      ),
                    ),
                  ),
              ],
              items: [
                for (final e in _labels.entries)
                  DropdownMenuItem(
                    value: e.key,
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
              ],
              onChanged: ritualActive
                  ? null
                  : (v) async {
                      if (v == null || v == selected) return;
                      final ok = await context
                          .read<PanditProfileProvider>()
                          .setAvailability(v);
                      if (!context.mounted) return;
                      showAppToast(
                        context,
                        ok
                            ? 'Status updated to ${_labels[v]}.'
                            : 'Could not update your status. Please try again.',
                        type: ok ? ToastType.success : ToastType.error,
                        title: 'Status',
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }
}
