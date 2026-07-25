import 'package:flutter/material.dart';
import '../theme.dart';

/// Apple-style error state. No red icons — muted content colors.
class ErrorState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppTheme.tertiaryLabel),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.body.copyWith(color: AppTheme.secondaryLabel),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.spacing16),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.systemBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing16,
                    vertical: AppTheme.spacing12,
                  ),
                  minimumSize: const Size(0, AppTheme.spacing44),
                ),
                child: const Text('Retry', style: AppTheme.body),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
