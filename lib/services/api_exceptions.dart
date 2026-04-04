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

/// Thiếu HERE API key.
class MissingApiKeyException extends ApiException {
  const MissingApiKeyException()
      : super(
          'Thiếu HERE API key. Hãy chạy bằng env.dev.json hoặc cấu hình HERE_API_KEY trong AppConfig.',
        );
}
