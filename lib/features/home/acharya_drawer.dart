import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/language_selector.dart';
import '../../providers/assignments_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/pandit_profile_provider.dart';
import '../app_tab.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// Left top main menu (image 13 of the UI pack) shown over every pane.
class AcharyaDrawer extends StatelessWidget {
  const AcharyaDrawer({
    super.key,
    required this.current,
    required this.onSelect,
    required this.onSupport,
    required this.onSignOut,
    this.onNavigate,
  });

  final AppTab current;
  final ValueChanged<AppTab> onSelect;
  final VoidCallback onSupport;
  final VoidCallback onSignOut;

  /// Shell pane switch handed to the pushed notifications screen so a tapped
  /// alert can jump to the screen that owns it (web
  /// `PanditDashboardPage.handleSelectNotification`).
  final void Function(AppTab tab)? onNavigate;

  /// (tab, icon, titleKey, subtitleKey) - resolved through [AppL10n] at build.
static const items = <(AppTab, IconData, String, String)>[
    (AppTab.schedule, Icons.event_available_outlined, 'acharya.schedule',
        'acharya.scheduleSub'),
    (AppTab.completed, Icons.fact_check_outlined, 'acharya.completed', 'acharya.completedSub'),
    (AppTab.earnings, Icons.account_balance_wallet_outlined, 'acharya.dakshina', 'acharya.dakshinaSub'),
    (AppTab.samagri, Icons.inventory_2_outlined, 'acharya.samagri', 'acharya.samagriSub'),
    (AppTab.live, Icons.podcasts_outlined, 'acharya.liveGps', 'acharya.liveGpsSub'),
    (AppTab.blessings, Icons.volunteer_activism_outlined, 'acharya.blessings', 'acharya.blessingsSub'),
    (AppTab.profile, Icons.badge_outlined, 'acharya.profile', 'acharya.profileSub'),
  ];

  @override
  Widget build(BuildContext context) {
    final profileP = context.watch<PanditProfileProvider>();
    final auth = context.watch<AuthProvider>();
    final notifs = context.watch<NotificationsProvider>();
    final assignments = context.watch<AssignmentsProvider>();
    final prof = profileP.profile;
    final currentRitual = assignments.currentRitual;

    return Drawer(
      backgroundColor: AppColors.cream,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        backgroundImage: (prof?.profilePhotoUrl?.isNotEmpty ?? false)
                            ? NetworkImage(prof!.profilePhotoUrl!)
                            : null,
                        child: (prof?.profilePhotoUrl?.isNotEmpty ?? false)
                            ? null
                            : const Text('🕉', style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prof?.fullName ?? auth.session?.name ?? 'Acharya',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Acharya Portal • ${prof?.city ?? 'PanditIndia'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: (prof?.isVerified == true ? AppColors.success : AppColors.warning)
                              .withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.7)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_rounded,
                                size: 12,
                                color: prof?.isVerified == true ? AppColors.success : AppColors.warning),
                            const SizedBox(width: 5),
                            Text(
                              prof?.isVerified == true ? context.tr('acharya.verified') : context.tr('acharya.underVerification'),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: prof?.isVerified == true
                                      ? AppColors.success
                                      : AppColors.warning),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('ॐ तत्सत्',
                          style: TextStyle(color: Color(0xFFFCD34D), fontSize: 12, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  if (currentRitual != null)
                    _tile(context, AppTab.schedule, Icons.local_fire_department_outlined,
                        context.tr('acharya.currentRitual'), context.tr('acharya.currentRitualSub')),
                  for (final (tab, icon, titleKey, subtitleKey) in items)
                    _tile(context, tab, icon, context.tr(titleKey), context.tr(subtitleKey)),
                  const SizedBox(height: 6),
                  const Divider(height: 1),
                  const SizedBox(height: 6),
                  _plainTile(
                    icon: Icons.translate_rounded,
                    color: AppColors.accent,
                    title: context.tr('common.changeLanguage'),
                    subtitle: context.tr('language.applied'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  _plainTile(
                    icon: Icons.support_agent_rounded,
                    color: AppColors.success,
                    title: context.tr('support.helpSupport'),
                    subtitle: context.tr('support.raiseTicketVedic'),
                    onTap: onSupport,
                  ),
                  if (notifs.unreadCount > 0)
                    _plainTile(
                      icon: Icons.notifications_none_rounded,
                      color: AppColors.info,
                      title: context.tr('nav.notifications'),
                      subtitle: context.tr('acharya.unreadAlerts', {'count': notifs.unreadCount}),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => NotificationsScreen(onNavigate: onNavigate)),
                        );
                      },
                    ),
                  const SizedBox(height: 6),
                  _plainTile(
                    icon: Icons.logout_rounded,
                    color: AppColors.danger,
                    title: context.tr('nav.logoutAcharya'),
                    danger: true,
                    onTap: onSignOut,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text('PanditIndia Acharya • v1.0.0',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, AppTab tab, IconData icon, String title, String subtitle) {
    final selected = current == tab;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.accent.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: selected ? AppColors.accent.withValues(alpha: 0.55) : Colors.transparent),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (selected ? AppColors.accent : AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: selected ? AppColors.accent : AppColors.primary),
          ),
          title: Text(title,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: selected ? AppColors.accentHover : AppColors.textDark)),
          subtitle: Text(subtitle,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, height: 1.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          trailing: selected
              ? const Icon(Icons.radio_button_checked_rounded, size: 17, color: AppColors.accent)
              : const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCBD5E1)),
          onTap: () => onSelect(tab),
        ),
      ),
    );
  }

  Widget _plainTile({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    bool danger = false,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(title,
          style: TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w900, color: danger ? AppColors.danger : AppColors.textDark)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}

/// Sign out confirmation shared by the drawer and profile pane.
Future<bool> confirmSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('${context.tr('nav.logoutAcharya')}?'),
      content: Text(context.tr('acharya.logoutMessage')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('common.cancel'))),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(context.tr('auth.signOut'), style: const TextStyle(color: AppColors.danger)),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Signs the Acharya out and returns to the login screen.
/// Returns true only when the session was actually terminated.
Future<bool> performSignOut(BuildContext context) async {
  if (!await confirmSignOut(context)) return false;
  if (!context.mounted) return false;
  await context.read<AuthProvider>().logout();
  if (!context.mounted) return true;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
  return true;
}
