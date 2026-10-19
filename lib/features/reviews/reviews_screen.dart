import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../providers/pandit_profile_provider.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<PanditProfileProvider>();
      if (p.reviews.isEmpty) p.loadReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PanditProfileProvider>();
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const GradientAppBar(title: 'Devotee Blessings'),
      body: p.loadingReviews && p.reviews.isEmpty
          ? const LoadingView(label: 'Loading reviews...')
          : RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () => context.read<PanditProfileProvider>().loadReviews(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.averageRating == 0 ? '-' : p.averageRating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
                            ),
                            Row(
                              children: List.generate(5, (i) {
                                final filled = i < p.averageRating.round();
                                return Icon(
                                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 17,
                                  color: filled ? AppColors.gold : Colors.white38,
                                );
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Average Devotee Rating',
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                              SizedBox(height: 4),
                              Text(
                                'Ratings are shared only after a ceremony is completed by the devotee.',
                                style: TextStyle(color: Color(0xFF9DB4C0), fontSize: 11.5, height: 1.45),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (p.reviews.isEmpty)
                    const EmptyState(
                      icon: Icons.star_outline_rounded,
                      title: 'No reviews yet',
                      subtitle: 'Blessings shared by devotees after their ceremonies will appear here.',
                    )
                  else
                    SectionHeader(title: '${p.reviews.length} Reviews'),
                  ...p.reviews.map((r) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: AppColors.border),
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
                                const Spacer(),
                                // Web `PanditReviews.jsx` renders the calendar
                                // date (`formatDate`), not a relative label.
                                Text(Fmt.date(r.createdAt),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                            if (r.reviewTitle != null && r.reviewTitle!.isNotEmpty) ...[
                              const SizedBox(height: 9),
                              Text(r.reviewTitle!,
                                  style: const TextStyle(
                                      fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                            ],
                            if (r.reviewText != null && r.reviewText!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(r.reviewText!,
                                  style:
                                      const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.5)),
                            ],
                            const SizedBox(height: 9),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  (r.isAnonymous == true ? 'Anonymous Devotee' : (r.customerName ?? 'Devotee')) +
                                      (r.ceremony != null && r.ceremony!.isNotEmpty ? ' • ${r.ceremony}' : ''),
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}
