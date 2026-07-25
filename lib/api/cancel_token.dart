import 'package:http/http.dart' as http;

/// A token that can cancel an HTTP request by closing its client.
///
/// Usage:
/// ```dart
/// final token = CancelToken();
/// api.search(..., cancelToken: token);
/// token.cancel(); // aborts the in-flight request
/// ```
class CancelToken {
  http.Client? _client;
  bool _isCancelled = false;

  /// Whether the request has been cancelled.
  bool get isCancelled => _isCancelled;

  /// Registers an HTTP client to be closed on cancel.
  void _attach(http.Client client) {
    _client = client;
  }

  /// Cancels the in-flight request, if any.
  void cancel() {
    _isCancelled = true;
    _client?.close();
    _client = null;
  }
}

/// Extensions on [http.Client] to attach a [CancelToken].
extension CancelTokenX on http.Client {
  /// Performs a GET request that can be cancelled via [cancelToken].
  Future<http.Response> getWithCancel(
    Uri uri, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) {
    cancelToken?._attach(this);
    return get(uri, headers: headers);
  }
}
