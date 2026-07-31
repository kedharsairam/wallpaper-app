import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../theme.dart';
import '../widgets/empty_illustrations.dart';
import '../widgets/empty_state.dart';

class DownloadsScreen extends StatefulWidget {
  final VoidCallback? onBrowseTap;

  const DownloadsScreen({super.key, this.onBrowseTap});

  @override
  DownloadsScreenState createState() => DownloadsScreenState();
}

class DownloadsScreenState extends State<DownloadsScreen> {
  List<_DownloadEntry> _entries = [];

  /// Refresh the downloads list from disk.
  void refresh() => _loadDownloads();

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dir = Directory(docsDir.path);
      if (await dir.exists()) {
        final entities = await dir.list().toList();
        final downloads = <_DownloadEntry>[];
        for (final e in entities) {
          if (e is File && p.basename(e.path).startsWith('wallkraft-')) {
            // Collect stat asynchronously to avoid blocking the UI thread.
            try {
              final stat = await e.stat();
              downloads.add(_DownloadEntry(e, stat));
            } catch (e) {
              debugPrint('[Downloads] Stat failed: $e');
            }
          }
        }
        downloads.sort((a, b) => b.stat.modified.compareTo(a.stat.modified));
        if (mounted) setState(() => _entries = downloads);
      } else {
        if (mounted) setState(() => _entries = []);
      }
    } catch (e) {
      debugPrint('[Downloads] Load failed: $e');
      if (mounted) setState(() => _entries = []);
    }
  }

  Future<void> _deleteFile(_DownloadEntry entry) async {
    try {
      await entry.file.delete();
      HapticFeedback.lightImpact();
      _loadDownloads();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) {
      return EmptyState(
        illustration: Illustration.downloads,
        title: 'No downloads',
        subtitle: 'Download wallpapers to see them here',
        action: TextButton(
          onPressed: widget.onBrowseTap,
          child: const Text('Browse Wallpapers'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDownloads,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
        itemCount: _entries.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final entry = _entries[index];
          final name = p.basename(entry.file.path);
          return Dismissible(
            key: ValueKey(entry.file.path),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppTheme.spacing20),
              color: Colors.redAccent,
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            onDismissed: (_) => _deleteFile(entry),
            child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                entry.file,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                cacheWidth: 112,
                cacheHeight: 112,
                errorBuilder: (_, _, _) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    color: isDark
                        ? AppTheme.tertiarySystemBackground
                        : AppTheme.lightTertiaryBackground,
                    child: Icon(Icons.broken_image,
                        color: isDark
                            ? AppTheme.tertiaryLabel
                            : AppTheme.lightTertiaryLabel),
                  );
                },
              ),
            ),
            title: Text(
              name,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _formatSize(entry.stat.size),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6)),
              tooltip: 'Delete',
              onPressed: () => _deleteFile(entry),
            ),
          ),
          );
        },
      ),
    );
  }
}

/// A downloaded file paired with its cached [FileStat] to avoid
/// blocking the UI thread with synchronous stat calls during build.
class _DownloadEntry {
  final File file;
  final FileStat stat;

  const _DownloadEntry(this.file, this.stat);
}
