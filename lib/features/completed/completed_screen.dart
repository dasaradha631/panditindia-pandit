import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/booking.dart';
import '../../providers/assignments_provider.dart';
import '../../providers/pandit_profile_provider.dart';
import '../app_tab.dart';
import '../home/widgets/dashboard_widgets.dart';
import '../home/widgets/sheets.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// Completed Poojas Archive & Vedic Records pane.
class CompletedScreen extends StatelessWidget {
  const CompletedScreen({super.key, required this.onNavigate});

  final void Function(AppTab tab) onNavigate;

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AssignmentsProvider>();
    final profileP = context.watch<PanditProfileProvider>();
    final completed = a.completedBookings;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => a.load(showSpinner: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          DashboardStats(
            pendingCount: a.pendingCount,
            upcomingCount: a.upcomingBookings.length,
            completedCount: a.completedCount,
            rating: profileP.averageRating,
            onPending: () => onNavigate(AppTab.schedule),
            onUpcoming: () => onNavigate(AppTab.schedule),
            onCompleted: () => onNavigate(AppTab.completed),
            onBlessings: () => onNavigate(AppTab.blessings),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Completed Poojas Archive & Vedic Records',
            emoji: '🌿',
            subtitle: 'Records of all sacred ceremonies performed by you.',
            subtitleColor: const Color(0xFF065F46),
            badgeLabel: '${completed.length} Total Completed',
            badgeColor: AppColors.success,
            borderColor: AppColors.success,
            child: completed.isEmpty
                ? const EmptyState(
                    icon: Icons.fact_check_outlined,
                    title: 'No Completed Poojas Yet',
                    subtitle:
                        "When you finish active ceremonies and click 'End Puja', they are securely archived here with their Dakshina records.",
                  )
                : Column(
                    children: completed.map((b) => _CompletedCard(booking: b)).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showSankalpaSheet(context, booking),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.35), width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(7)),
                    child: Text(booking.displayId,
                        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  const StatusBadge(label: 'Completed', color: AppColors.success, dense: true),
                  const Spacer(),
                  Text(booking.priceDisplay,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.success)),
                ],
              ),
              const SizedBox(height: 11),
              Text(booking.ceremony ?? 'Puja',
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.textDark, height: 1.3)),
              const SizedBox(height: 7),
              _line(Icons.person_outline,
                  [booking.fullName, if (booking.gothram?.isNotEmpty ?? false) booking.gothram]
                      .where((s) => s != null && s.isNotEmpty)
                      .join(' • ')),
              _line(Icons.calendar_today_outlined, Fmt.date(booking.bookingDate)),
              if (booking.city != null && booking.city!.isNotEmpty)
                _line(Icons.location_on_outlined, booking.city!),
              if (booking.samagri != null && booking.samagri!.isNotEmpty)
                _line(Icons.inventory_2_outlined, booking.samagri!),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => showSankalpaSheet(context, booking),
                  icon: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.info),
                  label: const Text('View Details',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.info,
                          letterSpacing: 0.4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 7),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
