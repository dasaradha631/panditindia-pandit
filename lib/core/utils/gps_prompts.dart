import 'package:flutter/material.dart' hide Text;

import '../../services/tracking_service.dart';
import '../theme/app_theme.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// Asks the Acharya to unblock GPS in the exact system settings page that can
/// fix [access]. Returns true when settings were opened so the caller can
/// retry the detection once the user comes back.
Future<bool> promptGpsUnblock(
  BuildContext context,
  PanditTrackingService tracking,
  GpsAccess access,
) async {
  final serviceOff = access == GpsAccess.serviceDisabled;
  final title = serviceOff ? 'Location Services Disabled' : 'Location Permission Blocked';
  final message = serviceOff
      ? 'Device location (GPS) is switched off. Turn it on so we can detect your exact position and stream live tracking to the devotee.'
      : 'Location permission is denied for PanditIndia Acharya. Allow it in app settings to detect your current GPS position.';
  final actionLabel = serviceOff ? 'Open Location Settings' : 'Open App Settings';

  final opened = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark)),
      content: Text(
        message,
        style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.textMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            actionLabel,
            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
  if (opened != true) return false;
  await tracking.openSettings(access);
  return true;
}
