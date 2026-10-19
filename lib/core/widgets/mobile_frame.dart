import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centers the app inside a phone-sized frame when running in a browser so the
/// mobile layout can be tested on a desktop machine. Returns the child
/// unchanged on real phones/tablets (non-web targets).
Widget buildMobileFrame(BuildContext context, Widget? child) {
  if (!kIsWeb || child == null) return child ?? const SizedBox.shrink();
  return LayoutBuilder(
    builder: (context, constraints) {
      const phoneWidth = 412.0;
      final height =
          constraints.maxHeight > 900 ? 900.0 : constraints.maxHeight;
      return MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(size: Size(phoneWidth, height)),
        child: ColoredBox(
          color: const Color(0xFF0E1620),
          child: Center(
            child: Container(
              width: phoneWidth + 16,
              height: height,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF05070A),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xFF1E262F)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: child,
              ),
            ),
          ),
        ),
      );
    },
  );
}
