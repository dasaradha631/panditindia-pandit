import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/booking.dart';
import '../../providers/assignments_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pandit_profile_provider.dart';
import '../app_tab.dart';
import '../home/widgets/dashboard_widgets.dart';
import '../home/widgets/sheets.dart';
import 'dakshina_data.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// Dakshina Ledger & Payouts pane (image 4 of the UI pack).
class DakshinaScreen extends StatefulWidget {
  const DakshinaScreen({super.key, required this.onNavigate});

  final void Function(AppTab tab) onNavigate;

  @override
  State<DakshinaScreen> createState() => _DakshinaScreenState();
}

class _DakshinaScreenState extends State<DakshinaScreen> {
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

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AssignmentsProvider>();
    final profile = context.watch<PanditProfileProvider>().profile;
    final completed = a.completedBookings;
    final total = dakshinaBalance(completed);
    final ledger = [...completed];

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => a.load(showSpinner: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'TOTAL EARNED',
                  value: Fmt.inr(total),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: 'AVAILABLE FOR PAYOUT',
                  value: Fmt.inr(total),
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _LinkedCard(
                  label: 'LINKED BANK ACCOUNT',
                  value: bankLabel(profile),
                  subtitle: (profile?.ifscCode ?? '').trim().isEmpty
                      ? 'Add IFSC in Payment Settings'
                      : 'IFSC: ${(profile?.ifscCode ?? '').trim().toUpperCase()}',
                  icon: Icons.account_balance_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LinkedCard(
                  label: 'LINKED UPI ID',
                  value: upiLabel(profile),
                  subtitle: (profile?.upiId ?? '').trim().isEmpty
                      ? 'Add UPI in Payment Settings'
                      : 'Auto-settlement active',
                  icon: Icons.qr_code_2_rounded,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: Material(
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _requestPayout,
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppColors.accent, Color(0xFFFBBF24), AppColors.accentHover]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 5)),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payments_outlined, size: 17, color: AppColors.primary),
                            SizedBox(width: 7),
                            Text('Request Payout',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => widget.onNavigate(AppTab.profile),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.55), width: 1.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.settings_outlined, size: 17, color: AppColors.accent),
                            SizedBox(width: 7),
                            Text('Payment Settings',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.accent)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Dakshina & Payouts Ledger',
            emoji: '💰',
            subtitle: 'Complete record of all ceremony earnings and settlements.',
            badgeLabel: '${ledger.length} Entries',
            badgeColor: AppColors.success,
            borderColor: AppColors.success,
            child: ledger.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Dakshina Entries Yet',
                    subtitle:
                        'Once you complete ceremonies, every dakshina credit, settlement and payout will be tracked here.',
                  )
                : Column(
                    children: [
                      for (var i = 0; i < ledger.length; i++) _LedgerRow(booking: ledger[i], pending: i == 0),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Dakshina credited after each completed ceremony is settled to your linked bank account within 24 working hours.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.9), height: 1.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(height: 9),
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 8.4, fontWeight: FontWeight.w900, letterSpacing: 0.6, color: color)),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        ],
      ),
    );
  }
}

/// Settlement destination card mirroring the web dashboard's
/// "Linked Bank Account" / "Linked UPI ID" panels.
class _LinkedCard extends StatelessWidget {
  const _LinkedCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 8.4, fontWeight: FontWeight.w900, letterSpacing: 0.6, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          const SizedBox(height: 3),
          Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted.withValues(alpha: 0.9))),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.booking, required this.pending});

  final Booking booking;
  final bool pending;

  /// Web ledger fallback when a booking predates the priced-kit columns:
  /// Premium → ₹1,200, Standard → ₹800, otherwise ₹0.
  String get _kitPrice {
    final explicit = booking.ecokitPrice;
    if (explicit != null) return Fmt.inr(explicit);
    final kit = booking.samagri ?? '';
    if (kit.contains('Premium')) return '₹1,200';
    if (kit.contains('Standard')) return '₹800';
    return '₹0';
  }

  @override
  Widget build(BuildContext context) {
    final status = pending ? 'Pending Clearance' : 'Settled';
    final statusColor = pending ? AppColors.info : AppColors.success;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showSankalpaSheet(context, booking),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.currency_rupee_rounded, size: 15, color: AppColors.gold),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(7)),
                          child: Text(booking.displayId,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(booking.ceremony ?? 'Puja',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${Fmt.date(booking.bookingDate)} • ${booking.fullName ?? 'Devotee'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                    // Web "Recent Ceremony Dakshina Ledger" columns — Samagri,
                    // Eco Kit (Items & Prices) and Eco Kit Price — the kit
                    // line-items and their cost live on this ledger, not on
                    // the ritual-prep tab.
                    if (booking.samagri != null && booking.samagri!.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🌿', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 4),
                            // Flexible: the chip sits in a narrow ledger
                            // column — an unbounded min-size Row overflowed
                            // by ~49px with long kit names.
                            Flexible(
                              child: Text(booking.samagri!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF92400E))),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (booking.ecokit != null && booking.ecokit!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text('📋 ${booking.ecokit}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                              height: 1.35)),
                    ] else if (booking.samagri != null && booking.samagri!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      const Text('Vedic Items Included',
                          style: TextStyle(
                              fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textMuted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(booking.priceDisplay,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.success)),
                  const SizedBox(height: 5),
                  StatusBadge(label: status, color: statusColor, dense: true),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: const Color(0xFF6EE7B7)),
                    ),
                    child: Text('Eco Kit $_kitPrice',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF047857))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
