import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/l10n/app_language.dart';
import '../../core/utils/dial_countries.dart';
import '../../providers/language_provider.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

// ============================================================
// COLORS (matches reference design)
// ============================================================

const Color authPrimaryOrange = Color(0xFFFF7900);
const Color authSecondaryOrange = Color(0xFFFF4D1F);
const Color authDarkText = Color(0xFF172033);
const Color authGreyText = Color(0xFF70798B);
const Color authCream = Color(0xFFFFF8EF);
const Color authHeadingBrown = Color(0xFF4B2015);
const Color authBodySlate = Color(0xFF36465A);
const Color authFieldBorder = Color(0xFFE1E2E5);
const Color authFieldFill = Color(0xFFFCFCFC);
const Color authHintGrey = Color(0xFF9299A7);
const Color authDividerGrey = Color(0xFFE0E0E0);
const Color authGold = Color(0xFFD89A52);

/// Validation messages and error borders.
const Color authFieldError = Color(0xFFD32F2F);

const String kTempleBackgroundAsset = 'assets/images/pandit_login_bg.jpg';

/// Bundled brand logo. Swap this for a wide wordmark once one is supplied.
const String kBrandLogoAsset = 'assets/branding/logo.png';

// ============================================================
// DENSITY SCALE
// ============================================================

/// Default viewport height the dimensions below are tuned for.
///
/// Screens with more content pass their own [designHeight] to [AuthScaffold] so
/// a long form shrinks harder than a short one.
const double _kAuthDesignHeight = 860;

/// How far the layout may shrink on short screens.
const double _kAuthMinScale = 0.70;

/// Exposes a density multiplier to every widget in the auth flow.
///
/// The reference design was drawn for a tall phone, so on a short viewport the
/// fields, buttons and gaps all shrink together instead of forcing a scroll.
class AuthScale extends InheritedWidget {
  const AuthScale({super.key, required this.scale, required super.child});

  final double scale;

  /// Multiplier for fixed dimensions. 1.0 on a design-height viewport.
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScale>()?.scale ?? 1.0;

  /// Multiplier for font sizes, which need less shrink than boxes.
  static double textOf(BuildContext context) =>
      of(context).clamp(0.86, 1.0).toDouble();

  /// Scales a fixed dimension, never below [minimum].
  static double dim(
    BuildContext context,
    double value, {
    double minimum = 34,
  }) => (value * of(context)).clamp(minimum, double.infinity).toDouble();

  /// Scales a font size, never dropping below legibility.
  static double font(
    BuildContext context,
    double value, {
    double minimum = 10,
  }) => (value * textOf(context)).clamp(minimum, double.infinity).toDouble();

  /// Scales a gap. No floor: spacing can compress to nothing.
  static double gap(BuildContext context, double value) => value * of(context);

  /// Picks the scale factor for the current viewport.
  ///
  /// [designHeight] is the viewport height the screen's content is authored
  /// for. A form taller than the baseline canvas passes a larger value so the
  /// scale drops further and the extra fields stay on screen.
  static double forHeight(
    double height, {
    double designHeight = _kAuthDesignHeight,
    double minScale = _kAuthMinScale,
  }) => (height / designHeight).clamp(minScale, 1.0).toDouble();

  @override
  bool updateShouldNotify(AuthScale oldWidget) => oldWidget.scale != scale;
}

/// Serif hero heading used on both auth pages.
class AuthHeading extends StatelessWidget {
  const AuthHeading(
    this.text, {
    super.key,
    this.fontSize = 34,
    this.centered = false,
  });

  final String text;
  final double fontSize;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontSize: AuthScale.font(context, fontSize, minimum: 24),
        height: 1.06,
        fontWeight: FontWeight.w700,
        color: authHeadingBrown,
      ),
    );
  }
}

/// Muted supporting line under the hero heading.
class AuthSubtitle extends StatelessWidget {
  const AuthSubtitle(
    this.text, {
    super.key,
    this.fontSize = 15.5,
    this.centered = false,
  });

