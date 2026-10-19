import 'package:flutter/material.dart' hide Text;

import '../app_tab.dart';
import '../home/widgets/dashboard_widgets.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// Samagri & Ritual Prep pane — exact port of the web `tab-samagri-prep` tab
/// (`PanditDashboardPage.jsx`): a protocols header plus the Havan & Homam
/// mandate and Sankalpa recitation guideline cards.
class SamagriScreen extends StatelessWidget {
  const SamagriScreen({super.key, required this.onNavigate});

  final void Function(AppTab tab) onNavigate;

  static const _amberEdge = Color(0xFFFDE68A);
  static const _amberTitle = Color(0xFF451A03);
  static const _slateBody = Color(0xFF334155);
  static const _blueEdge = Color(0xFFBFDBFE);
  static const _blueTitle = Color(0xFF172554);

  static const _havanBullets = [
    'Verify 100% pure organic A2 Cow Ghee container before lighting the Agni Kund.',
    'Check 108 Sacred Herb Hawan mix and Navgraha Samidha wood sticks.',
    'Ensure Gangotri Gangajal sealed container is unbroken.',
    'Keep sacred brass/copper Kalash with coconut and mango leaves ready.',
  ];

  static const _sankalpaSteps = [
    "Devotee's Gotra and ancestral deity (Kula Devata).",
    'Birth Nakshatra of Yajamana (Head of family) and spouse.',
    'Sankalpa purpose (Griha Pravesh, Vastu Shanti, Ayushya, etc.).',
    'Current Vikram Samvat and Lunar Month (Masa & Paksha).',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        SectionCard(
          title: 'Vedic Samagri & Ritual Preparation Mandap Protocols',
          emoji: '🌿',
          subtitle: 'Mandap guidelines and sacred item verification checklist.',
          subtitleColor: const Color(0xFF1D4ED8),
          borderColor: const Color(0xFF3B82F6),
          child: TwoUp(
            first: _havanCard(),
            second: _sankalpaCard(),
            gap: 14,
          ),
        ),
      ],
    );
  }

  Widget _havanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBEB), Color(0xFFFFF7ED)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _amberEdge, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🔥', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Havan & Homam Mandate',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _amberTitle, height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final line in _havanBullets) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•',
                    style: TextStyle(fontSize: 13, height: 1.5, fontWeight: FontWeight.w900, color: _slateBody)),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    line,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700, color: _slateBody, height: 1.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6EE7B7)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, size: 16, color: Color(0xFF059669)),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'All PanditIndia Eco-Samagri kits are 100% pre-certified.',
                    style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF065F46), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sankalpaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _blueEdge, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📜', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sankalpa Mantra Recitation Guidelines',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _blueTitle, height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Before initiating any ceremony, verify:',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _slateBody),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _sankalpaSteps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: const TextStyle(fontSize: 12.5, height: 1.5, fontWeight: FontWeight.w900, color: _blueTitle),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _sankalpaSteps[i],
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700, color: _slateBody, height: 1.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
