import 'package:flutter/material.dart' hide Text;

import '../../../core/theme/app_theme.dart';
import '../../../models/booking.dart';
import 'ceremony_stages.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// Prominent "Active Ritual" hero pinned to the top of the Puja Schedule pane
/// while a ceremony is running (web `LiveCeremonyCard` at the top of the
/// dashboard) — ceremony, devotee, workflow stage and muhurat at a glance with
/// a single CTA into Live GPS plus a details sheet.
class ActiveRitualCard extends StatelessWidget {
  const ActiveRitualCard({
    super.key,
    required this.booking,
    required this.onViewLive,
    required this.onViewDetails,
  });

  final Booking booking;
  final VoidCallback onViewLive;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final stageIndex = CeremonyStage.indexOf(booking);
    final stage = CeremonyStage.all[stageIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF7C2D12)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.8), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _LiveDot(),
              const SizedBox(width: 7),
              const Text('ACTIVE RITUAL',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(booking.displayId,
                    style: const TextStyle(
                        color: Color(0xFFFDE68A), fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(booking.ceremony ?? 'Puja',
              style: const TextStyle(
                  color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900, height: 1.2)),
          const SizedBox(height: 5),
          Text('Yajamana: ${booking.fullName ?? 'Devotee'}',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 11),
          Row(
            children: [
              _metaChip(icon: stage.icon, label: stage.label),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [Fmt.date(booking.bookingDate), booking.timeSlot]
                      .where((s) => s != null && s.isNotEmpty)
                      .join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onViewLive,
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.podcasts_outlined, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Open Live GPS',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Material(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onViewDetails,
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_outlined, size: 16, color: Color(0xFFFDE68A)),
                          SizedBox(width: 6),
                          Text('View Details',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFDE68A))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFFDE68A)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }
}

/// Small pulsing dot used as the "live" beacon on the Active Ritual card.
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 9,
        height: 9,
        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
      ),
    );
  }
}
