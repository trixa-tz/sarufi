/// Exceptions thrown by the Sarufi SDK.
///
/// Every failed request surfaces as a [SarufiException] (or one of its
/// subtypes). Because the base type is `sealed`, you can exhaustively handle
/// every case with a `switch`:
///
/// ```dart
/// try {
///   await sarufi.getBot(42);
/// } on SarufiException catch (e) {
///   final reason = switch (e) {
///     SarufiAuthException() => 'Check your API key',
///     SarufiNotFoundException() => 'That bot does not exist',
///     SarufiValidationException() => 'Bad request: ${e.message}',
///     SarufiNetworkException() => 'No connection',
///     SarufiServerException() => 'Sarufi is having a bad day',
///     SarufiApiException() => e.message,
///   };
///   print(reason);
/// }
/// ```
library;

/// Base type for every error raised by the SDK.
sealed class SarufiException implements Exception {
  SarufiException(this.message, {this.statusCode, this.body});

  /// Human-readable description of what went wrong.
  final String message;

  /// The HTTP status code, when the failure came from an HTTP response.
  final int? statusCode;

  /// The decoded response body (usually a `Map`), when available.
  final Object? body;

  /// Builds the most specific [SarufiException] subtype for a status code.
  factory SarufiException.fromResponse(int statusCode, Object? body) {
    final message =
        _extractMessage(body) ?? 'Request failed with status $statusCode';
    return switch (statusCode) {
      400 ||
      422 =>
        SarufiValidationException(message, statusCode: statusCode, body: body),
      401 ||
      403 =>
        SarufiAuthException(message, statusCode: statusCode, body: body),
      404 =>
        SarufiNotFoundException(message, statusCode: statusCode, body: body),
      >= 500 =>
        SarufiServerException(message, statusCode: statusCode, body: body),
      _ => SarufiApiException(message, statusCode: statusCode, body: body),
    };
  }

  static String? _extractMessage(Object? body) {
    if (body is Map) {
      for (final key in const ['message', 'detail', 'error', 'errors']) {
        final value = body[key];
        if (value != null) return value is String ? value : value.toString();
      }
    }
    if (body is String && body.isNotEmpty) return body;
    return null;
  }

  @override
  String toString() {
    final code = statusCode != null ? ' (status $statusCode)' : '';
    return '$runtimeType: $message$code';
  }
}

/// A generic API error that does not map to a more specific subtype.
final class SarufiApiException extends SarufiException {
  SarufiApiException(super.message, {super.statusCode, super.body});
}

/// The request was rejected because it was malformed or failed validation
/// (HTTP 400 / 422).
final class SarufiValidationException extends SarufiException {
  SarufiValidationException(super.message, {super.statusCode, super.body});
}

/// Authentication or authorization failed (HTTP 401 / 403) - usually a missing
/// or invalid API key.
final class SarufiAuthException extends SarufiException {
  SarufiAuthException(super.message, {super.statusCode, super.body});
}

/// The requested resource does not exist (HTTP 404).
final class SarufiNotFoundException extends SarufiException {
  SarufiNotFoundException(super.message, {super.statusCode, super.body});
}

/// Sarufi returned a server-side error (HTTP 5xx).
final class SarufiServerException extends SarufiException {
  SarufiServerException(super.message, {super.statusCode, super.body});
}

/// The request never completed - a timeout, DNS failure, dropped connection or
/// other transport-level problem. Has no [statusCode].
final class SarufiNetworkException extends SarufiException {
  SarufiNetworkException(super.message, {this.uri, super.body});

  /// The endpoint the SDK was trying to reach.
  final Uri? uri;

  @override
  String toString() =>
      'SarufiNetworkException: $message${uri != null ? ' ($uri)' : ''}';
}
