import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';

import '../constants/app_config.dart';
import '../theme/app_theme.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

enum ToastType { success, error, warning, info }

void showAppToast(BuildContext context, String message, {ToastType type = ToastType.info, String? title}) {
  final color = switch (type) {
    ToastType.success => AppColors.success,
    ToastType.error => AppColors.danger,
    ToastType.warning => AppColors.warning,
    ToastType.info => AppColors.info,
  };
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: AppColors.primary,
      content: Row(
        children: [
          Icon(
            type == ToastType.success
                ? Icons.check_circle_outline
                : type == ToastType.error
                    ? Icons.error_outline
                    : type == ToastType.warning
                        ? Icons.warning_amber_outlined
                        : Icons.info_outline,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                  ),
                Text(message, style: const TextStyle(color: Colors.white, fontSize: 13.5)),
              ],
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 4500),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expand = true,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;
    final child = loading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 8)],
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
          );

    final Widget button;
    if (variant == AppButtonVariant.primary) {
      button = Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentHover]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: disabled
              ? null
              : [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            minimumSize: Size(expand ? double.infinity : 80, height),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: child,
        ),
      );
    } else if (variant == AppButtonVariant.gold) {
      button = ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.5),
          minimumSize: Size(expand ? double.infinity : 80, height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: child,
      );
    } else if (variant == AppButtonVariant.danger) {
      button = OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger),
          minimumSize: Size(expand ? double.infinity : 80, height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: child,
      );
    } else {
      button = OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          backgroundColor: Colors.white,
          minimumSize: Size(expand ? double.infinity : 80, height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: child,
      );
    }

    return button;
  }
}

enum AppButtonVariant { primary, outline, gold, danger }

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.maxLines = 1,
    this.validator,
    this.suffix,
    this.prefix,
    this.enabled = true,
    this.onChanged,
    this.textInputAction,
    this.errorText,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final int maxLines;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final Widget? prefix;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final String? errorText;

  /// Optional hard character cap (e.g. a profile bio); null = unlimited.
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          maxLines: maxLines,
          validator: validator,
          enabled: enabled,
          onChanged: onChanged,
          textInputAction: textInputAction,
          inputFormatters: maxLength == null ? null : [LengthLimitingTextInputFormatter(maxLength)],
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            suffixIcon: suffix,
            prefixIcon: prefix,
          ),
        ),
      ],
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color, this.dense = false});

  final String label;
  final Color color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: dense ? 9.5 : 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.8),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 12.5)),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.actionLabel, this.onAction});

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              AppButton(label: actionLabel!, onPressed: onAction, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.accent),
          if (label != null) ...[
            const SizedBox(height: 14),
            Text(label!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.value, required this.label, this.color = AppColors.accent, this.icon});

  final String value;
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)),
              const Spacer(),
              if (icon != null) Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 118,
            child: Text(label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.textDark, fontSize: 13.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class CeremonyImage extends StatelessWidget {
  const CeremonyImage({super.key, required this.assetPath, required this.emoji, this.height = 96, this.width});

  final String assetPath;
  final String emoji;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.assetUrl(assetPath);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(
          child: Text(emoji, style: TextStyle(fontSize: height * 0.4)),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: Text(emoji, style: TextStyle(fontSize: height * 0.4)),
          );
        },
      ),
    );
  }
}

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({super.key, this.title, this.actions, this.leading, this.bottom});

  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: title == null
            ? null
            : Text(title!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
        actions: actions,
        leading: leading,
        bottom: bottom,
      ),
    );
  }
}
