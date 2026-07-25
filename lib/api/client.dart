import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallpaper.dart';
import '../models/rate_limit.dart';
import 'cancel_token.dart';
import 'exception.dart';

/// Wallpaper API client with rate limit tracking and request cancellation.
///
/// Automatically tracks rate limit via response headers.
/// Throws [RateLimitExceededException] when the limit is reached.
class WallpaperApi {
  static const _baseUrl = 'https://wallhaven.cc/api/v1';
  static const _timeout = Duration(seconds: 15);

  const WallpaperApi();

  /// Search wallpapers. Returns paginated results.
  ///
  /// Pass a [cancelToken] to abort the request mid-flight
  /// (e.g., when the user types a new search query).
  Future<WallpaperResponse> search({
    String? query,
    String categories = '111',
    String sorting = 'toplist',
    String order = 'desc',
    String? topRange,
    int page = 1,
    CancelToken? cancelToken,
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
      final client = http.Client();
      final response = await client
          .getWithCancel(uri,
              headers: {'Accept': 'application/json'}, cancelToken: cancelToken)
          .timeout(_timeout);

      _parseRateLimit(response);
      RateLimitState.instance.consume();

      if (response.statusCode == 200) {
        final decoded = _decodeJson(response.body);
        if (decoded is Map<String, dynamic>) {
          return WallpaperResponse.fromJson(decoded);
        }
        throw const WallpaperApiException('Unexpected API response format');
      }

      if (response.statusCode == 429) {
        throw RateLimitExceededException();
      }

      throw WallpaperApiException('API error: ${response.statusCode}');
    } on WallpaperApiException {
      rethrow;
    } on TimeoutException {
      throw const WallpaperApiException('Request timed out. Check your connection.');
    } on http.ClientException catch (e) {
      // If the cancellation closed the client, we get a ClientException.
      // Map it to a clear CancelledException.
      if (cancelToken?.isCancelled == true) {
        throw const CancelledException();
      }
      throw WallpaperApiException('Network error: ${e.message}');
    } catch (e) {
      throw WallpaperApiException('Request failed: $e');
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
        throw const WallpaperApiException('Unexpected API response format');
      }

      if (response.statusCode == 429) {
        throw RateLimitExceededException();
      }

      throw WallpaperApiException('API error: ${response.statusCode}');
    } on WallpaperApiException {
      rethrow;
    } on TimeoutException {
      throw const WallpaperApiException('Request timed out. Check your connection.');
    } on http.ClientException catch (e) {
      throw WallpaperApiException('Network error: ${e.message}');
    } catch (e) {
      throw WallpaperApiException('Request failed: $e');
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
      throw const WallpaperApiException('Invalid API response');
    }
  }
}