  final String text;
  final double fontSize;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontSize: AuthScale.font(context, fontSize, minimum: 12),
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: authBodySlate,
      ),
    );
  }
}

/// Lays two fields side by side when the form is wide enough, otherwise stacks
/// them. Keeps Create Account short on phones without cramping narrow screens.
class AuthFieldPair extends StatelessWidget {
  const AuthFieldPair({
    super.key,
    required this.left,
    required this.right,
    this.minSideBySideWidth = 318,
  });

  final Widget left;
  final Widget right;

  /// Below this usable width the fields stack instead of sharing a row.
  final double minSideBySideWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = SizedBox(width: AuthScale.gap(context, 10));
        final stackedGap = SizedBox(height: AuthScale.gap(context, 10));
        if (constraints.maxWidth < minSideBySideWidth) {
          return Column(children: [left, stackedGap, right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            gap,
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

// ============================================================
// BACKDROP
// ============================================================

/// Temple photograph with a soft cream wash so the form stays readable.
///
/// Falls back to a painted gradient if the photograph has not been added yet,
/// so the screen never renders as a broken image.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, this.fadeStart = 0.52});

  /// Where the cream fade reaches full opacity, measured from the top.
  final double fadeStart;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          kTempleBackgroundAsset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => const _PaintedBackdrop(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.20),
                authCream.withValues(alpha: 0.92),
                authCream,
              ],
              stops: [0.0, fadeStart, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

/// Stand-in used only while the real photograph is missing.
class _PaintedBackdrop extends StatelessWidget {
  const _PaintedBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFECBE), authCream],
        ),
      ),
    );
  }
}

// ============================================================
// BRANDING
// ============================================================

/// Centered PanditIndia logo inside a circular white plate, matching the
/// reference design's hero badge.
class AuthBrandLogo extends StatelessWidget {
  const AuthBrandLogo({super.key, this.size = 118, this.minimum = 74});

  final double size;

  /// Smallest rendered size. A screen with a long form passes a lower floor so
  /// the mark never holds the viewport open.
  final double minimum;

  @override
  Widget build(BuildContext context) {
    final d = AuthScale.dim(context, size, minimum: minimum);
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(kBrandLogoAsset, fit: BoxFit.contain),
    );
  }
}

