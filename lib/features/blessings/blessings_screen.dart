import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../providers/assignments_provider.dart';
import '../../providers/pandit_profile_provider.dart';
import '../app_tab.dart';
import '../home/widgets/dashboard_widgets.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// Devotee Blessings pane (image 8 of the UI pack): rating console, star
/// distribution and every blessing shared after a completed ceremony.
class BlessingsScreen extends StatefulWidget {
  const BlessingsScreen({super.key, required this.onNavigate});

  final void Function(AppTab tab) onNavigate;

  @override
  State<BlessingsScreen> createState() => _BlessingsScreenState();
}

class _BlessingsScreenState extends State<BlessingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always refresh so the blessing count matches the web dashboard
      // (web refetches /pandit/reviews on every mount).
      context.read<PanditProfileProvider>().loadReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PanditProfileProvider>();
    final a = context.watch<AssignmentsProvider>();
    final reviews = p.reviews;
    final avg = p.averageRating;
    final shown = avg;

    // counts[0] = 1★ … counts[4] = 5★. Unrated (null) blessings are excluded
    // so the distribution always reflects real data — never a placeholder.
    final counts = List<int>.filled(5, 0);
    for (final r in reviews) {
      final rating = r.rating;
      if (rating == null || rating < 1 || rating > 5) continue;
      counts[rating - 1] += 1;
    }
    final fiveStar = counts[4];
    final responded = reviews.length;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => context.read<PanditProfileProvider>().loadReviews(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          DashboardStats(
            pendingCount: a.pendingCount,
            upcomingCount: a.upcomingBookings.length,
            completedCount: a.completedCount,
            rating: shown,
            onPending: () => widget.onNavigate(AppTab.schedule),
            onUpcoming: () => widget.onNavigate(AppTab.schedule),
            onCompleted: () => widget.onNavigate(AppTab.completed),
            onBlessings: () => widget.onNavigate(AppTab.blessings),
          ),
          const SizedBox(height: 16),
          _ratingConsole(shown, reviews.length, fiveStar, responded, counts),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Devotee Blessings',
            emoji: '🙏',
            subtitle: 'Gratitude shared by Yajamanas after their ceremonies.',
            badgeLabel: '${reviews.length} Blessings',
            badgeColor: AppColors.gold,
            borderColor: AppColors.gold,
            child: p.loadingReviews && reviews.isEmpty
                ? const LoadingView(label: 'Loading blessings...')
                : reviews.isEmpty
                    ? const EmptyState(
                        icon: Icons.volunteer_activism_outlined,
                        title: 'No Blessings Received Yet',
                        subtitle:
                            'Complete ceremonies and your devotees will leave ratings, gratitude and blessings here for the Vedic community to see.',
                      )
                    : Column(
                        children: reviews.map(_reviewCard).toList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _ratingConsole(double avg, int total, int fiveStar, int responded, List<int> counts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, Color(0xFF06384E)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.75), width: 1.6),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 7)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(avg.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < avg.round();
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          filled ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 17,
                          color: filled ? AppColors.gold : Colors.white38,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Acharya Vedic Trust Score',
                        style: TextStyle(
                            color: Color(0xFFFCD34D), fontSize: 12.5, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _miniChip(Icons.verified_rounded, 'Profile Verified', AppColors.success),
                        _miniChip(Icons.rate_review_outlined, '$responded Reviews', AppColors.accent),
                        _miniChip(Icons.military_tech_outlined, '$fiveStar ★★★★★', const Color(0xFFC4B5FD)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFF1E4B5E)),
          const SizedBox(height: 12),
          _bars(counts),
        ],
      ),
    );
  }

  Widget _miniChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  /// Real star distribution: counts is indexed 1★…5★ and the rows are drawn
  /// 5★ down to 1★. Empty reviews render empty (zero) bars — never fake data.
  Widget _bars(List<int> counts) {
    final total = counts.fold<int>(0, (sum, c) => sum + c);
    final distribution = [for (var i = 0; i < 5; i++) total == 0 ? 0.0 : counts[4 - i] / total];

    return Column(
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text('${5 - i} ★',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white70)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: distribution[i],
                      minHeight: 8,
                      backgroundColor: const Color(0xFF143C4D),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          i == 0 ? AppColors.gold : AppColors.accent.withValues(alpha: 0.85)),
                    ),
                  ),
                ),
                SizedBox(
                  width: 42,
                  child: Text(
                    total == 0 ? '' : '${(distribution[i] * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _reviewCard(dynamic r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (i) {
                  final filled = i < (r.rating ?? 0);
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: filled ? AppColors.gold : AppColors.border,
                  );
                }),
              ),
              const SizedBox(width: 8),
              // Web `PanditReviews.jsx` (the Devotee Blessings tab) renders
              // the calendar date (`formatDate`), not a relative label.
              Text(Fmt.date(r.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const Spacer(),
              const Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFFFCD34D)),
            ],
          ),
          if (r.reviewTitle != null && r.reviewTitle!.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(r.reviewTitle!,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          ],
          if (r.reviewText != null && r.reviewText!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r.reviewText!, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.55)),
          ],
          const SizedBox(height: 11),
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  ((r.isAnonymous == true ? 'A' : (r.customerName ?? 'D'))).substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFC2410C)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (r.isAnonymous == true ? 'Anonymous Devotee' : (r.customerName ?? 'Devotee')) +
                      (r.ceremony != null && r.ceremony!.isNotEmpty ? ' • ${r.ceremony}' : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                ),
              ),
              const Icon(Icons.verified_user_outlined, size: 15, color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }
}
