import '../models/auth_response.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _api = ApiService();
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _api.isAuthenticated;

  Future<AuthResponse> login(String username, String password) async {
    final response = await _api.post('/api/auth/login/', body: {
      'username': username.trim(),
      'password': password,
    }, requiresAuth: false);

    final authResponse = AuthResponse.fromJson(response as Map<String, dynamic>);
    if (authResponse.access != null) {
      await _api.saveTokens(
        access: authResponse.access!,
        refresh: authResponse.refresh,
      );
      _currentUser = authResponse.user;
    }
    return authResponse;
  }

  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    String? shopName,
    String? phoneNumber,
  }) async {
    final body = {
      'username': username.trim(),
      'email': email.trim(),
      'password': password,
      if (shopName != null && shopName.trim().isNotEmpty) 'shop_name': shopName.trim(),
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) 'phone_number': phoneNumber.trim(),
    };

    final response = await _api.post('/api/auth/register/', body: body, requiresAuth: false);
    final authResponse = AuthResponse.fromJson(response as Map<String, dynamic>);
    if (authResponse.access != null) {
      await _api.saveTokens(
        access: authResponse.access!,
        refresh: authResponse.refresh,
      );
      _currentUser = authResponse.user;
    }
    return authResponse;
  }

  Future<User?> fetchProfile() async {
    try {
      final response = await _api.get('/api/auth/me/');
      if (response is Map<String, dynamic>) {
        _currentUser = User.fromJson(response);
        return _currentUser;
      }
    } catch (_) {
      // If fetching fails or token expired
    }
    return null;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _api.clearAuth();
  }
}
