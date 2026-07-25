import '../models/rate_limit.dart';

/// Base exception for all Wallhaven API errors.
class WallhavenException implements Exception {
  final String message;
  const WallhavenException(this.message);

  @override
  String toString() => message;
}

/// Specific exception for HTTP 429 rate limit responses.
class RateLimitExceededException extends WallhavenException {
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
