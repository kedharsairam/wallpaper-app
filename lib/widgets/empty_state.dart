import 'package:flutter/material.dart';
import '../theme.dart';

/// Apple-style empty state with icon, title, optional subtitle, and optional action.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: AppTheme.tertiaryLabel),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.callout.copyWith(color: AppTheme.secondaryLabel),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.spacing4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTheme.footnote.copyWith(color: AppTheme.tertiaryLabel),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppTheme.spacing20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
