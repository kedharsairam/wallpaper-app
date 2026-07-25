import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wallpaper.dart';
import 'exception.dart';

class WallhavenApi {
  static const _baseUrl = 'https://wallhaven.cc/api/v1';

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
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return WallhavenResponse.fromJson(json);
      }

      if (response.statusCode == 429) {
        throw const WallhavenException('Rate limited. Try again later.');
      }

      throw WallhavenException('API error: ${response.statusCode}');
    } on WallhavenException {
      rethrow;
    } catch (e) {
      throw WallhavenException('Connection failed');
    }
  }

  Future<Wallpaper?> wallpaper(String id) async {
    final uri = Uri.parse('$_baseUrl/w/$id');

    try {
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Wallpaper.fromJson(data);
        }
      }

      return null;
    } on WallhavenException {
      rethrow;
    } catch (e) {
      throw WallhavenException('Connection failed');
    }
  }
}
