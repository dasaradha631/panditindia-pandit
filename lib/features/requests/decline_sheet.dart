import 'package:flutter/material.dart' hide Text;

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/booking.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

class DeclineResult {
  DeclineResult({required this.reason, required this.notes});

  final String reason;
  final String notes;
}

class DeclineSheet extends StatefulWidget {
  const DeclineSheet({super.key, required this.booking});

  final Booking booking;

  @override
  State<DeclineSheet> createState() => _DeclineSheetState();
}

class _DeclineSheetState extends State<DeclineSheet> {
  static const _reasons = [
    'Schedule Conflict / Prior Booking',
    'Personal Emergency / Urgent Work',
    'On Anusthana / Fasting / Tapasya',
    'Location too far from current city',
    'Health / Medical Rest',
    'Other',
  ];

  String reason = _reasons.first;
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Decline this request',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text(
                '${widget.booking.displayId} • ${widget.booking.ceremony ?? 'Puja'} will be reassigned to another Acharya.',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              const Text('REASON',
                  style: TextStyle(
                      fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              ..._reasons.map((r) {
                final selected = r == reason;
                return GestureDetector(
                  onTap: () => setState(() => reason = r),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accentLight : AppColors.cream,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: selected ? AppColors.accent : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 18,
                          color: selected ? AppColors.accent : AppColors.border,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(r,
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              AppTextField(label: 'Additional Notes (optional)', controller: _notes, maxLines: 3),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Keep Request'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Decline Request',
                      variant: AppButtonVariant.danger,
                      onPressed: () => Navigator.of(context).pop(
                        DeclineResult(reason: reason, notes: _notes.text.trim()),
                      ),
                    ),
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
