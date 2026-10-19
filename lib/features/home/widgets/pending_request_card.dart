import 'package:flutter/material.dart' hide Text;

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../models/booking.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// Accept / Decline card for an unassigned puja request.
class PendingRequestCard extends StatelessWidget {
  const PendingRequestCard({
    super.key,
    required this.booking,
    required this.processing,
    required this.action,
    required this.onAccept,
    required this.onDecline,
  });

  final Booking booking;
  final bool processing;
  final String? action;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final isAccepting = processing && action == 'accept';
    final isDeclining = processing && action == 'decline';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.warning.withValues(alpha: 0.10), blurRadius: 14)],
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
              const StatusBadge(label: 'New Request', color: AppColors.warning, dense: true),
              const Spacer(),
              Text(booking.priceDisplay,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 11),
          Text(booking.ceremony ?? 'Puja',
              style: const TextStyle(
                  fontSize: 15.5, fontWeight: FontWeight.w900, color: AppColors.textDark, height: 1.3)),
          const SizedBox(height: 9),
          _row(Icons.calendar_today_outlined, Fmt.date(booking.bookingDate)),
          _row(Icons.wb_twilight_outlined, booking.timeSlot ?? '-', maxLines: 2),
          _row(Icons.location_on_outlined,
              [booking.city, booking.state].where((s) => s != null && s.isNotEmpty).join(', ')),
          _row(Icons.person_outline, booking.fullName ?? '-'),
          if (booking.gothram != null && booking.gothram!.isNotEmpty)
            _row(Icons.ac_unit_outlined, 'Gothram: ${booking.gothram}'),
          if (booking.samagri != null && booking.samagri!.isNotEmpty)
            _row(Icons.inventory_2_outlined, booking.samagri!),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(10)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 15, color: AppColors.accent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contact info protected — accept the request to unlock devotee mobile, email and full venue address.',
                    style: TextStyle(fontSize: 10.5, color: AppColors.textDark, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: processing ? null : onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(color: isDeclining ? AppColors.danger : AppColors.danger.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: isDeclining
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger))
                      : const Icon(Icons.close_rounded, size: 17),
                  label: Text(isDeclining ? 'Declining...' : 'Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: processing ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: isAccepting
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 17),
                  label: Text(isAccepting ? 'Accepting...' : 'Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textDark, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
