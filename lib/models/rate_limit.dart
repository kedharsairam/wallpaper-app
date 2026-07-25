/// Tracks Wallhaven API rate limit state.
///
/// Wallhaven allows ~45 requests/hour without an API key.
/// This singleton tracks remaining requests and reset time
/// so the UI can warn the user before they hit the limit.
class RateLimitState {
  RateLimitState._();
  static final _instance = RateLimitState._();
  static RateLimitState get instance => _instance;

  int _remaining = 45;
  int _resetEpoch = 0;

  int get remaining => _remaining;
  int get resetEpoch => _resetEpoch;
  bool get isLimited => _remaining <= 0;

  /// Update from API response headers.
  void update(int remaining, int resetEpoch) {
    _remaining = remaining;
    _resetEpoch = resetEpoch;
  }

  /// Decrement remaining (for optimistic tracking when headers aren't parsed).
  void consume() {
    if (_remaining > 0) _remaining--;
  }

  String get resetTimeFormatted {
    if (_resetEpoch == 0) return '';
    final reset = DateTime.fromMillisecondsSinceEpoch(_resetEpoch * 1000);
    final now = DateTime.now();
    final diff = reset.difference(now);
    if (diff.isNegative) return 'any moment';
    if (diff.inMinutes >= 60) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m ${diff.inSeconds % 60}s';
    }
    return '${diff.inSeconds}s';
  }
}
