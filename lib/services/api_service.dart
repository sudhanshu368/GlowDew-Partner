import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation_service.dart';

class ApiService {
  static const String baseUrl = 'https://api.pingtolearn.online';
  
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _cookieKey = 'auth_cookie';

  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Get headers with content-type and saved cookie/token
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (includeAuth) {
      final token = prefs.getString(_tokenKey);
      if (token != null && token != 'cookie_session') {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    final cookie = prefs.getString(_cookieKey);
    if (cookie != null) {
      headers['Cookie'] = cookie;
    }
    
    return headers;
  }

  // Helper to parse and save Cookie from response headers
  Future<void> _updateCookie(http.Response response) async {
    final rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cookieKey, rawCookie);
    }
  }

  // Save Token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Save Refresh Token
  Future<void> _saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  // Clear Session
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_cookieKey);
  }

  bool _isRedirecting = false;

  // Clear session and redirect to login
  Future<void> _handleInvalidSession() async {
    await clearSession();
    if (!_isRedirecting) {
      _isRedirecting = true;
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
      Future.delayed(const Duration(seconds: 2), () {
        _isRedirecting = false;
      });
    }
  }

  // Logout Api
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _post('/api/v1/auth/logout', {});
      await clearSession();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      await clearSession();
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  // POST Request Helper
  Future<http.Response> _post(String endpoint, Map<String, dynamic> body, {bool includeAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    var headers = await _getHeaders(includeAuth: includeAuth);
    var response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    await _updateCookie(response);

    // If unauthorized (401), try to refresh the token and retry once
    if (response.statusCode == 401 && includeAuth && endpoint != '/api/v1/auth/refresh') {
      final isRefreshed = await refreshToken();
      if (isRefreshed) {
        headers = await _getHeaders(includeAuth: includeAuth);
        response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
        await _updateCookie(response);
      } else {
        await _handleInvalidSession();
      }
    }

    return response;
  }

  // GET Request Helper
  Future<http.Response> _get(String endpoint, {bool includeAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    var headers = await _getHeaders(includeAuth: includeAuth);
    var response = await http.get(
      url,
      headers: headers,
    );
    await _updateCookie(response);

    // If unauthorized (401), try to refresh the token and retry once
    if (response.statusCode == 401 && includeAuth && endpoint != '/api/v1/auth/refresh') {
      final isRefreshed = await refreshToken();
      if (isRefreshed) {
        headers = await _getHeaders(includeAuth: includeAuth);
        response = await http.get(
          url,
          headers: headers,
        );
        await _updateCookie(response);
      } else {
        await _handleInvalidSession();
      }
    }

    return response;
  }



  // PUT Request Helper
  Future<http.Response> _put(String endpoint, Map<String, dynamic> body, {bool includeAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    var headers = await _getHeaders(includeAuth: includeAuth);
    var response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    await _updateCookie(response);

    // If unauthorized (401), try to refresh the token and retry once
    if (response.statusCode == 401 && includeAuth && endpoint != '/api/v1/auth/refresh') {
      final isRefreshed = await refreshToken();
      if (isRefreshed) {
        headers = await _getHeaders(includeAuth: includeAuth);
        response = await http.put(
          url,
          headers: headers,
          body: jsonEncode(body),
        );
        await _updateCookie(response);
      } else {
        await _handleInvalidSession();
      }
    }

    return response;
  }

  // Login Api
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _post('/api/v1/auth/login', {
        'email': email,
        'password': password,
      }, includeAuth: false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        final userData = data['data']?['user'] ?? data['user'];
        final role = userData?['role'];
        
        if (role != 'SALON_OWNER') {
          // Temporarily save token so logout API has the credentials to log out
          final token = data['token'] ?? data['accessToken'] ?? data['data']?['token'] ?? data['data']?['accessToken'];
          if (token != null) {
            await _saveToken(token.toString());
          } else {
            await _saveToken('cookie_session');
          }
          
          // Call logout api to clean up backend session
          await logout();
          
          return {
            'success': false,
            'isRoleError': true,
            'role': role ?? 'unknown',
            'error': 'Access denied: Only Salon Owners are allowed to login. Your role is ${role ?? 'unknown'}.'
          };
        }

        final token = data['token'] ?? data['accessToken'] ?? data['data']?['token'] ?? data['data']?['accessToken'];
        if (token != null) {
          await _saveToken(token.toString());
        } else {
          // If login is successful but no token is in response, save a fallback value
          // to indicate session is active (authenticaton is handled by saved cookie).
          await _saveToken('cookie_session');
        }

        final refreshToken = data['refreshToken'] ?? data['data']?['refreshToken'];
        if (refreshToken != null) {
          await _saveRefreshToken(refreshToken.toString());
        }
        return {'success': true, 'data': data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Register Api
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await _post('/api/v1/auth/register', {
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
        'role': role,
      }, includeAuth: false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Get Profile Api (/api/v1/auth/me)
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _get('/api/v1/auth/me');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Get Auth Profile Api (/api/v1/auth/profile)
  Future<Map<String, dynamic>> getAuthProfile() async {
    try {
      final response = await _get('/api/v1/auth/profile');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Update User Profile Api (/api/v1/users/{userId})
  Future<Map<String, dynamic>> updateUserProfile(String userId, String name, String phone) async {
    try {
      final response = await _put('/api/v1/users/$userId', {
        'name': name,
        'phone': phone,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? data, 'message': data['message'] ?? 'User updated successfully'};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Get Salons List Api (/api/v1/salons)
  Future<Map<String, dynamic>> getSalons() async {
    try {
      final response = await _get('/api/v1/salons');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Get Salon Detail by ID (/api/v1/salons/{salonId})
  Future<Map<String, dynamic>> getSalonDetail(dynamic salonId) async {
    try {
      final response = await _get('/api/v1/salons/$salonId');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Update Salon Details Api (/api/v1/salons/{salonId})
  Future<Map<String, dynamic>> updateSalon(String salonId, Map<String, dynamic> payload) async {
    try {
      final response = await _put('/api/v1/salons/$salonId', payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Salon settings updated successfully'
        };
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Get Salon Reviews (/api/v1/reviews/salons/{salonId}/reviews)
  Future<Map<String, dynamic>> getSalonReviews(dynamic salonId) async {
    try {
      final response = await _get('/api/v1/reviews/salons/$salonId/reviews');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Get Salon Ratings Summary (/api/v1/reviews/salons/{salonId}/rating-stats)
  Future<Map<String, dynamic>> getSalonRatingsSummary(dynamic salonId) async {
    try {
      final response = await _get('/api/v1/reviews/salons/$salonId/rating-stats');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Fetch States Api
  Future<List<String>> fetchStates() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/data/states');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<String>.from(data['data']);
        }
      }
      return ['Bihar'];
    } catch (_) {
      return ['Bihar'];
    }
  }

  // Fetch Cities Api
  Future<List<String>> fetchCities() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/data/cities');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<String>.from(data['data']);
        }
      }
      return [
        "Begusarai",
        "Bhagalpur",
        "Danapur",
        "Darbhanga",
        "Gaya",
        "Katihar",
        "Madhepura",
        "Muzaffarpur",
        "Patna",
        "Purnia",
        "Saharsa"
      ];
    } catch (_) {
      return [
        "Begusarai",
        "Bhagalpur",
        "Danapur",
        "Darbhanga",
        "Gaya",
        "Katihar",
        "Madhepura",
        "Muzaffarpur",
        "Patna",
        "Purnia",
        "Saharsa"
      ];
    }
  }

  // Fetch Service Categories Api (/data/service-categories)
  Future<Map<String, dynamic>> fetchServiceCategories() async {
    try {
      final response = await _get('/data/service-categories', includeAuth: false);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Submit Onboarding Api
  Future<Map<String, dynamic>> submitOnboarding(Map<String, dynamic> payload) async {
    try {
      final response = await _post('/api/v1/onboarding/submit', payload, includeAuth: false);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Forgot Password Api
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _post('/api/v1/auth/forgot-password', {
        'email': email,
      }, includeAuth: false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Reset Password (OTP) Api
  Future<Map<String, dynamic>> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _post('/api/v1/auth/reset-password-with-otp', {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      }, includeAuth: false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Resend Password Reset OTP Api
  Future<Map<String, dynamic>> resendPasswordResetOtp(String email) async {
    try {
      final response = await _post('/api/v1/auth/resend-password-reset-otp', {
        'email': email,
      }, includeAuth: false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Request Email Verification Api
  Future<Map<String, dynamic>> requestEmailVerification(String email) async {
    try {
      final response = await _post('/api/v1/auth/stateless-email/request', {
        'email': email,
      }, includeAuth: false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }




  // Refresh Token Api
  Future<bool> refreshToken() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/auth/refresh');
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);
      if (refreshToken == null) {
        return false;
      }

      final headers = await _getHeaders(includeAuth: false);
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );
      
      await _updateCookie(response);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'] ?? data['accessToken'] ?? data['data']?['token'] ?? data['data']?['accessToken'];
        final newRefreshToken = data['refreshToken'] ?? data['data']?['refreshToken'];
        
        if (token != null) {
          await _saveToken(token.toString());
          if (newRefreshToken != null) {
            await _saveRefreshToken(newRefreshToken.toString());
          }
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // DELETE Request Helper
  Future<http.Response> _delete(String endpoint, {bool includeAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    var headers = await _getHeaders(includeAuth: includeAuth);
    var response = await http.delete(
      url,
      headers: headers,
    );
    await _updateCookie(response);

    // If unauthorized (401), try to refresh the token and retry once
    if (response.statusCode == 401 && includeAuth && endpoint != '/api/v1/auth/refresh') {
      final isRefreshed = await refreshToken();
      if (isRefreshed) {
        headers = await _getHeaders(includeAuth: includeAuth);
        response = await http.delete(
          url,
          headers: headers,
        );
        await _updateCookie(response);
      } else {
        await _handleInvalidSession();
      }
    }

    return response;
  }

  // PATCH Request Helper
  Future<http.Response> _patch(String endpoint, Map<String, dynamic>? body, {bool includeAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    var headers = await _getHeaders(includeAuth: includeAuth);
    var response = await http.patch(
      url,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    await _updateCookie(response);

    // If unauthorized (401), try to refresh the token and retry once
    if (response.statusCode == 401 && includeAuth && endpoint != '/api/v1/auth/refresh') {
      final isRefreshed = await refreshToken();
      if (isRefreshed) {
        headers = await _getHeaders(includeAuth: includeAuth);
        response = await http.patch(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        await _updateCookie(response);
      } else {
        await _handleInvalidSession();
      }
    }

    return response;
  }

  // Get Salon Services (/api/v1/salons/{salonId}/services)
  Future<Map<String, dynamic>> getSalonServices(dynamic salonId) async {
    try {
      final response = await _get('/api/v1/salons/$salonId/owner-services');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Create Salon Service (/api/v1/salons/{salonId}/services)
  Future<Map<String, dynamic>> createSalonService(dynamic salonId, Map<String, dynamic> payload) async {
    try {
      final response = await _post('/api/v1/salons/$salonId/services', payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Service created successfully'
        };
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Update Salon Service (/api/v1/salons/{salonId}/services/{serviceId})
  Future<Map<String, dynamic>> updateSalonService(dynamic salonId, dynamic serviceId, Map<String, dynamic> payload) async {
    try {
      final response = await _put('/api/v1/salons/$salonId/services/$serviceId', payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Service updated successfully'
        };
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Delete Salon Service (/api/v1/salons/{salonId}/services/{serviceId})
  Future<Map<String, dynamic>> deleteSalonService(dynamic salonId, dynamic serviceId) async {
    try {
      final response = await _delete('/api/v1/salons/$salonId/services/$serviceId');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Service deleted successfully'
        };
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Activate Service (/api/v1/services/{id}/activate)
  Future<Map<String, dynamic>> activateService(dynamic serviceId) async {
    try {
      final response = await _patch('/api/v1/services/$serviceId/activate', null);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Service activated successfully'
        };
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Deactivate Service (/api/v1/services/{id}/deactivate)
  Future<Map<String, dynamic>> deactivateService(dynamic serviceId) async {
    try {
      final response = await _patch('/api/v1/services/$serviceId/deactivate', null);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Service deactivated successfully'
        };
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Get Salon Bookings (/api/v1/bookings/salon/{salonId})
  Future<Map<String, dynamic>> getSalonBookings(dynamic salonId) async {
    try {
      final response = await _get('/api/v1/bookings/salon/$salonId');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Get Owner's Salons (/api/v1/salons/my-salons)
  Future<Map<String, dynamic>> getMySalons() async {
    try {
      final response = await _get('/api/v1/salons/my-salons');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Create Salon (/api/v1/salons)
  Future<Map<String, dynamic>> createSalon(Map<String, dynamic> payload) async {
    try {
      final response = await _post('/api/v1/salons', payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Salon created successfully'
        };
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Get Salon Dashboard statistics (/api/v1/salons/{salonId}/dashboard)
  Future<Map<String, dynamic>> getSalonDashboard(dynamic salonId) async {
    try {
      final response = await _get('/api/v1/salons/$salonId/dashboard');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Get Salon Earnings (/api/v1/salons/{salonId}/earnings)
  Future<Map<String, dynamic>> getSalonEarnings(dynamic salonId) async {
    try {
      final response = await _get('/api/v1/salons/$salonId/earnings');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Get Salon Home Service Settings (/api/v1/home-service/salon/{salonId}/settings)
  Future<Map<String, dynamic>> getHomeServiceSettings(dynamic salonId) async {
    try {
      final response = await _get('/api/v1/home-service/salon/$salonId/settings');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Update Salon Home Service Settings (/api/v1/home-service/salon/{salonId}/settings)
  Future<Map<String, dynamic>> updateHomeServiceSettings(dynamic salonId, Map<String, dynamic> payload) async {
    try {
      final response = await _patch('/api/v1/home-service/salon/$salonId/settings', payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Settings updated successfully'
        };
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Update Home Service Booking Status (/api/v1/home-service/{bookingId}/status)
  Future<Map<String, dynamic>> updateHomeServiceStatus(dynamic bookingId, String status) async {
    try {
      final response = await _patch('/api/v1/home-service/$bookingId/status', {
        'status': status,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Status updated successfully'
        };
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Get Booking Details (/api/v1/bookings/{id})
  Future<Map<String, dynamic>> getBookingDetails(String bookingId) async {
    try {
      final response = await _get('/api/v1/bookings/$bookingId');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Update Booking Status (/api/v1/bookings/{id}/status)
  Future<Map<String, dynamic>> updateBookingStatus(String bookingId, String status) async {
    try {
      final response = await _patch('/api/v1/bookings/$bookingId/status', {
        'status': status,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Status updated successfully'
        };
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Confirm Booking (/api/v1/bookings/{id}/confirm)
  Future<Map<String, dynamic>> confirmBooking(String bookingId) async {
    try {
      final response = await _patch('/api/v1/bookings/$bookingId/confirm', null);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Booking confirmed successfully'
        };
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Reschedule Booking (/api/v1/bookings/{id}/reschedule)
  Future<Map<String, dynamic>> rescheduleBooking(String bookingId, String newStartTime) async {
    try {
      final response = await _patch('/api/v1/bookings/$bookingId/reschedule', {
        'newStartTime': newStartTime,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Booking rescheduled successfully'
        };
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Cancel Pending Booking (/api/v1/bookings/{id}/cancel)
  Future<Map<String, dynamic>> cancelPendingBooking(String bookingId) async {
    try {
      final response = await _delete('/api/v1/bookings/$bookingId/cancel');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Booking cancelled successfully'
        };
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Get Booking Services (/api/v1/bookings/{id}/services)
  Future<Map<String, dynamic>> getBookingServices(String bookingId) async {
    try {
      final response = await _get('/api/v1/bookings/$bookingId/services');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  // Get Available Slots (/api/v1/bookings/available-slots)
  Future<Map<String, dynamic>> getAvailableSlots(dynamic salonId, String date) async {
    try {
      final response = await _get('/api/v1/bookings/available-slots?salonId=$salonId&date=$date');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        final errorMsg = _parseError(response);
        return {'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network connection error: $e'};
    }
  }

  String _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data['error'] is Map) {
        return data['error']['message'] ?? data['message'] ?? 'Request failed with status code ${response.statusCode}';
      }
      return data['message'] ?? data['error'] ?? data['data']?['message'] ?? 'Request failed with status code ${response.statusCode}';
    } catch (_) {
      return 'Request failed with status code ${response.statusCode}';
    }
  }
}