class AuthTagline extends StatelessWidget {
  const AuthTagline({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.local_florist_rounded,
          color: authGold,
          size: AuthScale.dim(context, 26, minimum: 20),
        ),
        SizedBox(height: AuthScale.gap(context, 7)),
        Text(
          context.tr('brand.tagline'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AuthScale.font(context, 11, minimum: 9),
            letterSpacing: 2.2,
            fontWeight: FontWeight.w600,
            color: authGold,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// LANGUAGE DROPDOWN (wired to LanguageProvider)
// ============================================================

/// Top-right language dropdown shown on both Login and Create Account.
///
/// This replaces the standalone demo dropdown: choosing a language writes
/// straight to [LanguageProvider], so the change applies app-wide immediately.
/// Compact language switcher for the dark Design G header: a translucent
/// outlined pill showing the active language code (`EN`) with a dropdown
/// for the rest.
class HeaderLanguagePill extends StatelessWidget {
  const HeaderLanguagePill({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<LanguageProvider>().language;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AppLanguage>(
          value: selected,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Colors.white,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          dropdownColor: const Color(0xFF021F2C),
          items: [
            for (final language in AppLanguage.values)
              DropdownMenuItem(
                value: language,
                child: Text(language.code.toUpperCase()),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              context.read<LanguageProvider>().setLanguage(value);
            }
          },
        ),
      ),
    );
  }
}

class AuthLanguageDropdown extends StatelessWidget {
  const AuthLanguageDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<LanguageProvider>().language;
    final height = AuthScale.dim(context, 42, minimum: 36);

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AppLanguage>(
          value: selected,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: authDarkText,
          ),
          borderRadius: BorderRadius.circular(18),
          style: const TextStyle(color: authDarkText),
          items: [
            for (final language in AppLanguage.values)
              DropdownMenuItem(
                value: language,
                child: _LanguageRow(label: language.nativeName),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              context.read<LanguageProvider>().setLanguage(value);
            }
          },
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.language_rounded,
          color: authDarkText,
          size: AuthScale.dim(context, 21, minimum: 18),
        ),
        const SizedBox(width: 9),
        Text(
          label,
          style: TextStyle(
            fontSize: AuthScale.font(context, 15, minimum: 12.5),
            fontWeight: FontWeight.w600,
            color: authDarkText,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TEXT FIELDS
// ============================================================

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.textInputAction,
    this.validator,
    this.focusNode,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final text = value.text;
        final error = text.isEmpty ? null : validator?.call(text);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthFieldLabel(label),
            SizedBox(height: AuthScale.gap(context, 6)),
            AuthFieldShell(
              error: error,
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                obscureText: obscureText,
                keyboardType: keyboardType,
                readOnly: readOnly,
                onTap: onTap,
                onFieldSubmitted: onFieldSubmitted,
                textInputAction: textInputAction,
                validator: validator,
                style: TextStyle(
                  fontSize: AuthScale.font(context, 16, minimum: 13.5),
                  fontWeight: FontWeight.w500,
                  color: authDarkText,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    icon,
                    color: const Color(0xFF293447),
                    size: AuthScale.dim(context, 22, minimum: 18),
                  ),
                  suffixIcon: suffixIcon,
                  hintText: hint,
                  hintStyle: TextStyle(
                    fontSize: AuthScale.font(context, 14.5, minimum: 12.5),
                    color: authHintGrey,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: AuthScale.gap(context, 16),
                  ),
                ),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 5),
                child: Text(
                  error,
                  style: TextStyle(
                    fontSize: AuthScale.font(context, 11.5, minimum: 10),
                    fontWeight: FontWeight.w600,
                    color: authFieldError,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Phone input with a country picker.
///
/// The picker decides how many digits are accepted: switching to India caps the
/// field at 10, and validation rejects anything shorter than the selected
/// country's national number length, so the user is told what to fix instead of
/// silently submitting an invalid number.
class AuthMobileField extends StatefulWidget {
  const AuthMobileField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.focusNode,
    this.initialCountry = kDefaultDialCountry,
    this.onCountryChanged,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;

  /// Placeholder for the digits, e.g. "10-digit mobile number".
  final String hint;
  final FocusNode? focusNode;

  /// Country selected when the field first appears.
  final DialCountry initialCountry;

  /// Fired on every country change so the caller can send the dialling code
  /// with the registration payload.
  final ValueChanged<DialCountry>? onCountryChanged;
  final TextInputAction? textInputAction;
  final VoidCallback? onFieldSubmitted;

  @override
  State<AuthMobileField> createState() => _AuthMobileFieldState();
}

class _AuthMobileFieldState extends State<AuthMobileField> {
  late DialCountry _country = widget.initialCountry;

  @override
  void didUpdateWidget(covariant AuthMobileField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCountry != oldWidget.initialCountry &&
        widget.initialCountry != _country) {
      _selectCountry(widget.initialCountry);
    }
  }

  /// Applies [country] and trims digits that no longer fit its limit, so a
  /// switch from India (10) to Singapore (8) cannot leave an over-length value
  /// sitting in the field.
  void _selectCountry(DialCountry country) {
    setState(() {
      _country = country;
      final digits = widget.controller.text.replaceAll(RegExp(r'\D'), '');
      final capped = digits.length > country.nationalNumberLength
          ? digits.substring(0, country.nationalNumberLength)
          : digits;
      if (capped != widget.controller.text) widget.controller.text = capped;
    });
    widget.onCountryChanged?.call(country);
  }

  Future<void> _pickCountry() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<DialCountry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _CountryPickerSheet(selected: _country),
    );
    if (picked != null && mounted) _selectCountry(picked);
  }

  String? _validate(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return context.tr('register.errMobileRequired');
    if (digits.length != _country.nationalNumberLength) {
      return context.tr('register.errMobileLength', {
        'count': _country.nationalNumberLength,
      });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final digits = widget.controller.text.replaceAll(RegExp(r'\D'), '');
    final error = digits.isEmpty ? null : _validate(digits);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthFieldLabel(widget.label),
        SizedBox(height: AuthScale.gap(context, 6)),
        AuthFieldShell(
          error: error,
          child: Row(
            children: [
              // Country and dialling code.
              InkWell(
                onTap: _pickCountry,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: AuthScale.dim(context, 34, minimum: 28),
                  padding: const EdgeInsets.only(left: 12, right: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _country.flag,
                        style: TextStyle(
                          fontSize: AuthScale.font(context, 17, minimum: 15),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _country.displayDialCode,
                        style: TextStyle(
                          fontSize: AuthScale.font(context, 15, minimum: 13),
                          fontWeight: FontWeight.w600,
                          color: authDarkText,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: AuthScale.dim(context, 18, minimum: 16),
                        color: authGreyText,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  keyboardType: TextInputType.phone,
                  textInputAction: widget.textInputAction,
                  onFieldSubmitted: (_) => widget.onFieldSubmitted?.call(),
                  validator: _validate,
                  // Digits only, never more than the country's limit: this is
                  // what blocks an 11th digit rather than flagging it later.
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      _country.nationalNumberLength,
                    ),
                  ],
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: AuthScale.font(context, 15, minimum: 13),
                    color: authDarkText,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      fontSize: AuthScale.font(context, 13.5, minimum: 12),
                      color: authHintGrey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              if (error == null && digits.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    '${digits.length}/${_country.nationalNumberLength}',
                    style: TextStyle(
                      fontSize: AuthScale.font(context, 11, minimum: 10),
                      fontWeight: FontWeight.w700,
                      color: authGreyText,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 5),
            child: Text(
              error,
              style: TextStyle(
                fontSize: AuthScale.font(context, 11.5, minimum: 10),
                fontWeight: FontWeight.w600,
                color: authFieldError,
              ),
            ),
          ),
      ],
    );
  }
}

/// Bottom sheet listing every supported country with its dialling code.
class _CountryPickerSheet extends StatelessWidget {
  const _CountryPickerSheet({required this.selected});

  final DialCountry selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('register.selectCountry'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: authDarkText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: authDividerGrey),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: kDialCountries.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                itemBuilder: (context, index) {
                  final country = kDialCountries[index];
                  final isSelected = country.iso == selected.iso;
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(country),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Text(
                            country.flag,
                            style: const TextStyle(fontSize: 21),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              country.name,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: authDarkText,
                              ),
                            ),
                          ),
                          Text(
                            '${country.displayDialCode} · ${country.nationalNumberLength}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: authGreyText,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: authPrimaryOrange,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small uppercase label above every auth input.
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: AuthScale.font(context, 11.5, minimum: 10),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: authGreyText,
      ),
    );
  }
}

/// Rounded, bordered container wrapping a field's input area.
class AuthFieldShell extends StatelessWidget {
  const AuthFieldShell({super.key, required this.child, this.error});

  final Widget child;

  /// When set, the border turns red to match the message shown underneath.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Container(
      height: AuthScale.dim(context, 58, minimum: 48),
      decoration: BoxDecoration(
        color: authFieldFill,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: hasError ? authFieldError : authFieldBorder,
          width: hasError ? 1.4 : 1,
        ),
      ),
      child: child,
    );
  }
}

// ============================================================
// CHECKBOX
// ============================================================

/// Tappable orange checkbox with its label, used for Remember me and Terms.
class AuthCheckBox extends StatelessWidget {
  const AuthCheckBox({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.labelSize = 17,
  });

