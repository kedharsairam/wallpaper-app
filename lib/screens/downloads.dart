import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../theme.dart';

class DownloadsScreen extends StatefulWidget {
  final VoidCallback? onBrowseTap;

  const DownloadsScreen({super.key, this.onBrowseTap});

  @override
  DownloadsScreenState createState() => DownloadsScreenState();
}

class DownloadsScreenState extends State<DownloadsScreen> {
  List<FileSystemEntity> _files = [];
  var _isLoading = true;

  /// Refresh the downloads list from disk.
  void refresh() => _loadDownloads();

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dir = Directory(docsDir.path);
      if (await dir.exists()) {
        final entities = await dir.list().toList();
        final downloads = <FileSystemEntity>[];
        for (final e in entities) {
          if (e is File && p.basename(e.path).startsWith('wallkraft-')) {
            downloads.add(e);
          }
        }
        downloads.sort((a, b) {
          final statA = a.statSync();
          final statB = b.statSync();
          return statB.modified.compareTo(statA.modified);
        });
        if (mounted) setState(() => _files = downloads);
      } else {
        if (mounted) setState(() => _files = []);
      }
    } catch (_) {
      if (mounted) setState(() => _files = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFile(FileSystemEntity entity) async {
    try {
      await entity.delete();
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
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: AppTheme.secondaryLabel,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off,
                size: 48, color: AppTheme.tertiaryLabel),
            const SizedBox(height: AppTheme.spacing12),
            const Text(
              'No downloads',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.label,
              ),
            ),
            const SizedBox(height: AppTheme.spacing4),
            const Text(
              'Download wallpapers to see them here',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.secondaryLabel,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextButton(
              onPressed: widget.onBrowseTap,
              child: const Text('Browse Wallpapers'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDownloads,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
        itemCount: _files.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final entity = _files[index];
          final name = p.basename(entity.path);
          final stat = entity.statSync();
          return Dismissible(
            key: ValueKey(entity.path),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppTheme.spacing20),
              color: Colors.redAccent,
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            onDismissed: (_) => _deleteFile(entity),
            child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(entity.path),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppTheme.tertiarySystemBackground,
                  child: const Icon(Icons.broken_image,
                      color: AppTheme.tertiaryLabel),
                ),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(fontSize: 15, color: AppTheme.label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _formatSize(stat.size),
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.secondaryLabel),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.secondaryLabel),
              tooltip: 'Delete',
              onPressed: () => _deleteFile(entity),
            ),
          ),
          );
        },
      ),
    );
  }
}
