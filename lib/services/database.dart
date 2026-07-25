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

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    _db = await _open();
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
        if (oldVersion < 2) {
          // Future: ALTER TABLE favorites ADD COLUMN note TEXT;
        }
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
    final rows = await db.query('favorites', orderBy: 'saved_at DESC');
    return rows.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      return Wallpaper.fromJson(data);
    }).toList();
  }

  static Future<bool> isFavorite(String id) async {
    final db = await instance;
    final result = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  static Future<void> addFavorite(Wallpaper wallpaper) async {
    final db = await instance;
    await db.insert(
      'favorites',
      {
        'id': wallpaper.id,
        'data': jsonEncode(_wallpaperToMap(wallpaper)),
        'saved_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> removeFavorite(String id) async {
    final db = await instance;
    await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
  }

  // ── Downloads ─────────────────────────────────────────────────────

  static Future<void> recordDownload(String id, String path) async {
    final db = await instance;
    await db.insert(
      'downloads',
      {
        'id': id,
        'path': path,
        'saved_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getDownloads() async {
    final db = await instance;
    return db.query('downloads', orderBy: 'saved_at DESC');
  }

  static Future<void> removeDownload(String id) async {
    final db = await instance;
    await db.delete('downloads', where: 'id = ?', whereArgs: [id]);
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
