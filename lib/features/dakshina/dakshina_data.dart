import '../../models/booking.dart';
import '../../models/pandit_profile.dart';

/// Total dakshina earned across every completed ceremony.
double dakshinaBalance(List<Booking> completed) =>
    completed.fold<double>(0, (sum, b) => sum + (b.price ?? 0));

/// Bank account masked as ••••••4819 for the settlement cards.
String maskedAccount(PanditProfile? profile) {
  final account = (profile?.bankAccount ?? '').trim();
  if (account.isEmpty) return '••••••4819';
  if (account.length <= 4) return account;
  return '••••••${account.substring(account.length - 4)}';
}

/// Human readable destination bank derived from the linked IFSC prefix.
String bankLabel(PanditProfile? profile) {
  final ifsc = (profile?.ifscCode ?? '').trim().toUpperCase();
  final hasAccount = (profile?.bankAccount ?? '').trim().isNotEmpty;
  if (!hasAccount && ifsc.isEmpty) return 'No bank account linked';
  final bank = ifsc.length >= 4 ? '${ifsc.substring(0, 4)} Bank' : 'Linked Bank';
  return '$bank ${maskedAccount(profile)}';
}

/// Linked UPI ID or a clear placeholder.
String upiLabel(PanditProfile? profile) {
  final upi = (profile?.upiId ?? '').trim();
  return upi.isEmpty ? 'Not linked yet' : upi;
}