  final bool value;
  final String label;
  final VoidCallback onChanged;
  final double labelSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      behavior: HitTestBehavior.opaque,
      // Flexible, not Expanded: this widget is used both standalone in a Column
      // and inside the Remember me Row. Flexible lets the row shrink-wrap when
      // the incoming width is unbounded.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AuthScale.dim(context, 24, minimum: 20),
            height: AuthScale.dim(context, 24, minimum: 20),
            decoration: BoxDecoration(
              color: value ? authPrimaryOrange : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? authPrimaryOrange : Colors.grey.shade400,
                width: 1.5,
              ),
            ),
            child: value
                ? Icon(
                    Icons.check,
                    size: AuthScale.dim(context, 18, minimum: 15),
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AuthScale.font(context, labelSize, minimum: 12),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: authDarkText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BUTTONS
// ============================================================

/// Full-width orange gradient action button with a trailing arrow.
class AuthGradientButton extends StatelessWidget {
  const AuthGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final radius = BorderRadius.circular(17);
    return Opacity(
      opacity: enabled ? 1 : 0.75,
      child: SizedBox(
        width: double.infinity,
        height: AuthScale.dim(context, 56, minimum: 48),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8500), authSecondaryOrange],
            ),
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: authPrimaryOrange.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? onPressed : null,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: AuthScale.font(
                                  context,
                                  18,
                                  minimum: 15,
                                ),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: AuthScale.gap(context, 12)),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: AuthScale.dim(context, 23, minimum: 20),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined secondary action (Create Account on Login, Sign In on Register).
class AuthSecondaryButton extends StatelessWidget {
  const AuthSecondaryButton({
    super.key,
    required this.child,
    required this.onTap,
    this.height = 62,
    this.leadingIcon,
  });

