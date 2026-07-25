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
    final thumbs = json['thumbs'] as Map<String, dynamic>? ?? {};

    final tagsList = (json['tags'] as List<dynamic>?)
            ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    int dim(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    return Wallpaper(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      path: json['path'] as String? ?? '',
      thumbnail: thumbs['small'] as String? ?? '',
      thumbnailLarge: thumbs['large'] as String?,
      dimensionX: dim(json['dimension_x'], 1920),
      dimensionY: dim(json['dimension_y'], 1080),
      ratio: json['ratio'] as String? ?? '16:9',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      favorites: (json['favorites'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? 'general',
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
}

class Tag {
  final int id;
  final String name;

  Tag({required this.id, required this.name});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

class WallhavenResponse {
  final List<Wallpaper> data;
  final WallhavenMeta meta;

  WallhavenResponse({required this.data, required this.meta});

  factory WallhavenResponse.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List<dynamic>?)
            ?.map((e) => Wallpaper.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final metaJson = json['meta'] as Map<String, dynamic>? ?? {};
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
    int v(dynamic value, int fallback) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    return WallhavenMeta(
      currentPage: v(json['current_page'], 1),
      lastPage: v(json['last_page'], 1),
      perPage: v(json['per_page'], 24),
      total: v(json['total'], 0),
    );
  }
}
