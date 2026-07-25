class Wallpaper {
  final String id;
  final String url;
  final String path;
  final String thumbnail;
  final String? thumbnailLarge;
  final int dimensionX;
  final int dimensionY;
  final String ratio;
  final int fileSize;
  final int favorites;
  final String category;
  final List<Tag> tags;

  Wallpaper({
    required this.id,
    required this.url,
    required this.path,
    required this.thumbnail,
    this.thumbnailLarge,
    required this.dimensionX,
    required this.dimensionY,
    required this.ratio,
    required this.fileSize,
    required this.favorites,
    required this.category,
    required this.tags,
  });

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    final thumbs = _mapOrEmpty(json['thumbs']);
    final rawTags = json['tags'];
    final tagsList = rawTags is List
        ? rawTags
            .whereType<Map<String, dynamic>>()
            .map((e) => Tag.fromJson(e))
            .toList()
        : <Tag>[];

    return Wallpaper(
      id: _string(json['id']),
      url: _string(json['url']),
      path: _string(json['path']),
      thumbnail: _string(thumbs['small']),
      thumbnailLarge: _nullableString(thumbs['large']),
      dimensionX: _dim(json['dimension_x'], 1920),
      dimensionY: _dim(json['dimension_y'], 1080),
      ratio: _string(json['ratio'], '16:9'),
      fileSize: _int(json['file_size']),
      favorites: _int(json['favorites']),
      category: _string(json['category'], 'general'),
      tags: tagsList,
    );
  }

  String get resolution => '${dimensionX}x$dimensionY';

  String get fileSizeFormatted {
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String _string(dynamic v, [String fallback = '']) {
    if (v is String) return v;
    if (v is int || v is double) return v.toString();
    return fallback;
  }

  static String? _nullableString(dynamic v) {
    if (v is String) return v;
    return null;
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static int _dim(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? fallback;
    if (v is double) return v.toInt();
    return fallback;
  }

  static Map<String, dynamic> _mapOrEmpty(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    return {};
  }
}

class Tag {
  final int id;
  final String name;

  Tag({required this.id, required this.name});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: _int(json['id']),
      name: _string(json['name']),
    );
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static String _string(dynamic v, [String fallback = '']) {
    if (v is String) return v;
    if (v is int || v is double) return v.toString();
    return fallback;
  }
}

class WallhavenResponse {
  final List<Wallpaper> data;
  final WallhavenMeta meta;

  WallhavenResponse({required this.data, required this.meta});

  factory WallhavenResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final dataList = rawData is List
        ? rawData
            .whereType<Map<String, dynamic>>()
            .map((e) => Wallpaper.fromJson(e))
            .toList()
        : <Wallpaper>[];

    final rawMeta = json['meta'];
    final metaJson = rawMeta is Map<String, dynamic> ? rawMeta : <String, dynamic>{};
    return WallhavenResponse(
      data: dataList,
      meta: WallhavenMeta.fromJson(metaJson),
    );
  }
}

class WallhavenMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  WallhavenMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory WallhavenMeta.fromJson(Map<String, dynamic> json) {
    return WallhavenMeta(
      currentPage: _int(json['current_page'], 1),
      lastPage: _int(json['last_page'], 1),
      perPage: _int(json['per_page'], 24),
      total: _int(json['total'], 0),
    );
  }

  static int _int(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }
}
