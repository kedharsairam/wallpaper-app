import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallkraft/api/cancel_token.dart';
import 'package:wallkraft/models/category.dart';
import 'package:wallkraft/models/wallpaper.dart';

void main() {
  test('CancelToken can be cancelled', () {
    final token = CancelToken();
    expect(token.isCancelled, false);
    token.cancel();
    expect(token.isCancelled, true);
    // Cancelling twice should not throw
    token.cancel();
    expect(token.isCancelled, true);
  });

  test('Category enum parses API strings correctly', () {
    expect(Category.fromApi('general'), Category.general);
    expect(Category.fromApi('anime'), Category.anime);
    expect(Category.fromApi('people'), Category.people);
    expect(Category.fromApi('unknown'), Category.general);
  });

  test('SortOption enum parses API strings correctly', () {
    expect(SortOption.fromApi('date_added'), SortOption.dateAdded);
    expect(SortOption.fromApi('relevance'), SortOption.relevance);
    expect(SortOption.fromApi('random'), SortOption.random);
    expect(SortOption.fromApi('views'), SortOption.mostViewed);
    expect(SortOption.fromApi('favorites'), SortOption.mostFavorited);
    expect(SortOption.fromApi('toplist'), SortOption.topList);
    expect(SortOption.fromApi('invalid'), SortOption.dateAdded);
  });

  test('WallpaperResponse fromJson handles empty data gracefully', () {
    final result = WallpaperResponse.fromJson({
      'data': [],
      'meta': {'current_page': 1, 'last_page': 0, 'per_page': 24, 'total': 0},
    });
    expect(result.data, isEmpty);
    expect(result.meta.total, 0);
  });

  test('Wallpaper fromJson handles null fields gracefully', () {
    final wp = Wallpaper.fromJson({
      'id': '123',
      'url': null,
      'path': null,
      'thumbs': null,
      'tags': null,
    });
    expect(wp.id, '123');
    expect(wp.url, '');
    expect(wp.thumbnail, '');
    expect(wp.tags, isEmpty);
  });

  test('Wallpaper fromJson handles valid fields', () {
    final wp = Wallpaper.fromJson({
      'id': 'test-1',
      'url': 'https://example.com/wallpaper',
      'path': 'https://example.com/image.jpg',
      'thumbs': {
        'small': 'https://example.com/thumb.jpg',
        'large': 'https://example.com/large.jpg',
        'original': 'https://example.com/original.jpg',
      },
      'dimension_x': 3840,
      'dimension_y': 2160,
      'ratio': '16:9',
      'file_size': 2048576,
      'favorites': 1234,
      'category': 'anime',
      'tags': [
        {'id': 1, 'name': 'landscape'},
        {'id': 2, 'name': 'sunset'},
      ],
    });
    expect(wp.id, 'test-1');
    expect(wp.resolution, '3840x2160');
    expect(wp.thumbnailLarge, 'https://example.com/large.jpg');
    expect(wp.thumbnailOriginal, 'https://example.com/original.jpg');
    expect(wp.fileSizeFormatted, '2.0 MB');
    expect(wp.tags.length, 2);
    expect(wp.tags[0].name, 'landscape');
  });

  test('Tag fromJson works correctly', () {
    final tag = Tag.fromJson({'id': 42, 'name': 'cyberpunk'});
    expect(tag.id, 42);
    expect(tag.name, 'cyberpunk');
  });

  test('WallpaperMeta fromJson handles edge cases', () {
    final meta = WallpaperMeta.fromJson({
      'current_page': '3',
      'last_page': 10.5,
      'per_page': null,
      'total': 250,
    });
    expect(meta.currentPage, 3);
    expect(meta.lastPage, 10);
    expect(meta.perPage, 24);
    expect(meta.total, 250);
  });

  test('WallpaperResponse JSON round-trip', () {
    final json = {
      'data': [
        {
          'id': 'roundtrip-1',
          'url': 'https://a.com/wp',
          'path': 'https://a.com/img.jpg',
          'thumbs': {'small': 'https://a.com/thumb.jpg'},
          'dimension_x': 1920,
          'dimension_y': 1080,
          'ratio': '16:9',
          'file_size': 512000,
          'favorites': 99,
          'category': 'general',
          'tags': [],
        }
      ],
      'meta': {
        'current_page': 1,
        'last_page': 5,
        'per_page': 24,
        'total': 120,
      },
    };
    final response = WallpaperResponse.fromJson(json);
    expect(response.data.length, 1);
    expect(response.data[0].id, 'roundtrip-1');
    expect(response.meta.lastPage, 5);
    expect(response.meta.total, 120);

    // Verify JSON serialization for caching
    final encoded = jsonEncode({
      'data': response.data
          .map((w) => {
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
              })
          .toList(),
    });
    final decoded = jsonDecode(encoded);
    final restored = WallpaperResponse.fromJson({
      'data': decoded['data'],
      'meta': json['meta'],
    });
    expect(restored.data.length, 1);
    expect(restored.data[0].id, 'roundtrip-1');
    // The restored dimension_x/y come as int because jsonEncode/Decode preserves int
    expect(restored.data[0].dimensionX, 1920);
    expect(restored.data[0].dimensionY, 1080);
  });
}
