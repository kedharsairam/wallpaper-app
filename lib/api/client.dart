import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/wallpaper.dart';
import '../models/rate_limit.dart';
import '../services/api_key_service.dart';
import 'cancel_token.dart';
import 'exception.dart';

/// Wallpaper API client with rate limit tracking and request cancellation.
///
/// Automatically tracks rate limit via response headers.
/// Reads the API key from [ApiKeyService] on each request so that
/// key changes (via Settings) take effect immediately without a restart.
/// Throws [RateLimitExceededException] when the limit is reached.
class WallpaperApi {
  static const _baseUrl = 'https://wallhaven.cc/api/v1';
  static const _timeout = Duration(seconds: 15);

  const WallpaperApi();

  /// Builds request headers, including the API key if one is stored.
  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{'Accept': 'application/json'};
    final apiKey = await ApiKeyService.load();
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['X-API-Key'] = apiKey;
    }
    return headers;
  }

  /// Search wallpapers. Returns paginated results.
  ///
  /// Pass a [cancelToken] to abort the request mid-flight
  /// (e.g., when the user types a new search query).
  /// [purity] is a bitmask: '100'=SFW, '110'=SFW+Sketchy, '111'=all.
  Future<WallpaperResponse> search({
    String? query,
    String categories = '111',
    String purity = '100',
    String sorting = 'date_added',
    String order = 'desc',
    String? topRange,
    String? ratios,
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    _checkRateLimit();

    final params = <String, String>{
      'categories': categories,
      'purity': purity,
      'sorting': sorting,
      'order': order,
      'page': page.toString(),
    };

    if (query != null && query.isNotEmpty) params['q'] = query;
    if (topRange != null) params['topRange'] = topRange;
    if (ratios != null && ratios.isNotEmpty) params['ratios'] = ratios;

    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: params);

    try {
      final client = http.Client();
      final headers = await _headers();
      final response = await client
          .getWithCancel(uri, headers: headers, cancelToken: cancelToken)
          .timeout(_timeout);

      // Rate limit is authoritative from the server — no local consume().
      _parseRateLimit(response);

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
      if (cancelToken?.isCancelled == true) {
        throw const CancelledException();
      }
      throw WallpaperApiException('Network error: ${e.message}');
    } catch (e) {
      throw WallpaperApiException('Request failed: $e');
    }
  }

  /// Fetch a single wallpaper by ID. Supports cancellation.
  Future<Wallpaper?> wallpaper(String id, {CancelToken? cancelToken}) async {
    _checkRateLimit();

    final uri = Uri.parse('$_baseUrl/w/$id');

    try {
      final client = http.Client();
      final headers = await _headers();
      final response = await client
          .getWithCancel(uri, headers: headers, cancelToken: cancelToken)
          .timeout(_timeout);

      _parseRateLimit(response);

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
      if (cancelToken?.isCancelled == true) {
        throw const CancelledException();
      }
      throw WallpaperApiException('Network error: ${e.message}');
    } catch (e) {
      throw WallpaperApiException('Request failed: $e');
    }
  }

  /// Fetch search autocomplete suggestions for [query].
  ///
  /// Returns a list of suggested tag strings from the Wallhaven API.
  /// On failure or rate-limit, returns an empty list (non-critical).
  Future<List<String>> suggestions(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse('$_baseUrl/search/suggestions')
          .replace(queryParameters: {'q': query.trim()});
      final client = http.Client();
      final headers = await _headers();
      final response = await client
          .getWithCancel(uri, headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = _decodeJson(response.body);
        if (decoded is Map<String, dynamic>) {
          final suggestions = decoded['suggestions'];
          if (suggestions is List) {
            return suggestions.cast<String>();
          }
        }
      }
    } catch (e) {
      debugPrint('[Suggestions] Failed: $e');
    }
    return [];
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
    } catch (e) {
      throw WallpaperApiException('Invalid API response: $e');
    }
  }
}
