import 'package:wallkraft/models/wallpaper.dart';

/// Factory helpers for creating test data.
class TestData {
  static Wallpaper wallpaper({
    String id = 'test-1',
    String url = 'https://example.com/wp',
    String path = 'https://example.com/img.jpg',
    String thumb = 'https://example.com/thumb.jpg',
    int dimensionX = 1920,
    int dimensionY = 1080,
    String ratio = '16:9',
    int fileSize = 512000,
    int favorites = 99,
    String category = 'general',
  }) {
    return Wallpaper.fromJson({
      'id': id,
      'url': url,
      'path': path,
      'thumbs': {
        'small': thumb,
        'large': thumb,
        'original': thumb,
      },
      'dimension_x': dimensionX,
      'dimension_y': dimensionY,
      'ratio': ratio,
      'file_size': fileSize,
      'favorites': favorites,
      'category': category,
      'tags': [],
    });
  }

  static WallpaperResponse response({
    int total = 24,
    int perPage = 24,
    int currentPage = 1,
    int lastPage = 1,
    List<Wallpaper>? data,
  }) {
    return WallpaperResponse.fromJson({
      'data': (data ?? List.generate(
        total > 24 ? 24 : total,
        (i) => wallpaper(id: 'test-$i'),
      )).map((w) => {
        'id': w.id,
        'url': w.url,
        'path': w.path,
        'thumbs': {'small': w.thumbnail},
        'dimension_x': w.dimensionX,
        'dimension_y': w.dimensionY,
        'ratio': w.ratio,
        'file_size': w.fileSize,
        'favorites': w.favorites,
        'category': w.category,
        'tags': w.tags.map((t) => {'id': t.id, 'name': t.name}).toList(),
      }).toList(),
      'meta': {
        'current_page': currentPage,
        'last_page': lastPage,
        'per_page': perPage,
        'total': total,
      },
    });
  }
}
