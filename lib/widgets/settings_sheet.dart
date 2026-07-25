import 'package:flutter/material.dart';
import '../theme.dart';

/// Apple-style settings/about bottom sheet.
///
/// Shows version info, attribution, and legal links.
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing16, AppTheme.spacing20, AppTheme.spacing16, 32),
      decoration: const BoxDecoration(
        color: AppTheme.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grabber
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.tertiaryLabel,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing20),

          // About header
          const Text('About', style: AppTheme.title2),
          const SizedBox(height: AppTheme.spacing16),

          _infoRow('Version', '1.0.0'),
          const Divider(),
          _infoRow('Build', '1'),
          const Divider(),
          _infoRow('Platform', 'Android'),

          // App description
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.spacing8),
            child: Text(
              'Browse and download high-resolution wallpapers.',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.secondaryLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.secondaryLabel,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.label, fontSize: 15),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
