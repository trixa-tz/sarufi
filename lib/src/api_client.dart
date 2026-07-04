import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'exceptions.dart';

/// Thin internal wrapper around [http.Client] that centralises headers, JSON
/// encoding/decoding, timeouts and error mapping.
///
/// This class is not part of the public API - consumers talk to `Sarufi`.
class ApiClient {
  ApiClient({
    required this.apiKey,
    required this.baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 120),
    Logger? logger,
  })  : _http = httpClient ?? http.Client(),
        _ownsClient = httpClient == null,
        _log = logger ?? Logger('Sarufi');

  /// Bearer token used to authenticate every request.
  final String apiKey;

  /// Root URL every request is resolved against.
  final String baseUrl;

  /// How long to wait before aborting a request.
  final Duration timeout;

  final http.Client _http;
  final bool _ownsClient;
  final Logger _log;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Uri _uri(String path) {
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse('$base$path');
  }

  Future<Object?> get(String path) => _send('GET', path);

  Future<Object?> post(String path, Map<String, dynamic> body) =>
      _send('POST', path, body);

  Future<Object?> put(String path, Map<String, dynamic> body) =>
      _send('PUT', path, body);

  Future<Object?> delete(String path) => _send('DELETE', path);

  Future<Object?> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final uri = _uri(path);
    final encoded = body == null ? null : jsonEncode(body);
    _log.fine('$method $uri');

    http.Response response;
    try {
      final future = switch (method) {
        'GET' => _http.get(uri, headers: _headers),
        'POST' => _http.post(uri, headers: _headers, body: encoded),
        'PUT' => _http.put(uri, headers: _headers, body: encoded),
        'DELETE' => _http.delete(uri, headers: _headers),
        _ => throw ArgumentError('Unsupported method: $method'),
      };
      response = await future.timeout(timeout);
    } on TimeoutException {
      throw SarufiNetworkException(
        'Request timed out after ${timeout.inSeconds}s',
        uri: uri,
      );
    } on http.ClientException catch (e) {
      throw SarufiNetworkException(e.message, uri: uri);
    } on SarufiException {
      rethrow;
    } catch (e) {
      throw SarufiNetworkException('Network error: $e', uri: uri);
    }

    return _handle(response);
  }

  Object? _handle(http.Response response) {
    final code = response.statusCode;
    final body = _decode(response.body);
    if (code >= 200 && code < 300) return body;
    _log.warning('Request failed ($code): $body');
    throw SarufiException.fromResponse(code, body);
  }

  Object? _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      // Non-JSON payload (e.g. an HTML error page) - return it verbatim.
      return body;
    }
  }

  /// Releases the underlying HTTP client, but only if this instance created it.
  void close() {
    if (_ownsClient) _http.close();
  }
}
