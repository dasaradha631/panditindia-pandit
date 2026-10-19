import 'package:flutter/material.dart' hide Text;

import '../../../core/theme/app_theme.dart';
import '../../../models/booking.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// One step of the six stage sacred ceremony workflow.
class CeremonyStage {
  const CeremonyStage(this.id, this.label, this.icon, this.actionLabel, this.actionIcon);

  final String id;
  final String label;
  final IconData icon;
  final String? actionLabel;
  final IconData? actionIcon;

  static const List<CeremonyStage> all = [
    CeremonyStage('accepted', 'Accepted', Icons.check_circle_outline_rounded, null, null),
    CeremonyStage('en_route', 'Start Journey', Icons.directions_car_filled_outlined,
        'Start Journey (En Route)', Icons.directions_car_filled_outlined),
    CeremonyStage('arrived', 'Arrived', Icons.home_outlined, "Reached Location", Icons.home_outlined),
    CeremonyStage('in_progress', 'Live Puja', Icons.local_fire_department_outlined, 'Start Live Puja & Havan',
        Icons.local_fire_department_outlined),
    CeremonyStage('aarti', 'Final Ritual / Aarti', Icons.wb_sunny_outlined, 'Purna Ahuti & Maha Aarti',
        Icons.wb_sunny_outlined),
    CeremonyStage('completed', 'Puja Completed', Icons.done_all_rounded, 'End Puja & Complete',
        Icons.done_all_rounded),
  ];

  /// Maps a raw backend status onto its workflow step (0 - 5).
  static int indexOf(Booking booking) {
    final s = (booking.rawStatus ?? '').toLowerCase();
    if (s.contains('complete')) return 5;
    if (s.contains('aarti')) return 4;
    if (s.contains('progress') || s.contains('live')) return 3;
    if (s.contains('arrived')) return 2;
    if (s.contains('route') || s.contains('transit')) return 1;
    return 0;
  }

  static bool isLive(Booking booking) {
    final idx = indexOf(booking);
    return idx >= 1 && idx <= 4;
  }
}

/// Compact "Stage N of 6" chip.
class StageChip extends StatelessWidget {
  const StageChip({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final done = index >= CeremonyStage.all.length - 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: (done ? AppColors.success : AppColors.accent).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: (done ? AppColors.success : AppColors.accent).withValues(alpha: 0.5)),
      ),
      child: Text(
        done ? 'Stage 6 of 6 • Done' : 'Stage ${index + 1} of 6',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: done ? AppColors.successDark : AppColors.accentHover,
        ),
      ),
    );
  }
}

/// Horizontally scrollable six step workflow shared by Schedule and Live GPS.
class CeremonyStepStrip extends StatelessWidget {
  const CeremonyStepStrip({super.key, required this.currentIndex, this.height = 96});

  final int currentIndex;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: CeremonyStage.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final stage = CeremonyStage.all[i];
          final done = i < currentIndex;
          final active = i == currentIndex;
          final borderColor = done
              ? AppColors.success
              : active
                  ? AppColors.accent
                  : AppColors.border;
          final bg = active
              ? AppColors.accentLight
              : done
                  ? AppColors.success.withValues(alpha: 0.07)
                  : Colors.white;

          return Container(
            width: 96,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: borderColor, width: active || done ? 1.6 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? AppColors.success
                        : active
                            ? AppColors.accent
                            : Colors.white,
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Icon(done ? Icons.check_rounded : stage.icon,
                      size: 14, color: done || active ? Colors.white : AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Text(
                  stage.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.8,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: done || active ? AppColors.textDark : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  done ? 'DONE' : active ? '• ACTIVE' : 'STEP ${i + 1}',
                  style: TextStyle(
                    fontSize: 8.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: done
                        ? AppColors.success
                        : active
                            ? AppColors.accentHover
                            : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
