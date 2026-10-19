import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../providers/auth_provider.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  int step = 1;
  bool loading = false;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showAppToast(context, 'Please enter a valid registered email.', type: ToastType.warning, title: 'Forgot Password');
      return;
    }
    setState(() => loading = true);
    final res = await context.read<AuthProvider>().forgotPassword(email);
    if (!mounted) return;
    setState(() => loading = false);
    if (!res.success) {
      showAppToast(context, res.message ?? 'Failed to send OTP. Please verify your email.',
          type: ToastType.error, title: 'Forgot Password');
      return;
    }
    setState(() => step = 2);
    showAppToast(context, res.message ?? 'OTP sent to your registered email.', type: ToastType.success, title: 'OTP Sent');
  }

  Future<void> _verifyOtp() async {
    final otp = _otp.text.trim();
    if (otp.length < 4) {
      showAppToast(context, 'Please enter the OTP you received.', type: ToastType.warning, title: 'Verify OTP');
      return;
    }
    setState(() => loading = true);
    final res = await context.read<AuthProvider>().verifyOtp(email: _email.text.trim(), otp: otp);
    if (!mounted) return;
    setState(() => loading = false);
    if (!res.success) {
      showAppToast(context, res.message ?? 'Invalid or expired OTP.', type: ToastType.error, title: 'Verify OTP');
      return;
    }
    setState(() => step = 3);
    showAppToast(context, res.message ?? 'OTP verified successfully.', type: ToastType.success, title: 'Verified');
  }

  Future<void> _resetPassword() async {
    if (_password.text.length < 6) {
      showAppToast(context, 'Password must be at least 6 characters.', type: ToastType.warning, title: 'Reset');
      return;
    }
    if (_password.text != _confirm.text) {
      showAppToast(context, 'Passwords do not match.', type: ToastType.warning, title: 'Reset');
      return;
    }
    setState(() => loading = true);
    final res = await context
        .read<AuthProvider>()
        .changePassword(email: _email.text.trim(), newPassword: _password.text);
    if (!mounted) return;
    setState(() => loading = false);
    if (!res.success) {
      showAppToast(context, res.message ?? 'Failed to update password.', type: ToastType.error, title: 'Reset');
      return;
    }
    showAppToast(context, 'Password updated successfully. Please sign in with your new password.',
        type: ToastType.success, title: 'Done');
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const GradientAppBar(title: 'Reset Password'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepIndicator(current: step),
            const SizedBox(height: 26),
            if (step == 1) _stepEmail(),
            if (step == 2) _stepOtp(),
            if (step == 3) _stepPassword(),
          ],
        ),
      ),
    );
  }

  Widget _stepEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Forgot your password?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        const SizedBox(height: 6),
        const Text(
          'Enter your registered email address and we will send you a one-time password (OTP).',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
        ),
        const SizedBox(height: 22),
        AppTextField(
          label: 'Registered Email',
          controller: _email,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          prefix: const Icon(Icons.email_outlined, size: 20, color: AppColors.textMuted),
        ),
        const SizedBox(height: 22),
        AppButton(label: 'Send OTP', onPressed: _sendOtp, loading: loading),
      ],
    );
  }

  Widget _stepOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Enter OTP',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text(
          'We sent a 6-digit code to ${_email.text.trim()}. It is valid for 10 minutes.',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
        ),
        const SizedBox(height: 22),
        AppTextField(
          label: 'One-Time Password',
          controller: _otp,
          hint: '123456',
          keyboardType: TextInputType.number,
          prefix: const Icon(Icons.shield_outlined, size: 20, color: AppColors.textMuted),
        ),
        const SizedBox(height: 22),
        AppButton(label: 'Verify OTP', onPressed: _verifyOtp, loading: loading),
        const SizedBox(height: 10),
        TextButton(
          onPressed: loading ? null : _sendOtp,
          child: const Text('Resend OTP', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
        ),
        TextButton(
          onPressed: () => setState(() => step = 1),
          child: const Text('Change email address', style: TextStyle(color: AppColors.textMuted)),
        ),
      ],
    );
  }

  Widget _stepPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Set new password',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        const SizedBox(height: 6),
        const Text(
          'Choose a strong password for your PanditIndia account.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
        ),
        const SizedBox(height: 22),
        AppTextField(
          label: 'New Password',
          controller: _password,
          obscure: true,
          prefix: const Icon(Icons.lock_outline, size: 20, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Confirm New Password',
          controller: _confirm,
          obscure: true,
          prefix: const Icon(Icons.lock_reset_outlined, size: 20, color: AppColors.textMuted),
        ),
        const SizedBox(height: 22),
        AppButton(label: 'Update Password', onPressed: _resetPassword, loading: loading),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    const labels = ['Email', 'OTP', 'Password'];
    return Row(
      children: List.generate(labels.length, (i) {
        final idx = i + 1;
        final active = idx <= current;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? AppColors.accent : Colors.white,
                  border: Border.all(color: active ? AppColors.accent : AppColors.border, width: 1.6),
                ),
                child: Center(
                  child: active && idx < current
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : Text('$idx',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: active ? Colors.white : AppColors.textMuted,
                          )),
                ),
              ),
              const SizedBox(width: 6),
              Text(labels[i],
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.textDark : AppColors.textMuted,
                  )),
              if (i < labels.length - 1)
                const Expanded(child: Divider(indent: 6, endIndent: 6, thickness: 1.4)),
            ],
          ),
        );
      }),
    );
  }
}
