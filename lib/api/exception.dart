class WallhavenException implements Exception {
  final String message;
  const WallhavenException(this.message);

  @override
  String toString() => message;
}
