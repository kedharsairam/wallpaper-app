import 'package:flutter/material.dart';
import '../theme.dart';
import 'empty_illustrations.dart';

/// Apple-style empty state with optional custom vector illustration,
/// title, optional subtitle, and optional action button.
class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? icon;
  final Illustration? illustration;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.icon,
    this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null)
              EmptyIllustration(
                type: illustration!,
                size: 100,
              )
            else if (icon != null)
              Icon(icon, size: 48,
                  color: AppTheme.of(context, AppTheme.tertiaryLabel,
                      AppTheme.lightTertiaryLabel)),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.callout.copyWith(
                  color: AppTheme.of(
                      context, AppTheme.secondaryLabel, AppTheme.lightSecondaryLabel)),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.spacing4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTheme.footnote.copyWith(
                    color: AppTheme.of(
                        context, AppTheme.tertiaryLabel, AppTheme.lightTertiaryLabel)),
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
