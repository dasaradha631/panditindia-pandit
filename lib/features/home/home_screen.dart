import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/booking.dart';
import '../../providers/assignments_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pandit_profile_provider.dart';
import '../app_tab.dart';
import '../dakshina/dakshina_data.dart';
import '../requests/decline_sheet.dart';
import 'widgets/accepted_booking_card.dart';
import 'widgets/active_ritual_card.dart';
import 'widgets/dashboard_widgets.dart';
import 'widgets/pending_request_card.dart';
import 'widgets/sheets.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// Puja Schedule pane: welcome console, KPI cards, pending requests and the
/// upcoming accepted schedule with its six stage workflow.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onNavigate, required this.onOpenLiveNav});

  final void Function(AppTab tab) onNavigate;
  final void Function(Booking booking) onOpenLiveNav;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Set once the acharya dismisses the "profile incomplete" banner — it stays
  /// hidden for the rest of the session (it reappears only on a fresh open).
  bool _profilePromptDismissed = false;

  Future<void> _accept(Booking b) async {
    final error = await context.read<AssignmentsProvider>().accept(b);
    if (!mounted) return;
    if (error != null) {
      showAppToast(context, error, type: ToastType.error, title: 'Accept Request');
      return;
    }
    showAppToast(context, '🎉 Puja Request Accepted! Devotee details and venue address are now unlocked.',
        type: ToastType.success, title: 'Request Accepted');
  }

  Future<void> _decline(Booking b) async {
    final result = await showModalBottomSheet<DeclineResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeclineSheet(booking: b),
    );
    if (result == null || !mounted) return;
    final error = await context.read<AssignmentsProvider>().decline(
          b,
          reason: result.reason,
          notes: result.notes,
        );
    if (!mounted) return;
    if (error != null) {
      showAppToast(context, error, type: ToastType.error, title: 'Decline Request');
      return;
    }
    showAppToast(context, 'Request declined. It will be reassigned to another Acharya.',
        type: ToastType.info, title: 'Declined');
  }

  Future<void> _advance(Booking b, String stage) async {
    // "Start Journey" must go through the Live GPS flow so a real device
    // fix is acquired before the stage is advanced — never bump the stage
    // to en_route without location.
    if (stage == 'en_route') {
      widget.onOpenLiveNav(b);
      return;
    }
    final error = await context.read<AssignmentsProvider>().advanceStage(b, stage);
    if (!mounted) return;
    if (error != null) {
      showAppToast(context, error, type: ToastType.error, title: 'Stage Update');
      return;
    }
    showAppToast(context, AssignmentsProvider.stageLabels[stage] ?? 'Stage updated.',
        type: ToastType.success, title: 'Ceremony');
  }

  Future<void> _endPuja(Booking b) async {
    final confirmed = await confirmEndPuja(context, b);
    if (!confirmed || !mounted) return;
    final error = await context.read<AssignmentsProvider>().completeCeremony(b);
    if (!mounted) return;
    if (error != null) {
      showAppToast(context, error, type: ToastType.error, title: 'End Puja');
      return;
    }
    showAppToast(context, AssignmentsProvider.stageLabels['completed']!,
        type: ToastType.success, title: 'Puja Completed');
  }

  Future<void> _requestPayout() async {
    final profile = context.read<PanditProfileProvider>().profile;
    final completed = context.read<AssignmentsProvider>().completedBookings;
    final auth = context.read<AuthProvider>();
    await showPayoutSheet(
      context,
      amount: Fmt.inr(dakshinaBalance(completed)),
      holder: profile?.fullName ?? auth.session?.name ?? 'Acharya',
      bankLabel: bankLabel(profile),
      upiId: profile?.upiId ?? '',
    );
  }

  /// Dismissible amber alert (same palette as the pending-request banner)
  /// shown while name / phone / city are missing — tapping it opens the
  /// Acharya profile pane, mirroring the web "Go to Profile" prompt.
  Widget _profileIncompleteBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFbeb),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => widget.onNavigate(AppTab.profile),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 2),
                child: Icon(Icons.person_add_alt_1_rounded, size: 18, color: Color(0xFFB45309)),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete your Acharya profile',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF92400E),
                            height: 1.3),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your name, mobile number or city is still missing. Add them so devotees can reach you for puja requests. Tap to open your profile.',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFB45309)),
                tooltip: 'Dismiss',
                onPressed: () => setState(() => _profilePromptDismissed = true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AssignmentsProvider>();
    final profileP = context.watch<PanditProfileProvider>();
    final auth = context.watch<AuthProvider>();

    final upcoming = a.upcomingBookings;
    final current = a.currentRitual;

    final displayName =
        profileP.profile?.fullName ?? auth.session?.name ?? auth.session?.username ?? 'Pandit';

    // Web parity (PanditDashboardPage profile prompt): nudge incomplete
    // profiles — the three required fields are name, phone and city.
    final prof = profileP.profile;
    final showProfilePrompt =
        !_profilePromptDismissed && profileP.loaded && (prof == null || !prof.isComplete);

    return RefreshIndicator(
      color: AppColors.accent,
      // Full-page refresh: the home pane renders both assignments and the
      // profile (name, rating), so one pull reloads everything visible.
      onRefresh: () async {
        await Future.wait([
          a.load(showSpinner: true),
          context.read<PanditProfileProvider>().load(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (current != null) ...[
            ActiveRitualCard(
              booking: current,
              onViewLive: () => widget.onOpenLiveNav(current),
              onViewDetails: () => showSankalpaSheet(context, current),
            ),
            const SizedBox(height: 16),
          ],
          if (showProfilePrompt) _profileIncompleteBanner(),
          WelcomeBanner(displayName: displayName, onPayout: _requestPayout),
          const SizedBox(height: 14),
          DashboardStats(
            pendingCount: a.pendingCount,
            upcomingCount: upcoming.length,
            completedCount: a.completedCount,
            rating: profileP.averageRating,
            onPending: () => widget.onNavigate(AppTab.schedule),
            onUpcoming: () => widget.onNavigate(AppTab.schedule),
            onCompleted: () => widget.onNavigate(AppTab.completed),
            onBlessings: () => widget.onNavigate(AppTab.blessings),
          ),
          const SizedBox(height: 16),
          if (current != null) ...[
            // Dedicated current-ritual card (web pins this atop the Puja
            // Schedule tab as the "Current Ritual" / active ceremony view).
            SectionCard(
              title: 'Current Ritual',
              emoji: '🔥',
              subtitle: 'Active ceremony in progress right now.',
              subtitleColor: const Color(0xFF991B1B),
              badgeLabel: 'LIVE',
              badgeColor: AppColors.danger,
              borderColor: AppColors.danger,
              child: AcceptedBookingCard(
                booking: current,
                processing: a.processingId == '${current.bookingId}',
                action: a.processingAction,
                onAdvance: (stage) => _advance(current, stage),
                onEndPuja: () => _endPuja(current),
                onOpenLiveNav: () => widget.onOpenLiveNav(current),
                onViewSankalpa: () => showSankalpaSheet(context, current),
                onViewDetails: () => showSankalpaSheet(context, current),
              ),
            ),
            const SizedBox(height: 16),
          ],
          SectionCard(
            title: 'Pending Puja Requests',
            emoji: '🪔',
            badgeLabel: '${a.pendingCount} Action Req.',
            badgeColor: AppColors.accent,
            borderColor: AppColors.accent,
            trailing: SectionAction(
              label: 'Refresh',
              icon: Icons.refresh_rounded,
              busy: a.loading,
              onPressed: () => a.load(showSpinner: true),
            ),
            child: a.loading && a.bookings.isEmpty
                ? const LoadingView(label: 'Fetching assignments...')
                : a.pendingRequests.isEmpty
                    ? const EmptyState(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'No Pending Puja Requests',
                        subtitle:
                            'You are completely up to date! New ceremony assignments from devotees and super admin will appear here.',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFbeb),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFCD34D)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.notifications_active_rounded,
                                    size: 18, color: Color(0xFFB45309)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You have ${a.pendingCount} new customer assignment(s) waiting. '
                                    'Please Accept or Decline to update the system.',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF92400E),
                                        height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...a.pendingRequests.map((b) => PendingRequestCard(
                                booking: b,
                                processing: a.processingId == '${b.bookingId}',
                                action: a.processingAction,
                                onAccept: () => _accept(b),
                                onDecline: () => _decline(b),
                              )),
                        ],
                      ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Upcoming Accepted Schedule',
            emoji: '🕉️',
            badgeLabel: '${upcoming.length} Scheduled',
            badgeColor: AppColors.info,
            borderColor: AppColors.info,
            child: upcoming.isEmpty
                ? const EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'No Upcoming Ceremonies Scheduled',
                    subtitle:
                        'When you accept new puja requests, their full devotee details, venue coordinates, and ceremony progress will appear here.',
                  )
                : Column(
                    children: upcoming
                        .map(
                          (b) => AcceptedBookingCard(
                            booking: b,
                            processing: a.processingId == '${b.bookingId}',
                            action: a.processingAction,
                            onAdvance: (stage) => _advance(b, stage),
                            onEndPuja: () => _endPuja(b),
                            onOpenLiveNav: () => widget.onOpenLiveNav(b),
                            onViewSankalpa: () => showSankalpaSheet(context, b),
                            onViewDetails: () => showSankalpaSheet(context, b),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
