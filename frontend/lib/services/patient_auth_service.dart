import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/patient.dart';

class PatientAuthService {
  static const String _baseUrl = 'http://127.0.0.1:8000';
  static const String _tokenKey = 'patient_auth_token';
  static const String _patientKey = 'patient_data';

  final Dio _dio = Dio(BaseOptions(baseUrl: _baseUrl));
  SharedPreferences? _prefs;

  PatientAuthService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _prefs?.remove(_tokenKey);
            _prefs?.remove(_patientKey);
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

  String? getToken() {
    return _prefs?.getString(_tokenKey);
  }

  Patient? getStoredPatient() {
    final patientJson = _prefs?.getString(_patientKey);
    if (patientJson != null) {
      return Patient.fromJson(jsonDecode(patientJson));
    }
    return null;
  }

  Future<void> clearCache() async {
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_patientKey);
    _dio.options.headers.remove('Authorization');
  }

  Future<({Patient patient, String token})> register({
    required String iin,
    required String name,
    required int age,
    required String gender,
    required String password,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/api/patients-auth/register',
        data: {
          'iin': iin,
          'name': name,
          'age': age,
          'gender': gender,
          'password': password,
          'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['token'] as String;
        final patientJson = response.data['patient'] as Map<String, dynamic>;
        final patientData = Patient.fromJson(patientJson);

        await _prefs?.setString(_tokenKey, token);
        await _prefs?.setString(_patientKey, jsonEncode(patientJson));
        _dio.options.headers['Authorization'] = 'Bearer $token';

        return (patient: patientData, token: token);
      } else {
        throw Exception('Registration failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Registration error');
    }
  }

  Future<({Patient patient, String token})> login({
    required String iin,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/patients-auth/login',
        data: {
          'iin': iin,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['token'] as String;
        final patientJson = response.data['patient'] as Map<String, dynamic>;
        final patientData = Patient.fromJson(patientJson);

        await _prefs?.setString(_tokenKey, token);
        await _prefs?.setString(_patientKey, jsonEncode(patientJson));
        _dio.options.headers['Authorization'] = 'Bearer $token';

        return (patient: patientData, token: token);
      } else {
        throw Exception(response.data['detail'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Login error: ${e.message}');
    }
  }

  Future<void> logout() async {
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_patientKey);
    _dio.options.headers.remove('Authorization');
  }

  Future<Patient?> getCurrentPatient() async {
    final token = getToken();
    if (token == null) return null;

    try {
      final response = await _dio.get(
        '/api/patients-auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final patientJson = response.data as Map<String, dynamic>;
        return Patient.fromJson(patientJson);
      }
    } catch (e) {
      await logout();
    }
    return null;
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final token = getToken();
      final response = await _dio.put(
        '/api/patients-auth/change-password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Failed to change password');
    }
  }
}
