import '../models/rate_limit.dart';

/// Base exception for all API errors.
class WallpaperApiException implements Exception {
  final String message;
  const WallpaperApiException(this.message);

  @override
  String toString() => message;
}

/// Thrown when a request was deliberately cancelled (e.g., new search starts).
class CancelledException extends WallpaperApiException {
  const CancelledException() : super('Request cancelled');
}

/// Specific exception for HTTP 429 rate limit responses.
class RateLimitExceededException extends WallpaperApiException {
  RateLimitExceededException()
      : super(_buildMessage());

  static String _buildMessage() {
    final reset = RateLimitState.instance.resetTimeFormatted;
    if (reset.isNotEmpty) {
      return 'Rate limit reached. Resets in $reset.';
    }
    return 'Rate limit reached. Try again later.';
  }
}