  final Widget child;
  final VoidCallback onTap;
  final double height;
  final Widget? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(17);
    return Material(
      color: Colors.white,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: AuthScale.dim(context, height, minimum: 50),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: radius,
            border: Border.all(color: const Color(0xFFE5E5E5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                leadingIcon!,
                const SizedBox(width: 14),
              ],
              Expanded(child: child),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade500,
                size: AuthScale.dim(context, 26, minimum: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// OR DIVIDER
// ============================================================

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: authDividerGrey, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            context.tr('auth.or'),
            style: TextStyle(
              fontSize: AuthScale.font(context, 13, minimum: 11),
              color: authGreyText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: authDividerGrey, height: 1)),
      ],
    );
  }
}

// ============================================================
// PAGE SCAFFOLD
// ============================================================

/// Shared page frame: temple backdrop, scrollable body, and the bottom-rounded
/// white card that the form fields sit inside.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.header,
    required this.formChildren,
    this.fadeStart = 0.52,
    this.formPadding = const EdgeInsets.fromLTRB(18, 16, 18, 14),
    this.designHeight,
    this.minScale = _kAuthMinScale,
  });

  final Widget header;

  /// Form widgets rendered inside the white rounded card.
  final List<Widget> formChildren;

  final double fadeStart;
  final EdgeInsets formPadding;

  /// Viewport height this screen's content is authored for. Defaults to the
  /// shared baseline; a longer form overrides it to shrink harder.
  final double? designHeight;

  /// Lower bound for the density multiplier on this screen.
  final double minScale;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authCream,
      body: Stack(
        children: [
          AuthBackdrop(fadeStart: fadeStart),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Derive the density factor from the height actually available
                // so the page fits the device rather than the design canvas.
                final scale = AuthScale.forHeight(
                  constraints.maxHeight,
                  designHeight: designHeight ?? _kAuthDesignHeight,
                  minScale: minScale,
                );
                return AuthScale(
                  scale: scale,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        header,
                        SizedBox(height: AuthScale.gap(context, 18)),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.only(
                            left: AuthScale.gap(context, formPadding.left),
                            right: AuthScale.gap(context, formPadding.right),
                            top: AuthScale.gap(context, formPadding.top),
                            bottom: AuthScale.gap(context, formPadding.bottom),
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(34),
                              topRight: Radius.circular(34),
                            ),
                          ),
                          child: Column(children: formChildren),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
