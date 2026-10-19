import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/widgets/common.dart';
import '../../providers/auth_provider.dart';
import '../main_shell.dart';
import 'auth_design.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _rememberMe = true;
  bool _loading = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final error = await context.read<AuthProvider>().login(
          identifier: _identifier.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      showAppToast(
        context,
        error,
        type: ToastType.error,
        title: context.tr('auth.signIn'),
      );
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  void _openForgotPassword() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
  }

  void _openRegister() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      fadeStart: 0.52,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [AuthLanguageDropdown()],
            ),
            SizedBox(height: AuthScale.gap(context, 12)),
            const Center(child: AuthBrandLogo(size: 92)),
            SizedBox(height: AuthScale.gap(context, 8)),
            AuthHeading(context.tr('auth.namasteAcharya'), fontSize: 30),
            SizedBox(height: AuthScale.gap(context, 8)),
            AuthSubtitle(context.tr('auth.acharyaSubtitle'), fontSize: 14),
          ],
        ),
      ),
      formChildren: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AuthTextField(
                controller: _identifier,
                label: context.tr('auth.emailOrMobile').toUpperCase(),
                hint: context.tr('register.hintEmail'),
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return context.tr('register.errIdentifier');
                  }
                  return null;
                },
              ),
              SizedBox(height: AuthScale.gap(context, 10)),
              AuthTextField(
                controller: _password,
                label: context.tr('auth.password').toUpperCase(),
                hint: context.tr('auth.hintPassword'),
                focusNode: _passwordFocus,
                icon: Icons.lock_outline_rounded,
                obscureText: _obscure,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: authDarkText,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return context.tr('register.errPassword');
                  }
                  if (v.length < 6) {
                    return context.tr('register.errPasswordShort');
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              SizedBox(height: AuthScale.gap(context, 10)),
              Row(
                children: [
                  Expanded(
                    child: AuthCheckBox(
                      value: _rememberMe,
                      label: context.tr('auth.rememberMe'),
                      onChanged: () =>
                          setState(() => _rememberMe = !_rememberMe),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _openForgotPassword,
                    child: Text(
                      context.tr('auth.forgotPassword'),
                      style: TextStyle(
                        fontSize: AuthScale.font(context, 13.5, minimum: 11.5),
                        fontWeight: FontWeight.w700,
                        color: authPrimaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AuthScale.gap(context, 12)),
              AuthGradientButton(
                label: context.tr('auth.signInToPortal'),
                loading: _loading,
                onPressed: _submit,
              ),
              SizedBox(height: AuthScale.gap(context, 11)),
              const AuthOrDivider(),
              SizedBox(height: AuthScale.gap(context, 11)),
              AuthSecondaryButton(
                onTap: _openRegister,
                leadingIcon: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: authPrimaryOrange,
                  size: 26,
                ),
                child: Text(
                  context.tr('auth.createAccount'),
                  style: TextStyle(
                    fontSize: AuthScale.font(context, 16, minimum: 13.5),
                    fontWeight: FontWeight.w700,
                    color: authDarkText,
                  ),
                ),
              ),
              SizedBox(height: AuthScale.gap(context, 11)),
              Text(
                context.tr('auth.termsLine1'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AuthScale.font(context, 13, minimum: 11),
                  color: authGreyText,
                ),
              ),
              SizedBox(height: AuthScale.gap(context, 2)),
              Text(
                context.tr('auth.termsLink'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AuthScale.font(context, 14, minimum: 12),
                  fontWeight: FontWeight.w600,
                  color: authPrimaryOrange,
                  decoration: TextDecoration.underline,
                ),
              ),
              SizedBox(height: AuthScale.gap(context, 12)),
              const AuthTagline(),
            ],
          ),
        ),
      ],
    );
  }
}
