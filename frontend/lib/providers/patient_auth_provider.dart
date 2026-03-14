import 'package:flutter/material.dart';
import 'package:frontend/models/patient.dart';
import 'package:frontend/services/patient_auth_service.dart';

class PatientAuthProvider extends ChangeNotifier {
  final PatientAuthService _authService;

  Patient? _currentPatient;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;

  PatientAuthProvider(this._authService);

  /// Initialize auth provider
  Future<void> init() async {
    await _authService.init();
    _token = _authService.getToken();

    if (_token != null) {
      final patient = await _authService.getCurrentPatient();
      if (patient != null) {
        _currentPatient = patient;
        _isLoggedIn = true;
      } else {
        _isLoggedIn = false;
        _currentPatient = null;
        _token = null;
      }
    }
    notifyListeners();
  }

  /// Getters
  Patient? get currentPatient => _currentPatient;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;

  /// Register a new patient
  Future<bool> register({
    required String name,
    required int age,
    required String gender,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        name: name,
        age: age,
        gender: gender,
        notes: notes,
      );

      _currentPatient = result.patient;
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

  /// Login a patient
  Future<bool> login({
    required String name,
    required String disease,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        name: name,
        disease: disease,
      );

      _currentPatient = result.patient;
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

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _currentPatient = null;
    _token = null;
    _isLoggedIn = false;
    _errorMessage = null;
    _isLoading = false;

    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
