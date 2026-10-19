import 'package:flutter/material.dart' hide Text;

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/contact_actions.dart';
import '../../../core/widgets/common.dart';
import '../../../models/booking.dart';
import 'dashboard_widgets.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// Full ceremony + devotee Sankalpa details sheet (View Sankalpa action).
Future<void> showSankalpaSheet(BuildContext context, Booking booking) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.description_outlined, size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Ceremony & Sankalpa Details',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.ceremony ?? 'Puja',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(booking.displayId,
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.accent)),
                    ],
                  ),
                ),
                StatusBadge(label: 'Dakshina: ${booking.priceDisplay}', color: AppColors.success),
              ],
            ),
            const SizedBox(height: 14),
            TwoUp(
              first: _infoBox('DEVOTEE / YAJAMANA', [
                Text(booking.fullName ?? 'Devotee',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Mobile: ${booking.mobile ?? '—'}', style: const TextStyle(fontSize: 12.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
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
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF059669),
                          side: const BorderSide(color: Color(0xFF059669)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.call_rounded, size: 15),
                        label: const Text('Call', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final phone = (booking.mobile ?? '').trim();
                          if (phone.isEmpty) {
                            showAppToast(context, 'Devotee mobile number is not available yet.',
                                type: ToastType.warning, title: 'WhatsApp');
                            return;
                          }
                          final ok = await whatsappDevotee(
                              phone, 'Namaste Ji, Acharya is on the way for your ${booking.ceremony ?? 'puja'}.');
                          if (!ok && context.mounted) {
                            showAppToast(context, 'Unable to open WhatsApp. Try again.',
                                type: ToastType.error, title: 'WhatsApp');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF059669),
                          side: const BorderSide(color: Color(0xFF059669)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.chat_rounded, size: 15),
                        label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text.rich(TextSpan(children: [
                  const TextSpan(text: 'Gotra: '),
                  TextSpan(
                      text: booking.gothram ?? 'Kashyapa',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ]), style: const TextStyle(fontSize: 12.5)),
              ]),
              second: _infoBox('DATE & MUHURAT', [
                Text(Fmt.date(booking.bookingDate),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(booking.timeSlot ?? '-', style: const TextStyle(fontSize: 12.5)),
                const SizedBox(height: 4),
                Text.rich(TextSpan(children: [
                  const TextSpan(text: 'Samagri Kit: '),
                  TextSpan(
                      text: booking.samagri ?? 'Premium Sealed Samagri Kit',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ]), style: const TextStyle(fontSize: 12.5)),
              ]),
            ),
            const SizedBox(height: 12),
            _infoBox('PUJA VENUE ADDRESS', [
              Text(
                [booking.address ?? booking.addressLine1, booking.city, booking.pincode]
                    .where((s) => s != null && s.isNotEmpty)
                    .join(', '),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.45),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => openMaps([
                  booking.address ?? booking.addressLine1,
                  booking.city,
                  booking.pincode,
                ].where((s) => s != null && s.isNotEmpty).join(', ')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.info,
                  side: BorderSide(color: AppColors.info.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.map_outlined, size: 17),
                label: const Text('Open Google Maps Navigation',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SANKALPA NOTES & INTENTIONS',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: AppColors.accent)),
                  const SizedBox(height: 7),
                  Text(
                    'Devotee Sankalpa: ${booking.fullName ?? 'Devotee'} (${booking.gothram ?? 'Kashyapa'} Gotra) '
                    'for ${booking.ceremony ?? 'Puja'} at ${booking.city ?? 'the venue city'}. '
                    'Special prayer for peace, auspicious blessings, and spiritual prosperity.'
                    '${booking.specialRequests != null && booking.specialRequests!.isNotEmpty ? ' Note: ${booking.specialRequests}' : ''}',
                    style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, height: 1.55),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppButton(label: 'Close', variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    ),
  );
}

Widget _infoBox(String label, List<Widget> children) {
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
        Text(label,
            style: const TextStyle(
                fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: AppColors.textMuted)),
        const SizedBox(height: 7),
        ...children,
      ],
    ),
  );
}

/// Instant bank settlement sheet used by both payout buttons.
Future<void> showPayoutSheet(
  BuildContext context, {
  required String amount,
  required String holder,
  required String bankLabel,
  required String upiId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _PayoutSheet(amount: amount, holder: holder, bankLabel: bankLabel, upiId: upiId),
    ),
  );
}

class _PayoutSheet extends StatefulWidget {
  const _PayoutSheet({
    required this.amount,
    required this.holder,
    required this.bankLabel,
    required this.upiId,
  });

  final String amount;
  final String holder;
  final String bankLabel;
  final String upiId;

  @override
  State<_PayoutSheet> createState() => _PayoutSheetState();
}

class _PayoutSheetState extends State<_PayoutSheet> {
  bool _loading = false;
  bool _done = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _done = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.pop(context);
    showAppToast(
      context,
      '${widget.amount} payout initiated via IMPS to ${widget.bankLabel}.',
      type: ToastType.success,
      title: 'Payout Initiated',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999)),
            ),
          ),
          Row(
            children: [
              const Expanded(
                child: Text('Instant Dakshina Bank Payout',
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: AppColors.success)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
              ),
            ],
          ),
          const Divider(height: 20),
          Center(
            child: Text(widget.amount,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.success)),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text('Available for Instant IMPS / UPI Direct Bank Transfer',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _line('Account Holder', widget.holder),
                _line('Destination Bank', widget.bankLabel),
                _line('Transfer Mode', 'Instant IMPS (Zero Fee)', valueColor: AppColors.success),
                if (widget.upiId.isNotEmpty) _line('UPI ID', widget.upiId),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: _loading
                ? 'Processing Bank IMPS...'
                : _done
                    ? '✓ Payout Initiated'
                    : 'Confirm & Transfer to Bank',
            loading: _loading,
            onPressed: _done ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: valueColor ?? AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation dialog shown before a sacred ceremony is marked complete.
Future<bool> confirmEndPuja(BuildContext context, Booking booking) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.help_outline_rounded, color: AppColors.accent),
          SizedBox(width: 8),
          Text('End Sacred Puja?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure the ceremony "${booking.ceremony ?? 'Puja'}" has completed?'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upon confirmation:',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: AppColors.successDark)),
                SizedBox(height: 6),
                Text('• Booking moves to the Completed Poojas archive',
                    style: TextStyle(fontSize: 12, height: 1.5)),
                Text('• Live GPS tracking terminates immediately', style: TextStyle(fontSize: 12, height: 1.5)),
                Text('• Your status returns to Available for new requests',
                    style: TextStyle(fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Yes, End Puja', style: TextStyle(color: AppColors.success)),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
