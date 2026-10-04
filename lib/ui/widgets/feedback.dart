import 'package:flutter/material.dart';

import '../theme.dart';

void showAppSnack(
  BuildContext context, {
  required String message,
  bool success = false,
}) {
  if (message.trim().isEmpty) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: success ? NgungTuTheme.aqua : NgungTuTheme.ice,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: NgungTuTheme.soft,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF12343E),
      elevation: 8,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: (success ? NgungTuTheme.aqua : NgungTuTheme.ice).withValues(alpha: 0.35),
        ),
      ),
      duration: Duration(milliseconds: success ? 2600 : 3600),
    ),
  );
}

Future<void> showSuccessDialog(
  BuildContext context, {
  required String title,
  String? message,
}) async {
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      Future<void>.delayed(const Duration(milliseconds: 1600), () {
        if (!ctx.mounted) return;
        final nav = Navigator.of(ctx);
        if (nav.canPop()) nav.pop();
      });
      return Dialog(
        backgroundColor: NgungTuTheme.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NgungTuTheme.aqua.withValues(alpha: 0.16),
                  border: Border.all(color: NgungTuTheme.aqua.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.check_rounded, color: NgungTuTheme.aqua, size: 34),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: NgungTuTheme.soft,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: NgungTuTheme.soft.withValues(alpha: 0.75),
                    height: 1.4,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
