import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app.dart';
import '../services/api_key_service.dart';
import '../services/theme_service.dart';
import '../theme.dart';

/// Full-page settings screen replacing the old bottom sheet.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _apiKey;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _apiKey = await ApiKeyService.load();
    if (mounted) _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(
            () => _appVersion = '${info.version} (Build ${info.buildNumber})');
      }
    } catch (_) {}
  }

  Future<void> _openGetKeyUrl() async {
    final uri = Uri.parse(ApiKeyService.settingsUrl);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) debugPrint('[Settings] Failed to launch URL: $uri');
    } catch (e) {
      debugPrint('[Settings] URL launch error: $e');
    }
  }

  Future<void> _showKeyDialog() async {
    final controller = TextEditingController(text: _apiKey ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark
              ? AppTheme.secondarySystemBackground
              : AppTheme.lightSystemBackground,
          title: Text('Wallhaven API Key',
              style: TextStyle(
                  color: isDark ? AppTheme.label : AppTheme.lightLabel)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste your API key from Wallhaven settings to increase '
                'your rate limit from 45 to 5000 requests per hour.',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.secondaryLabel
                      : AppTheme.lightSecondaryLabel,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Paste your API key here',
                  hintStyle: TextStyle(
                      color: isDark
                          ? AppTheme.tertiaryLabel
                          : AppTheme.lightTertiaryLabel),
                  filled: true,
                  fillColor: isDark
                      ? AppTheme.tertiarySystemBackground
                      : AppTheme.lightTertiaryBackground,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                style:
                    TextStyle(color: isDark ? AppTheme.label : AppTheme.lightLabel),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            if (_apiKey != null)
              TextButton(
                onPressed: () async {
                  await ApiKeyService.save(null);
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                },
                child: const Text('Remove',
                    style: TextStyle(color: AppTheme.favoriteRed)),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  await ApiKeyService.save(value);
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved == true && mounted) {
      setState(() => _apiKey = null);
      final key = await ApiKeyService.load();
      if (mounted) setState(() => _apiKey = key);
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final launched =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!launched) debugPrint('[Settings] Failed to launch URL: $url');
    } catch (e) {
      debugPrint('[Settings] URL launch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = _apiKey != null && _apiKey!.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor =
        isDark ? AppTheme.tertiaryLabel : AppTheme.lightTertiaryLabel;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.systemBackground : AppTheme.lightSystemBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.spacing16, 0, AppTheme.spacing16, AppTheme.spacing32),
          children: [
            const SizedBox(height: AppTheme.spacing20),

            // Header with app icon
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/icon_source.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WallKraft', style: AppTheme.title2),
                    const SizedBox(height: 2),
                    Text(
                      _appVersion.isEmpty
                          ? 'Version 1.1.1'
                          : 'Version $_appVersion',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppTheme.secondaryLabel
                            : AppTheme.lightSecondaryLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing20),

            // Description
            Text(
              'Browse, download, and favorite high-resolution wallpapers '
              'from around the web. Powered by the Wallhaven API.',
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? AppTheme.secondaryLabel
                    : AppTheme.lightSecondaryLabel,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),

            // ── Section: API ──────────────────────────────────────────
            Text(
              'API',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hintColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),

            _settingRow(
              hasKey ? Icons.vpn_key : Icons.vpn_key_outlined,
              'Wallhaven API Key',
              trailing: hasKey
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 16, color: AppTheme.systemBlue),
                        SizedBox(width: 4),
                        Text(
                          'Connected',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.systemBlue,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Not set — 45 req/hr',
                      style: TextStyle(
                        fontSize: 13,
                        color: hintColor,
                      ),
                    ),
              onTap: _showKeyDialog,
            ),
            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.only(left: 34, bottom: 4),
              child: InkWell(
                onTap: _openGetKeyUrl,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new,
                          size: 14,
                          color: isDark
                              ? AppTheme.secondaryLabel
                              : AppTheme.lightSecondaryLabel),
                      const SizedBox(width: 6),
                      Text(
                        'Get your free key',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.secondaryLabel
                              : AppTheme.lightSecondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),

            // ── Section: Appearance ────────────────────────────────────
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hintColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            _themeRow(),
            const Divider(height: 1),
            const SizedBox(height: AppTheme.spacing16),

            // ── Section: Links ─────────────────────────────────────────
            Text(
              'Links',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hintColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),

            _settingRow(
              Icons.open_in_new,
              'Wallhaven API',
              onTap: () => _openUrl('https://wallhaven.cc'),
            ),
            const Divider(height: 1),
            _settingRow(
              Icons.code,
              'Source Code',
              onTap: () =>
                  _openUrl('https://github.com/kedharsairam/wallkraft'),
            ),
            const Divider(height: 1),
            _settingRow(
              Icons.info_outline,
              'About',
              onTap: () => _openUrl(
                  'https://github.com/kedharsairam/wallkraft#readme'),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // Footer
            Center(
              child: Text(
                'Made with Flutter',
                style: TextStyle(
                  fontSize: 12,
                  color: hintColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeRow() {
    final appState = WallKraftApp.of(context);
    final current = appState?.currentThemeMode ?? ThemeMode.system;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const modes = ThemeMode.values;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Row(
        children: [
          Icon(ThemeService.icon(current),
              size: 18, color: AppTheme.systemBlue),
          const SizedBox(width: AppTheme.spacing12),
          const Expanded(
            child: Text(
              'Appearance',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.systemBlue,
              ),
            ),
          ),
          DropdownButton<ThemeMode>(
            value: current,
            dropdownColor: isDark
                ? AppTheme.secondarySystemBackground
                : AppTheme.lightSecondaryBackground,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.systemBlue,
            ),
            underline: const SizedBox(),
            items: modes.map((mode) {
              return DropdownMenuItem(
                value: mode,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(ThemeService.icon(mode),
                        size: 16, color: AppTheme.systemBlue),
                    const SizedBox(width: 6),
                    Text(ThemeService.label(mode)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (mode) {
              if (mode != null) appState?.setThemeMode(mode);
            },
          ),
        ],
      ),
    );
  }

  Widget _settingRow(IconData icon, String label,
      {Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.systemBlue),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.systemBlue,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
