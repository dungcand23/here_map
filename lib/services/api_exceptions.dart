/// Base exception cho các call API.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;

  const ApiException(
    this.message, {
    this.statusCode,
    this.endpoint,
  });

  @override
  String toString() => 'ApiException(message: $message, statusCode: $statusCode, endpoint: $endpoint)';
}

/// Thiếu HERE API key (do chưa set --dart-define).
class MissingApiKeyException extends ApiException {
  const MissingApiKeyException()
      : super('Thiếu HERE API key. Hãy chạy app với --dart-define=HERE_API_KEY=...');
}
