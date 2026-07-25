import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallpaper.dart';
import 'exception.dart';

class WallhavenApi {
  static const _baseUrl = 'https://wallhaven.cc/api/v1';
  static const _timeout = Duration(seconds: 15);

  const WallhavenApi();

  Future<WallhavenResponse> search({
    String? query,
    String categories = '111',
    String sorting = 'toplist',
    String order = 'desc',
    String? topRange,
    int page = 1,
  }) async {
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

      if (response.statusCode == 200) {
        final decoded = _decodeJson(response.body);
        if (decoded is Map<String, dynamic>) {
          return WallhavenResponse.fromJson(decoded);
        }
        throw const WallhavenException('Unexpected API response format');
      }

      if (response.statusCode == 429) {
        throw const WallhavenException('Rate limited. Try again later.');
      }

      throw WallhavenException('API error: ${response.statusCode}');
    } on WallhavenException {
      rethrow;
    } on http.ClientException catch (e) {
      throw WallhavenException('Network error: ${e.message}');
    } catch (e) {
      throw WallhavenException('Request failed: $e');
    }
  }

  Future<Wallpaper?> wallpaper(String id) async {
    final uri = Uri.parse('$_baseUrl/w/$id');

    try {
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = _decodeJson(response.body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];
          if (data is Map<String, dynamic>) {
            return Wallpaper.fromJson(data);
          }
        }
      }

      return null;
    } on WallhavenException {
      rethrow;
    } on http.ClientException catch (e) {
      throw WallhavenException('Network error: ${e.message}');
    } catch (e) {
      throw WallhavenException('Request failed: $e');
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
