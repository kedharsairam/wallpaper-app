class WallhavenWallpaper {
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
  final String purity;
  final List<Tag> tags;

  WallhavenWallpaper({
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
    required this.purity,
    required this.tags,
  });

  factory WallhavenWallpaper.fromJson(Map<String, dynamic> json) {
    final thumbs = json['thumbs'] as Map<String, dynamic>? ?? {};
    final tagsList = (json['tags'] as List<dynamic>?)
            ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Wallhaven may return numeric fields as strings through the proxy.
    double toDouble(dynamic v, double fallback) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    // Parse dimensions from the ratio string as a fallback
    // (e.g. "1.78" for 16:9, "0.56" for 9:16).
    double ratioFromString(String ratio) {
      final r = double.tryParse(ratio);
      if (r != null && r > 0) return r;
      return 1.78; // default 16:9
    }

    final dimX = toDouble(json['dimension_x'], 0);
    final dimY = toDouble(json['dimension_y'], 0);
    final ratioStr = json['ratio'] as String? ?? '';

    // If API returned 0 dimensions (string cast failure or missing), use ratio
    if (dimX <= 0 || dimY <= 0) {
      final r = ratioFromString(ratioStr);
      // Assume a typical width and derive height from ratio
      final width = 1920.0;
      final height = width / r;
      return WallhavenWallpaper(
        id: json['id'] as String? ?? '',
        url: json['url'] as String? ?? '',
        path: json['path'] as String? ?? '',
        thumbnail: thumbs['small'] as String? ?? '',
        thumbnailLarge: thumbs['large'] as String?,
        dimensionX: width.toInt(),
        dimensionY: height.toInt(),
        ratio: ratioStr,
        fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
        favorites: (json['favorites'] as num?)?.toInt() ?? 0,
        category: json['category'] as String? ?? 'general',
        purity: json['purity'] as String? ?? 'sfw',
        tags: tagsList,
      );
    }

    return WallhavenWallpaper(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      path: json['path'] as String? ?? '',
      thumbnail: thumbs['small'] as String? ?? '',
      thumbnailLarge: thumbs['large'] as String?,
      dimensionX: dimX.toInt(),
      dimensionY: dimY.toInt(),
      ratio: ratioStr,
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      favorites: (json['favorites'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? 'general',
      purity: json['purity'] as String? ?? 'sfw',
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
  final String? alias;

  Tag({required this.id, required this.name, this.alias});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      alias: json['alias'] as String?,
    );
  }
}

class WallhavenResponse {
  final List<WallhavenWallpaper> data;
  final WallhavenMeta meta;

  WallhavenResponse({required this.data, required this.meta});

  factory WallhavenResponse.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List<dynamic>?)
            ?.map((e) => WallhavenWallpaper.fromJson(e as Map<String, dynamic>))
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
    // Wallhaven returns these as integers, but the Cloudflare proxy
    // sometimes returns them as strings. Handle both.
    int toInt(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    return WallhavenMeta(
      currentPage: toInt(json['current_page'], 1),
      lastPage: toInt(json['last_page'], 1),
      perPage: toInt(json['per_page'], 24),
      total: toInt(json['total'], 0),
    );
  }
}
