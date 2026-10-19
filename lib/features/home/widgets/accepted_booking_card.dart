import 'package:flutter/material.dart' hide Text;

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/contact_actions.dart';
import '../../../core/widgets/common.dart';
import '../../../models/booking.dart';
import 'ceremony_stages.dart';
import 'dashboard_widgets.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// Accepted booking with unlocked devotee details and the six step workflow.
class AcceptedBookingCard extends StatelessWidget {
  const AcceptedBookingCard({
    super.key,
    required this.booking,
    required this.processing,
    required this.action,
    required this.onAdvance,
    required this.onEndPuja,
    required this.onOpenLiveNav,
    required this.onViewSankalpa,
    required this.onViewDetails,
  });

  final Booking booking;
  final bool processing;
  final String? action;
  final ValueChanged<String> onAdvance;
  final VoidCallback onEndPuja;
  final VoidCallback onOpenLiveNav;
  final VoidCallback onViewSankalpa;

  /// Opens the same ceremony details sheet as "View Sankalpa" — the explicit
  /// "View Details" label mirrors the web `CompletedPujaCard` action.
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final stageIndex = CeremonyStage.indexOf(booking);
    final isLive = CeremonyStage.isLive(booking);
    final address = [booking.address ?? booking.addressLine1, booking.city, booking.state, booking.pincode]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLive ? AppColors.accent.withValues(alpha: 0.6) : AppColors.border,
          width: isLive ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLive ? AppColors.accent : AppColors.primary).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 7,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _Pill(
                label: 'Confirmed & Accepted',
                color: AppColors.success,
                icon: Icons.verified_user_outlined,
              ),
              if (isLive)
                const _Pill(label: 'LIVE NOW', color: AppColors.danger, icon: Icons.podcasts_outlined),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(booking.displayId,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFC2410C))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(booking.ceremony ?? 'Puja',
              style: const TextStyle(
                  fontSize: 18.5, fontWeight: FontWeight.w900, color: AppColors.textDark, height: 1.25)),
          const SizedBox(height: 11),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.priceDisplay,
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
                const SizedBox(height: 2),
                const Text('DAKSHINA GUARANTEED',
                    style: TextStyle(
                        fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 1, color: Color(0xFF166534))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TwoUp(
            first: _devoteeBox(context),
            second: _venueBox(address),
          ),
          const SizedBox(height: 12),
          _workflow(stageIndex),
          const SizedBox(height: 12),
          _footer(),
        ],
      ),
    );
  }

  Widget _devoteeBox(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  (booking.fullName ?? 'D').trim().isEmpty ? 'D' : (booking.fullName ?? 'D').trim()[0].toUpperCase(),
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFFC2410C)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DEVOTEE (YAJAMANA)',
                        style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.9, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(booking.fullName ?? 'Devotee',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text('Gotra: ${booking.gothram ?? 'Kashyapa'}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.accent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _contactButton(
                  label: 'Call Devotee',
                  icon: Icons.call_rounded,
                  color: const Color(0xFF059669),
                  filled: false,
                  onTap: () async {
                    final phone = (booking.mobile ?? '').trim();
                    if (phone.isEmpty) {
                      showAppToast(context, 'Devotee mobile number is not available yet.',
                          type: ToastType.warning, title: 'Call Devotee');
                      return;
                    }
                    final ok = await callDevotee(phone);
                    if (!ok && context.mounted) {
                      showAppToast(context, 'Unable to open the dialer. Try again.',
                          type: ToastType.error, title: 'Call Devotee');
                    }
                  },
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _contactButton(
                  label: 'WhatsApp',
                  icon: Icons.chat_rounded,
                  color: const Color(0xFF059669),
                  filled: true,
                  onTap: () async {
                    final phone = (booking.mobile ?? '').trim();
                    if (phone.isEmpty) {
                      showAppToast(context, 'Devotee mobile number is not available yet.',
                          type: ToastType.warning, title: 'WhatsApp');
                      return;
                    }
                    final ok = await whatsappDevotee(
                      phone,
                      'Namaste Ji, Acharya is assigned for your ${booking.ceremony ?? 'puja'}.',
                    );
                    if (!ok && context.mounted) {
                      showAppToast(context, 'Unable to open WhatsApp. Try again.',
                          type: ToastType.error, title: 'WhatsApp');
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _venueBox(String address) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CEREMONY VENUE',
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.9, color: AppColors.textMuted)),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFFE11D48)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(address.isEmpty ? 'Devotee Mandap Venue' : address,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.45)),
              ),
            ],
          ),
          if (booking.pincode != null && booking.pincode!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Pincode: ${booking.pincode}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 11),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text.rich(TextSpan(children: [
                  const TextSpan(
                      text: 'Muhurat: ',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  TextSpan(
                      text: Fmt.date(booking.bookingDate),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, color: AppColors.textDark, fontSize: 12.5)),
                ])),
              ),
              Flexible(
                child: Text(booking.timeSlot ?? '-',
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _workflow(int stageIndex) {
    final stageBusy = processing && action == 'stage';
    final endBusy = processing && action == 'end';
    final complete = stageIndex >= CeremonyStage.all.length - 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CEREMONY WORKFLOW PROGRESS',
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: AppColors.textDark)),
          const SizedBox(height: 6),
          StageChip(index: stageIndex),
          if (!complete) ...[
            const SizedBox(height: 10),
            _primaryAction(stageIndex, stageBusy, endBusy),
          ],
          const SizedBox(height: 13),
          CeremonyStepStrip(currentIndex: stageIndex),
          if (complete) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.45)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Text('Ceremony Completed',
                      style: TextStyle(
                          color: AppColors.successDark, fontWeight: FontWeight.w900, fontSize: 13.5)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _primaryAction(int stageIndex, bool stageBusy, bool endBusy) {
    if (stageIndex >= CeremonyStage.all.length - 1) return const SizedBox.shrink();
    final next = CeremonyStage.all[stageIndex + 1];
    if (stageIndex <= 2) {
      return _button(
        label: next.actionLabel ?? 'Continue',
        icon: next.actionIcon ?? Icons.arrow_forward_rounded,
        loading: stageBusy,
        onPressed: () => onAdvance(next.id),
      );
    }
    if (stageIndex == 3) {
      return Row(
        children: [
          Flexible(
            child: _button(
              label: next.actionLabel ?? 'Purna Ahuti & Maha Aarti',
              icon: next.actionIcon ?? Icons.wb_sunny_outlined,
              loading: stageBusy,
              onPressed: () => onAdvance(next.id),
            ),
          ),
          const SizedBox(width: 8),
          _button(
            label: 'End Puja',
            icon: Icons.stop_circle_outlined,
            loading: endBusy,
            color: AppColors.danger,
            onPressed: onEndPuja,
          ),
        ],
      );
    }
    if (stageIndex == 4) {
      return _button(
        label: next.actionLabel ?? 'End Puja & Complete',
        icon: next.actionIcon ?? Icons.done_all_rounded,
        loading: endBusy,
        color: AppColors.success,
        onPressed: onEndPuja,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _button({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool loading = false,
    Color color = AppColors.accent,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 9, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                    width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              else
                Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 15, color: Color(0xFFFF8C00)),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  booking.samagri ?? 'Premium Sealed Samagri Kit (6 Items)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _footerButton(
                label: 'Live GPS Radar',
                icon: Icons.podcasts_outlined,
                color: AppColors.accent,
                filled: true,
                onTap: onOpenLiveNav,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _footerButton(
                label: 'View Details',
                icon: Icons.info_outline_rounded,
                color: AppColors.info,
                filled: false,
                onTap: onViewDetails,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _footerButton(
                label: 'View Sankalpa',
                icon: Icons.menu_book_outlined,
                color: AppColors.info,
                filled: false,
                onTap: onViewSankalpa,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _footerButton(
                label: 'Pooja Ended',
                icon: Icons.stop_circle_outlined,
                color: AppColors.danger,
                filled: false,
                onTap: onEndPuja,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _footerButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: filled ? color : color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: filled ? 0 : 0.55)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: filled ? Colors.white : color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: filled ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: filled ? color : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: filled ? color : AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: filled ? Colors.white : color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: filled ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}
