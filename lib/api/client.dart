import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallpaper.dart';
import '../models/rate_limit.dart';
import 'exception.dart';

/// Wallhaven API v1 client.
///
/// Automatically tracks rate limit via response headers.
/// Throws [RateLimitExceededException] when the limit is reached.
class WallhavenApi {
  static const _baseUrl = 'https://wallhaven.cc/api/v1';
  static const _timeout = Duration(seconds: 15);

  const WallhavenApi();

  /// Search wallpapers. Returns paginated results.
  Future<WallhavenResponse> search({
    String? query,
    String categories = '111',
    String sorting = 'toplist',
    String order = 'desc',
    String? topRange,
    int page = 1,
  }) async {
    _checkRateLimit();

    final params = <String, String>{
      'categories': categories,
      'purity': '100',
      'sorting': sorting,
      'order': order,
      'page': page.toString(),
    };

    if (query != null && query.isNotEmpty) params['q'] = query;
    if (topRange != null) params['topRange'] = topRange;

    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: params);

    try {
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      _parseRateLimit(response);
      RateLimitState.instance.consume();

      if (response.statusCode == 200) {
        final decoded = _decodeJson(response.body);
        if (decoded is Map<String, dynamic>) {
          return WallhavenResponse.fromJson(decoded);
        }
        throw const WallhavenException('Unexpected API response format');
      }

      if (response.statusCode == 429) {
        throw RateLimitExceededException();
      }

      throw WallhavenException('API error: ${response.statusCode}');
    } on WallhavenException {
      rethrow;
    } on TimeoutException {
      throw const WallhavenException('Request timed out. Check your connection.');
    } on http.ClientException catch (e) {
      throw WallhavenException('Network error: ${e.message}');
    } catch (e) {
      throw WallhavenException('Request failed: $e');
    }
  }

  /// Fetch a single wallpaper by ID.
  Future<Wallpaper?> wallpaper(String id) async {
    _checkRateLimit();

    final uri = Uri.parse('$_baseUrl/w/$id');

    try {
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      _parseRateLimit(response);
      RateLimitState.instance.consume();

      if (response.statusCode == 200) {
        final decoded = _decodeJson(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];
          if (data is Map<String, dynamic>) {
            return Wallpaper.fromJson(data);
          }
        }
        throw const WallhavenException('Unexpected API response format');
      }

      if (response.statusCode == 429) {
        throw RateLimitExceededException();
      }

      throw WallhavenException('API error: ${response.statusCode}');
    } on WallhavenException {
      rethrow;
    } on TimeoutException {
      throw const WallhavenException('Request timed out. Check your connection.');
    } on http.ClientException catch (e) {
      throw WallhavenException('Network error: ${e.message}');
    } catch (e) {
      throw WallhavenException('Request failed: $e');
    }
  }

  void _checkRateLimit() {
    if (RateLimitState.instance.isLimited) {
      throw RateLimitExceededException();
    }
  }

  void _parseRateLimit(http.Response response) {
    final remaining = response.headers['x-ratelimit-remaining'];
    final reset = response.headers['x-ratelimit-reset'];
    if (remaining != null && reset != null) {
      RateLimitState.instance.update(
        int.tryParse(remaining) ?? 45,
        int.tryParse(reset) ?? 0,
      );
    }
  }

  dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      throw const WallhavenException('Invalid API response');
    }
  }
}
