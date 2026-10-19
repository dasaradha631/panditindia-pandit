import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/language_selector.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../main_shell.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _gurukul = TextEditingController();
  final _experience = TextEditingController(text: '10');
  final _city = TextEditingController();
  final _languages = TextEditingController(text: 'Hindi, Sanskrit');
  final _otp = TextEditingController();

  String specialization = 'Rigveda & Vastu Shanti';
  bool _loading = false;
  int step = 1;

  // ─── Step 1: contact OTP verification (web PanditRegisterPage parity) ───
  String _channel = 'email';
  bool _otpSent = false;
  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  bool _verified = false;
  String _verifiedIdentifier = '';
  int _resendIn = 0;
  Timer? _resendTimer;

  static const _specializations = [
    'Rigveda Specialist',
    'Yajurveda Specialist',
    'Samaveda Specialist',
    'Atharvaveda Specialist',
    'Vedic Astrology (Jyotish)',
    'Vastu Shastra Specialist',
    'Rigveda & Vastu Shanti',
  ];

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in [
      _name, _email, _phone, _password, _confirm,
      _gurukul, _experience, _city, _languages, _otp,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _selectedIdentifier => _channel == 'email'
      ? _email.text.trim().toLowerCase()
      : _phone.text.trim();

  bool get _identifierValid => _channel == 'email'
      ? (_selectedIdentifier.contains('@') && _selectedIdentifier.contains('.'))
      : (_selectedIdentifier.length == 10 &&
          int.tryParse(_selectedIdentifier) != null);

  bool get _step1Valid => _verified;
  bool get _step2Valid =>
      _name.text.trim().length >= 3 &&
      _phone.text.trim().length == 10 &&
      _email.text.trim().contains('@') &&
      _password.text.length >= 6 &&
      _password.text == _confirm.text &&
      _city.text.trim().isNotEmpty &&
      _languages.text.trim().isNotEmpty;

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendIn = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendIn <= 1) {
        t.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn--);
      }
    });
  }

  void _resetVerification() {
    _resendTimer?.cancel();
    setState(() {
      _otpSent = false;
      _verified = false;
      _verifiedIdentifier = '';
      _resendIn = 0;
      _otp.clear();
    });
  }

  Future<void> _sendOtp() async {
    if (!_identifierValid) {
      showAppToast(
        context,
        _channel == 'email'
            ? context.tr('register.enterValidEmail')
            : context.tr('register.enterValidPhone'),
        type: ToastType.warning,
        title: context.tr('auth.register'),
      );
      return;
    }
    setState(() => _sendingOtp = true);
    final error = await context.read<AuthProvider>().sendRegistrationOtp(
          identifier: _selectedIdentifier,
          channel: _channel,
        );
    if (!mounted) return;
    setState(() {
      _sendingOtp = false;
      if (error == null) {
        _otpSent = true;
        _verified = false;
        _otp.clear();
      }
    });
    if (error != null) {
      final already = error.toLowerCase().contains('already registered');
      showAppToast(context, error,
          type: already ? ToastType.warning : ToastType.error,
          title: context.tr('auth.register'));
      return;
    }
    _startResendCountdown();
    showAppToast(
      context,
      context.tr('register.otpSentSuccess'),
      type: ToastType.success,
      title: context.tr('auth.register'),
    );
  }

  Future<void> _verifyOtp() async {
    final code = _otp.text.trim();
    if (code.length != 6) {
      showAppToast(context, context.tr('register.enterSixDigitOtp'),
          type: ToastType.warning, title: context.tr('auth.register'));
      return;
    }
    setState(() => _verifyingOtp = true);
    final error = await context.read<AuthProvider>().verifyRegistrationOtp(
          identifier: _selectedIdentifier,
          channel: _channel,
          otp: code,
        );
    if (!mounted) return;
    setState(() {
      _verifyingOtp = false;
      if (error == null) {
        _verified = true;
        _verifiedIdentifier = _selectedIdentifier;
        _resendTimer?.cancel();
        _resendIn = 0;
      }
    });
    if (error != null) {
      showAppToast(context, error,
          type: ToastType.error, title: context.tr('auth.register'));
      return;
    }
    showAppToast(
      context,
      context.tr('register.contactVerifiedSuccess'),
      type: ToastType.success,
      title: context.tr('auth.register'),
    );
  }

  Future<void> _submit() async {
    if (!_verified) {
      showAppToast(context, context.tr('register.verifyContactFirst'),
          type: ToastType.warning, title: context.tr('auth.register'));
      setState(() => step = 1);
      return;
    }
    if (!_step2Valid) {
      showAppToast(context, context.tr('register.fillAllRequired'),
          type: ToastType.warning, title: context.tr('auth.register'));
      return;
    }
    setState(() => _loading = true);
    final language = context.read<LanguageProvider>().language.code;
    final payload = <String, dynamic>{
      'username': _name.text.trim(),
      'full_name': _name.text.trim(),
      'email': _email.text.trim(),
      'phonenumber': _phone.text.trim(),
      'password': _password.text,
      'role': 'admin',
      'gurukul': _gurukul.text.trim(),
      'veda_branch': specialization,
      'specializations': specialization,
      'experience_years': int.tryParse(_experience.text.trim()) ?? 10,
      'languages': _languages.text.trim(),
      'city': _city.text.trim(),
      // Selected UI language is persisted so the whole app renders in it.
      'language': language,
      'preferred_language': language,
    };
    final error = await context.read<AuthProvider>().register(payload);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      showAppToast(context, error, type: ToastType.error, title: context.tr('auth.register'));
      return;
    }
    _successDialog();
  }

  void _successDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 42),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('register.submittedScrutiny'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('register.profileCreated'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: context.tr('register.enterPortal'),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainShell()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: GradientAppBar(title: context.tr('register.acharyaTitle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: LanguageSelectorBar(compact: true),
            ),
            const SizedBox(height: 18),
            Row(
              children: List.generate(2, (i) {
                final idx = i + 1;
                final active = idx <= step;
                return Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? (_verified || idx <= step ? AppColors.accent : AppColors.accent)
                              : Colors.white,
                          border: Border.all(color: active ? AppColors.accent : AppColors.border, width: 1.6),
                        ),
                        child: Center(
                          child: idx == 1 && _verified
                              ? const Icon(Icons.check, size: 15, color: Colors.white)
                              : Text('$idx',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      color: active ? Colors.white : AppColors.textMuted)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.tr(i == 0 ? 'register.stepVerify' : 'register.stepProfile'),
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: active ? AppColors.textDark : AppColors.textMuted),
                      ),
                      if (i == 0)
                        const Expanded(child: Divider(indent: 6, endIndent: 6, thickness: 1.4)),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            if (step == 1) _verifyStep() else _profileStep(),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, -3))],
        ),
        child: Row(
          children: [
            if (step == 2)
              OutlinedButton(
                onPressed: () => setState(() => step = 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textDark,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                child: Text(context.tr('common.back'),
                    style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: step == 1
                  ? AppButton(
                      label: context.tr('common.continue'),
                      onPressed: _step1Valid ? () => setState(() => step = 2) : null,
                    )
                  : AppButton(
                      label: context.tr('register.submitApplication'),
                      loading: _loading,
                      onPressed: _submit),
            ),
          ],
        ),
      ),
    );
  }

  /// STEP 1 — verify email/mobile via OTP (web parity: channel toggle,
  /// send code, 6-digit entry, 30s resend countdown, change-contact).
  Widget _verifyStep() {
    final contactLabel = _channel == 'email'
        ? context.tr('register.emailAddress')
        : context.tr('register.mobileWhatsapp');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _verified
              ? context.tr('register.contactVerifiedTitle')
              : _otpSent
                  ? context.tr('register.enterVerificationCode')
                  : context.tr('register.verifyYourContact'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark),
        ),
        const SizedBox(height: 6),
        Text(
          _verified
              ? context.tr('register.contactVerifiedSubtitle')
              : _otpSent
                  ? '${context.tr('register.otpSentTo')} $contactLabel ($_selectedIdentifier).'
                  : context.tr('register.verifySubtitle'),
          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.45),
        ),
        const SizedBox(height: 20),
        // Channel toggle (email / phone) — locked once a code is sent.
        Row(
          children: ['email', 'phone'].map((method) {
            final selected = _channel == method;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: method == 'email' ? 8 : 0, left: method == 'phone' ? 8 : 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _otpSent
                      ? null
                      : () {
                          if (_channel == method) return;
                          setState(() {
                            _channel = method;
                            _otp.clear();
                            _otpSent = false;
                            _verified = false;
                            _verifiedIdentifier = '';
                            _resendTimer?.cancel();
                            _resendIn = 0;
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: selected
                          ? const LinearGradient(
                              colors: [Color(0xFFD4AF37), Color(0xFF997A15)])
                          : null,
                      color: selected ? null : Colors.white,
                      border: Border.all(
                          color: selected ? Colors.transparent : AppColors.border, width: 1.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          method == 'email' ? Icons.mail_outline : Icons.phone_iphone,
                          size: 16,
                          color: selected ? const Color(0xFF021F2C) : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          method == 'email'
                              ? context.tr('register.channelEmail')
                              : context.tr('register.channelPhone'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: selected ? const Color(0xFF021F2C) : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        if (_verified)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.success.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$_verifiedIdentifier ✓',
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('register.contactVerifiedSubtitle'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _resetVerification,
                  child: Text(
                    context.tr('register.changeContact'),
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.accent),
                  ),
                ),
              ],
            ),
          )
        else ...[
          if (_channel == 'email')
            AppTextField(
              label: '${context.tr('register.emailAddress')} *',
              controller: _email,
              hint: context.tr('register.hintEmail'),
              keyboardType: TextInputType.emailAddress,
              prefix: const Icon(Icons.email_outlined, size: 20, color: AppColors.textMuted),
              onChanged: (_) => setState(() {}),
            )
          else
            AppTextField(
              label: '${context.tr('register.mobileWhatsapp')} *',
              controller: _phone,
              hint: context.tr('register.hintMobile'),
              keyboardType: TextInputType.phone,
              prefix: const Icon(Icons.phone_outlined, size: 20, color: AppColors.textMuted),
              onChanged: (_) => setState(() {}),
            ),
          const SizedBox(height: 16),
          if (!_otpSent)
            AppButton(
              label: context.tr('register.sendOtp'),
              loading: _sendingOtp,
              onPressed: _identifierValid ? _sendOtp : null,
            )
          else ...[
            AppTextField(
              label: '${context.tr('register.enterOtpLabel')} *',
              controller: _otp,
              hint: '------',
              keyboardType: TextInputType.number,
              maxLength: 6,
              prefix: const Icon(Icons.lock_clock_outlined, size: 20, color: AppColors.textMuted),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: context.tr('register.verifyOtpButton'),
                    loading: _verifyingOtp,
                    onPressed: _otp.text.trim().length == 6 ? _verifyOtp : null,
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: _resendIn > 0 || _sendingOtp ? null : _sendOtp,
                  child: Text(
                    _resendIn > 0
                        ? '${context.tr('register.resendIn')} ${_resendIn}s'
                        : context.tr('register.resendOtp'),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: _resendIn > 0 ? AppColors.textMuted : AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
        const SizedBox(height: 90),
      ],
    );
  }

  /// STEP 2 — account + Vedic credentials (the web's single form page).
  Widget _profileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('register.createYourAccount'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text(context.tr('register.accountSubtitle'),
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        const SizedBox(height: 20),
        AppTextField(
          label: '${context.tr('register.fullAcharyaName')} *',
          controller: _name,
          hint: context.tr('register.hintAcharyaName'),
          prefix: const Icon(Icons.person_outline, size: 20, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: '${context.tr('register.mobileWhatsapp')} *',
          controller: _phone,
          hint: context.tr('register.hintMobile'),
          keyboardType: TextInputType.phone,
          prefix: const Icon(Icons.phone_outlined, size: 20, color: AppColors.textMuted),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: '${context.tr('register.emailAddress')} *',
          controller: _email,
          hint: context.tr('register.hintEmail'),
          keyboardType: TextInputType.emailAddress,
          prefix: const Icon(Icons.email_outlined, size: 20, color: AppColors.textMuted),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: '${context.tr('auth.password')} *',
          controller: _password,
          obscure: true,
          hint: context.tr('register.hintMinPassword'),
          prefix: const Icon(Icons.lock_outline, size: 20, color: AppColors.textMuted),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: '${context.tr('auth.confirmPassword')} *',
          controller: _confirm,
          obscure: true,
          hint: context.tr('register.hintReenterPassword'),
          onChanged: (_) => setState(() {}),
          prefix: const Icon(Icons.lock_reset_outlined, size: 20, color: AppColors.textMuted),
          suffix: _confirm.text.isNotEmpty
              ? (_password.text == _confirm.text
                  ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                  : const Icon(Icons.cancel, color: AppColors.danger, size: 20))
              : null,
        ),
        const SizedBox(height: 24),
        const Divider(thickness: 1.2),
        const SizedBox(height: 16),
        Text(context.tr('register.vedaCredentials'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text(context.tr('register.vedaSubtitle'),
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        const SizedBox(height: 20),
        Text(context.tr('register.vedaShakha'),
            style: const TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: _specializations.map((s) {
            final selected = s == specialization;
            return ChoiceChip(
              label: Text(s, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              selected: selected,
              selectedColor: AppColors.accent,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textDark),
              side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
              onSelected: (_) => setState(() => specialization = s),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        AppTextField(label: context.tr('register.gurukul'), controller: _gurukul, hint: context.tr('register.optional')),
        const SizedBox(height: 16),
        AppTextField(
          label: context.tr('register.yearsExperience'),
          controller: _experience,
          keyboardType: TextInputType.number,
          prefix: const Icon(Icons.workspace_premium_outlined, size: 20, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: '${context.tr('register.primaryCity')} *',
          controller: _city,
          hint: context.tr('register.cityYouServe'),
          prefix: const Icon(Icons.location_city_outlined, size: 20, color: AppColors.textMuted),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: '${context.tr('register.languages')} *',
          controller: _languages,
          hint: context.tr('register.hintLanguages'),
          prefix: const Icon(Icons.translate_outlined, size: 20, color: AppColors.textMuted),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 90),
      ],
    );
  }
}
