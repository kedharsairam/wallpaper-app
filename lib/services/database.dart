import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/wallpaper.dart';

/// Thread-safe database for favorites and downloads metadata.
///
/// ## Migration strategy
/// When adding new tables or columns:
/// 1. Increment [_version].
/// 2. Add an `if (oldVersion < newVersion)` case in [onUpgrade].
/// 3. Test on a device with the old database.
class WallKraftDatabase {
  static const _version = 1;
  static Database? _db;
  static final _initCompleter = Completer<void>();

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    // Serialize concurrent access via a one-shot completer.
    if (!_initCompleter.isCompleted) {
      _db = await _open();
      _initCompleter.complete();
    } else {
      await _initCompleter.future;
    }
    return _db!;
  }

  static Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'wallkraft.db');
    debugPrint('[DB] Opening database at $path (v$_version)');
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async => _createTables(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        // When adding new migrations, replace the condition below:
        // if (oldVersion < 2 && newVersion >= 2) { ... }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE favorites (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        saved_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE downloads (
        id TEXT PRIMARY KEY,
        path TEXT NOT NULL,
        saved_at INTEGER NOT NULL
      )
    ''');
    debugPrint('[DB] Tables created successfully');
  }

  // ── Favorites ─────────────────────────────────────────────────────

  static Future<List<Wallpaper>> getFavorites() async {
    final db = await instance;
    try {
      final rows = await db.query('favorites', orderBy: 'saved_at DESC');
      return rows.map((row) {
        final raw = row['data'];
        if (raw is! String) return null;
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) return null;
        return Wallpaper.fromJson(decoded);
      }).whereType<Wallpaper>().toList();
    } catch (e) {
      debugPrint('[DB] getFavorites failed: $e');
      return [];
    }
  }

  static Future<bool> isFavorite(String id) async {
    final db = await instance;
    try {
      final result = await db.query(
        'favorites',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('[DB] isFavorite failed: $e');
      return false;
    }
  }

  static Future<void> addFavorite(Wallpaper wallpaper) async {
    final db = await instance;
    try {
      await db.insert(
        'favorites',
        {
          'id': wallpaper.id,
          'data': jsonEncode(_wallpaperToMap(wallpaper)),
          'saved_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[DB] addFavorite failed: $e');
      rethrow;
    }
  }

  static Future<void> removeFavorite(String id) async {
    final db = await instance;
    try {
      await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('[DB] removeFavorite failed: $e');
      rethrow;
    }
  }

  // ── Downloads ─────────────────────────────────────────────────────

  static Future<void> recordDownload(String id, String path) async {
    final db = await instance;
    try {
      await db.insert(
        'downloads',
        {
          'id': id,
          'path': path,
          'saved_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[DB] recordDownload failed: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getDownloads() async {
    final db = await instance;
    try {
      return db.query('downloads', orderBy: 'saved_at DESC');
    } catch (e) {
      debugPrint('[DB] getDownloads failed: $e');
      return [];
    }
  }

  static Future<void> removeDownload(String id) async {
    final db = await instance;
    try {
      await db.delete('downloads', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('[DB] removeDownload failed: $e');
      rethrow;
    }
  }

  // ── Serialization ─────────────────────────────────────────────────

  static Map<String, dynamic> _wallpaperToMap(Wallpaper w) => {
        'id': w.id,
        'url': w.url,
        'path': w.path,
        'thumbs': {
          'small': w.thumbnail,
          'large': w.thumbnailLarge,
          'original': w.thumbnailOriginal,
        },
        'dimension_x': w.dimensionX,
        'dimension_y': w.dimensionY,
        'ratio': w.ratio,
        'file_size': w.fileSize,
        'favorites': w.favorites,
        'category': w.category,
        'tags': w.tags.map((t) => {'id': t.id, 'name': t.name}).toList(),
      };
}
