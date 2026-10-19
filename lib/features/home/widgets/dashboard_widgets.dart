import 'package:flutter/material.dart' hide Text;

import '../../../core/theme/app_theme.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// Two children side by side on wide panes, stacked on phone widths.
class TwoUp extends StatelessWidget {
  const TwoUp({
    super.key,
    required this.first,
    required this.second,
    this.gap = 12,
    this.breakpoint = 640,
  });

  final Widget first;
  final Widget second;
  final double gap;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              SizedBox(width: gap),
              Expanded(child: second),
            ],
          );
        }
        return Column(
          children: [first, SizedBox(height: gap), second],
        );
      },
    );
  }
}

/// Card shell used by every dashboard pane: emoji + title + badge + action.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.emoji,
    this.icon,
    this.iconColor = AppColors.accent,
    this.subtitle,
    this.subtitleColor,
    this.badgeLabel,
    this.badgeColor = AppColors.accent,
    this.trailing,
    this.borderColor = AppColors.accent,
    this.headerDivider = true,
  });

  final String title;
  final Widget child;
  final String? emoji;
  final IconData? icon;
  final Color iconColor;
  final String? subtitle;
  final Color? subtitleColor;
  final String? badgeLabel;
  final Color badgeColor;
  final Widget? trailing;
  final Color borderColor;
  final bool headerDivider;

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (emoji != null) Text(emoji!, style: const TextStyle(fontSize: 16)),
            if (icon != null) Icon(icon, size: 17, color: iconColor),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
                height: 1.25,
              ),
            ),
            if (badgeLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [badgeColor, badgeColor.withValues(alpha: 0.78)]),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeLabel!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: subtitleColor ?? AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor.withValues(alpha: 0.55), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (trailing == null)
            heading
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: heading),
                const SizedBox(width: 10),
                trailing!,
              ],
            ),
          if (headerDivider) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: borderColor.withValues(alpha: 0.30)),
            const SizedBox(height: 14),
          ] else
            const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Pill button used for section level actions such as Refresh / Payout.
class SectionAction extends StatelessWidget {
  const SectionAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.accent,
    this.filled = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color color;
  final bool filled;

  /// While true the icon swaps for a spinner and taps are ignored, so an
  /// action like Refresh visibly responds instead of looking dead.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    return Material(
      color: filled ? color : color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: busy ? null : onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: filled ? 0 : 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              else if (icon != null)
                Icon(icon, size: 14, color: fg),
              if (icon != null || busy) const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The four jewel tone KPI cards shown on Schedule, Completed and Blessings.
class DashboardStats extends StatelessWidget {
  const DashboardStats({
    super.key,
    required this.pendingCount,
    required this.upcomingCount,
    required this.completedCount,
    required this.rating,
    required this.onPending,
    required this.onUpcoming,
    required this.onCompleted,
    required this.onBlessings,
  });

  final int pendingCount;
  final int upcomingCount;
  final int completedCount;
  final double rating;
  final VoidCallback onPending;
  final VoidCallback onUpcoming;
  final VoidCallback onCompleted;
  final VoidCallback onBlessings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Pending Requests',
                value: '$pendingCount Action Req.',
                icon: Icons.notifications_rounded,
                border: const Color(0xFFFBBF24),
                start: const Color(0xFFFF8C00),
                end: const Color(0xFFFBBF24),
                labelColor: const Color(0xFF92400E),
                darkIcon: true,
                pulse: pendingCount > 0,
                onTap: onPending,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Upcoming Schedule',
                value: '$upcomingCount Scheduled',
                icon: Icons.calendar_month_rounded,
                border: const Color(0xFF93C5FD),
                start: const Color(0xFF22D3EE),
                end: const Color(0xFF2563EB),
                labelColor: const Color(0xFF1E3A8A),
                onTap: onUpcoming,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Completed Pujas',
                value: '$completedCount Finished',
                icon: Icons.done_all_rounded,
                border: const Color(0xFF6EE7B7),
                start: const Color(0xFF10B981),
                end: const Color(0xFF0D9488),
                labelColor: const Color(0xFF065F46),
                onTap: onCompleted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Devotee Blessings',
                // Two decimals to match the web dashboard exactly — 4.98 was
                // rounding to "5" when displayed with a single decimal.
                value: rating > 0 ? rating.toStringAsFixed(2) : '-',
                icon: Icons.star_rounded,
                border: const Color(0xFFC4B5FD),
                start: const Color(0xFF8B5CF6),
                end: const Color(0xFF4F46E5),
                labelColor: const Color(0xFF581C87),
                valueSuffix: rating > 0 ? '★★★★★' : null,
                badge: rating > 0 ? 'Verified' : null,
                onTap: onBlessings,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.border,
    required this.start,
    required this.end,
    required this.labelColor,
    required this.onTap,
    this.valueSuffix,
    this.badge,
    this.darkIcon = false,
    this.pulse = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color border;
  final Color start;
  final Color end;
  final Color labelColor;
  final VoidCallback onTap;
  final String? valueSuffix;
  final String? badge;
  final bool darkIcon;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border, width: 1.8),
            boxShadow: [
              BoxShadow(color: border.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [start, end]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: start.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Icon(icon, size: 21, color: darkIcon ? AppColors.primary : Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              height: 1.15,
                            ),
                          ),
                        ),
                        if (valueSuffix != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            valueSuffix!,
                            style: const TextStyle(fontSize: 9, color: Color(0xFFF59E0B), letterSpacing: -1),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                )
              else if (pulse)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                )
              else
                const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark welcome console with the greeting and the payout action.
class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({super.key, required this.displayName, required this.onPayout});

  final String displayName;
  final VoidCallback onPayout;

  @override
  Widget build(BuildContext context) {
    final clean = displayName.trim();
    final first = clean.isEmpty || clean == 'Acharya' ? 'Pandit' : clean.split(' ').first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.85), width: 1.8),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFFFBBF24)]),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🪔', style: TextStyle(fontSize: 10)),
                    SizedBox(width: 5),
                    Text(
                      'VEDIC PRIEST OPERATIONS CONSOLE',
                      style: TextStyle(
                        fontSize: 8.6,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'ॐ तत्सत्',
                style: TextStyle(color: Color(0xFFFCD34D), fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Namaste, $first Ji 🙏',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2),
          ),
          const SizedBox(height: 7),
          Text(
            'Manage your sacred ritual assignments, devotees Sankalpas, and daily ceremony schedule with Gurukul Vedic protocols.',
            style: TextStyle(
              color: const Color(0xFFFFE8CC).withValues(alpha: 0.85),
              fontSize: 12.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: Material(
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onPayout,
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.accent, Color(0xFFFBBF24), AppColors.accentHover]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppColors.accent.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Request Dakshina Payout',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
