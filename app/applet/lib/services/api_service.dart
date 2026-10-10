import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String keyBaseUrl = 'sp_api_base_url';
  static const String keyAccessToken = 'sp_access_token';
  static const String keyRefreshToken = 'sp_refresh_token';
  static const String keyEsp32Url = 'sp_esp32_cam_url';

  // Configurable default via build environment or standard emulator loopback
  // Usage: flutter run --dart-define=BASE_URL=http://YOUR_HOST:8000
  static const String configuredBaseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const String defaultBaseUrl = configuredBaseUrl;
  static const String defaultEsp32Url = 'http://192.168.1.100:81/stream';

  String _baseUrl = defaultBaseUrl;
  String? _accessToken;
  String? _refreshToken;
  String _esp32Url = defaultEsp32Url;

  String get baseUrl => _baseUrl;
  String get esp32Url => _esp32Url;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;
  String? get token => _accessToken;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(keyBaseUrl) ?? defaultBaseUrl;
    _accessToken = prefs.getString(keyAccessToken);
    _refreshToken = prefs.getString(keyRefreshToken);
    _esp32Url = prefs.getString(keyEsp32Url) ?? defaultEsp32Url;
  }

  Future<void> setBaseUrl(String url) async {
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    _baseUrl = cleanUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyBaseUrl, _baseUrl);
  }

  Future<void> setEsp32Url(String url) async {
    _esp32Url = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyEsp32Url, _esp32Url);
  }

  Future<void> saveTokens({required String access, String? refresh}) async {
    _accessToken = access;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyAccessToken, access);
    if (refresh != null) {
      _refreshToken = refresh;
      await prefs.setString(keyRefreshToken, refresh);
    }
  }

  Future<void> clearAuth() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyAccessToken);
    await prefs.remove(keyRefreshToken);
  }

  Map<String, String> _headers({bool requiresAuth = true}) {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth && _accessToken != null) {
      map['Authorization'] = 'Bearer $_accessToken';
    }
    return map;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    String fullUrl = '$_baseUrl${path.startsWith('/') ? path : '/$path'}';
    final uri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams = queryParameters.map((key, value) => MapEntry(key, value.toString()));
      return uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  String _formatNetworkError(dynamic e) {
    if (e is SocketException) {
      return 'Failed to connect to $_baseUrl. The backend server is not running or unreachable from this network environment. Verify that the Django server is started and accessible at this address.';
    } else if (e is HttpException) {
      return 'HTTP error while communicating with $_baseUrl: ${e.message}';
    } else if (e is FormatException) {
      return 'Malformed response or URL address: $_baseUrl';
    }
    final str = e.toString();
    if (str.contains('Failed host lookup') || str.contains('Connection refused') || str.contains('Failed to connect')) {
      return 'Failed to connect to $_baseUrl. Server is offline or unreachable.';
    }
    return 'Network error: $str';
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams, bool requiresAuth = true}) async {
    try {
      final uri = _buildUri(path, queryParams);
      final response = await http
          .get(uri, headers: _headers(requiresAuth: requiresAuth))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw ApiException(
              'Connection to $_baseUrl timed out after 10s. The server may be unresponsive.',
            ),
          );
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_formatNetworkError(e));
    }
  }

  Future<dynamic> post(String path, {dynamic body, bool requiresAuth = true}) async {
    try {
      final uri = _buildUri(path);
      final response = await http
          .post(
            uri,
            headers: _headers(requiresAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw ApiException(
              'Connection to $_baseUrl timed out after 15s. The server may be unresponsive.',
            ),
          );
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_formatNetworkError(e));
    }
  }

  Future<dynamic> put(String path, {dynamic body, bool requiresAuth = true}) async {
    try {
      final uri = _buildUri(path);
      final response = await http
          .put(
            uri,
            headers: _headers(requiresAuth: requiresAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw ApiException(
              'Connection to $_baseUrl timed out after 15s. The server may be unresponsive.',
            ),
          );
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_formatNetworkError(e));
    }
  }

  Future<dynamic> delete(String path, {bool requiresAuth = true}) async {
    try {
      final uri = _buildUri(path);
      final response = await http
          .delete(uri, headers: _headers(requiresAuth: requiresAuth))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw ApiException(
              'Connection to $_baseUrl timed out after 10s. The server may be unresponsive.',
            ),
          );
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(_formatNetworkError(e));
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    String errorMessage = 'Request failed (${response.statusCode})';
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('error')) {
        errorMessage = decoded['error'].toString();
      } else if (decoded.containsKey('detail')) {
        errorMessage = decoded['detail'].toString();
      } else if (decoded.containsKey('message')) {
        errorMessage = decoded['message'].toString();
      } else {
        // Collect field errors
        final errors = decoded.entries.map((e) => '${e.key}: ${e.value}').join(', ');
        if (errors.isNotEmpty) errorMessage = errors;
      }
    }

    throw ApiException(errorMessage, statusCode: response.statusCode, data: decoded);
  }
}
