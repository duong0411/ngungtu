import 'package:flutter/material.dart';

import '../theme.dart';

void showAppSnack(
  BuildContext context, {
  required String message,
  bool success = false,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: success ? NgungTuTheme.aqua : NgungTuTheme.ice,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.3),
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: NgungTuTheme.panel,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: Duration(milliseconds: success ? 2200 : 3200),
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
      Future<void>.delayed(const Duration(milliseconds: 1400), () {
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
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontSize: 20),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: NgungTuTheme.soft.withValues(alpha: 0.72),
                        height: 1.4,
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
