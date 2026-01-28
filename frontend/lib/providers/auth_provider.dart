import 'package:flutter/material.dart';
import 'package:frontend/models/doctor.dart';
import 'package:frontend/models/patient.dart';
import 'package:frontend/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  Doctor? _currentDoctor;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;

  // Getters
  Doctor? get currentDoctor => _currentDoctor;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;
  List<Patient> get patients => _currentDoctor?.patients ?? [];

  AuthProvider(this._authService);

  /// Initialize auth provider - check if there's a stored token
  Future<void> init() async {
    await _authService.init();
    _token = _authService.getToken();

    if (_token != null) {
      await verifyToken();
    }
  }

  /// Register a new doctor
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String specialization,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
        specialization: specialization,
      );

      _currentDoctor = result.doctor;
      _token = result.token;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login a doctor
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );

      _currentDoctor = result.doctor;
      _token = result.token;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify token validity
  Future<void> verifyToken() async {
    try {
      final doctor = await _authService.verifyToken();
      if (doctor != null) {
        _currentDoctor = doctor;
        _isLoggedIn = true;
      } else {
        _isLoggedIn = false;
        _currentDoctor = null;
        _token = null;
        await _authService.clearCache();
      }
    } catch (e) {
      _isLoggedIn = false;
      _currentDoctor = null;
      _token = null;
      await _authService.clearCache();
      print('Token verification failed: $e');
    }
    notifyListeners();
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _currentDoctor = null;
    _token = null;
    _isLoggedIn = false;
    _errorMessage = null;
    _isLoading = false;

    notifyListeners();
  }

  /// Add a patient
  Future<bool> addPatient({
    required String name,
    required int age,
    required String gender,
    required String disease,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedDoctor = await _authService.addPatient(
        name: name,
        age: age,
        gender: gender,
        disease: disease,
        notes: notes,
      );

      _currentDoctor = updatedDoctor;
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      final errorMsg = e.toString();
      _errorMessage = errorMsg;
      
      // Check if error indicates unauthorized access (token invalid)
      if (errorMsg.contains('401') || errorMsg.contains('Unauthorized')) {
        _isLoggedIn = false;
        _currentDoctor = null;
        _token = null;
        await _authService.clearCache();
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove a patient
  Future<bool> removePatient(dynamic patientId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.deletePatient(patientId);

      if (_currentDoctor != null) {
        // Ensure your Doctor model's removePatient also handles dynamic/int IDs
        _currentDoctor = _currentDoctor!.removePatient(patientId);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update doctor profile
  Future<bool> updateProfile({
    required String name,
    required String specialization,
    String? profileImage,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedDoctor = await _authService.updateProfile(
        name: name,
        specialization: specialization,
        profileImage: profileImage,
      );

      _currentDoctor = updatedDoctor;
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
