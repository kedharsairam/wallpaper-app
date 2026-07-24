import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallhaven_wallpaper.dart';

class WallhavenApi {
  static const String _baseUrl = 'https://wallhaven.cc/api/v1';

  // Free API key — get yours at https://wallhaven.cc/settings/account
  // Leave null for public access (SFW only, rate-limited)
  final String? apiKey;

  WallhavenApi({this.apiKey});

  /// Search wallpapers with optional filters.
  ///
  /// [query] - search term
  /// [categories] - '111' = General+Anime+People, '100' = General only, etc.
  /// [purity] - '100' = SFW only, '110' = SFW+Sketchy, '111' = all
  /// [sorting] - 'date_added', 'relevance', 'random', 'views', 'favorites', 'toplist'
  /// [order] - 'desc' or 'asc'
  /// [topRange] - for toplist sorting: '1d', '3d', '1w', '1M', '3M', '6M', '1y'
  /// [atleast] - minimum resolution, e.g. '1920x1080'
  /// [page] - page number
  Future<WallhavenResponse> search({
    String? query,
    String categories = '111',
    String purity = '100',
    String sorting = 'toplist',
    String order = 'desc',
    String? topRange,
    String? atleast,
    int page = 1,
  }) async {
    final params = <String, String>{
      'categories': categories,
      'purity': purity,
      'sorting': sorting,
      'order': order,
      'page': page.toString(),
    };

    if (query != null && query.isNotEmpty) params['q'] = query;
    if (topRange != null) params['topRange'] = topRange;
    if (atleast != null) params['atleast'] = atleast;
    if (apiKey != null) params['apikey'] = apiKey!;

    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: params);

    try {
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return WallhavenResponse.fromJson(json);
      } else if (response.statusCode == 429) {
        throw WallhavenException('Rate limited. Please add an API key or wait.');
      } else {
        throw WallhavenException(
          'API error ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on WallhavenException {
      rethrow;
    } catch (e) {
      throw WallhavenException('Network error: $e');
    }
  }

  /// Get a single wallpaper's full details by ID.
  Future<WallhavenWallpaper?> getWallpaper(String id) async {
    final params = <String, String>{};
    if (apiKey != null) params['apikey'] = apiKey!;

    final uri = Uri.parse('$_baseUrl/w/$id').replace(queryParameters: params);

    try {
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          return WallhavenWallpaper.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      throw WallhavenException('Failed to load wallpaper details: $e');
    }
  }
}

class WallhavenException implements Exception {
  final String message;
  WallhavenException(this.message);

  @override
  String toString() => message;
}
