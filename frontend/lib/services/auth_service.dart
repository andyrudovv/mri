import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/doctor.dart';

class AuthService {
  static const String _baseUrl = 'http://127.0.0.1:8000';
  static const String _tokenKey = 'auth_token';
  static const String _doctorKey = 'doctor_data';

  final Dio _dio = Dio(BaseOptions(baseUrl: _baseUrl));
  SharedPreferences? _prefs;

  AuthService() {
    // Add interceptor to handle 401 Unauthorized responses
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Token is invalid or expired, clear it
            _prefs?.remove(_tokenKey);
            _prefs?.remove(_doctorKey);
            _dio.options.headers.remove('Authorization');
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get stored token
  String? getToken() {
    return _prefs?.getString(_tokenKey);
  }

  /// Get stored doctor data
  Doctor? getStoredDoctor() {
    final doctorJson = _prefs?.getString(_doctorKey);
    if (doctorJson != null) {
      // You may need to decode the JSON if stored as string
      // For now, returning null to use the response data
      return null;
    }
    return null;
  }

  /// Clear all cached authentication data
  Future<void> clearCache() async {
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_doctorKey);
    _dio.options.headers.remove('Authorization');
  }

  /// Register a new doctor
// Inside AuthService.dart
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String specialization,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'specialization': specialization,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        
        // 1. Save the token
        await _prefs?.setString(_tokenKey, data['token']);
        
        // 2. Save the doctor data - Ensure you use the correct key from FastAPI
        // In your auth.py, the key is "doctor"
        await _prefs?.setString(_doctorKey, jsonEncode(data['doctor']));

        return AuthResponse.fromJson(data);
      } else {
        throw Exception('Registration failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Registration error');
    }
  }
  /// Login a doctor
  Future<({Doctor doctor, String token})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['token'] as String;
        final doctorJson = response.data['doctor'] as Map<String, dynamic>;
        final doctorData = Doctor.fromJson(doctorJson);

        // Store token
        await _prefs?.setString(_tokenKey, token);

        // Set authorization header for future requests
        _dio.options.headers['Authorization'] = 'Bearer $token';

        return (doctor: doctorData, token: token);
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Login error: ${e.message}',
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      final token = getToken();
      if (token != null) {
        await _dio.post(
          '/api/auth/logout',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
            },
          ),
        );
      }
    } catch (e) {
      print('Logout error: $e');
    }

    // Clear local storage
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_doctorKey);

    // Clear authorization header
    _dio.options.headers.remove('Authorization');
  }

  /// Verify token validity
  Future<Doctor?> verifyToken() async {
    final token = getToken();
    if (token == null) return null;

    try {
      final response = await _dio.get(
        '/api/auth/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
        final doctorJson = response.data['doctor'] as Map<String, dynamic>;
        return Doctor.fromJson(doctorJson);
      }
    } catch (e) {
      print('Token verification error: $e');
      await logout();
    }
    return null;
  }

  // Update these specific methods in auth_service.dart

  Future<Doctor> addPatient({
    required String name,
    required int age,
    required String gender,
    required String disease,
    String? notes,
  }) async {
    try {
      final token = getToken();
      final response = await _dio.post(
        '/api/patients',
        data: {
          'name': name,
          'age': age,
          'gender': gender,
          'disease': disease,
          'notes': notes,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // FIX: Backend returns the Doctor object directly
      if (response.statusCode == 200 || response.statusCode == 201) {
        final doctorJson = response.data as Map<String, dynamic>;
        // Save updated doctor data (with new patient) to local storage
        await _prefs?.setString(_doctorKey, jsonEncode(doctorJson)); 
        return Doctor.fromJson(doctorJson);
      } else {
        throw Exception('Failed to add patient');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Error adding patient');
    }
  }

// FIX: Change String patientId to dynamic to prevent the int/String crash
Future<void> deletePatient(dynamic patientId) async {
  try {
    final token = getToken();
    final response = await _dio.delete(
      '/api/patients/${patientId.toString()}', // Convert to string for the URL
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  } on DioException catch (e) {
    throw Exception('Error deleting patient: ${e.message}');
  }
}
  Future<List<dynamic>> getPatients() async {
    try {
      final token = getToken();
      final response = await _dio.get(
        '/api/patients',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['patients'] ?? [];
      } else {
        throw Exception('Failed to fetch patients');
      }
    } on DioException catch (e) {
      throw Exception('Error fetching patients: ${e.message}');
    }
  }
    /// Update doctor profile
  Future<Doctor> updateProfile({
    required String name,
    required String specialization,
    String? profileImage,
  }) async {
    try {
      final token = getToken();
      final response = await _dio.put(
        '/api/auth/profile',
        data: {
          'name': name,
          'specialization': specialization,
          'profileImage': profileImage,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final doctorJson = response.data['doctor'] as Map<String, dynamic>;
        return Doctor.fromJson(doctorJson);
      } else {
        throw Exception('Failed to update profile');
      }
    } on DioException catch (e) {
      throw Exception('Error updating profile: ${e.message}');
    }
  }
}
