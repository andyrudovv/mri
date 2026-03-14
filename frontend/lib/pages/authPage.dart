import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/patient_auth_provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _patientNameController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _patientDiseaseController = TextEditingController();
  final _patientGenderController = TextEditingController();
  final _patientNotesController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isDoctorAuth = true; // Toggle between doctor and patient auth
  String _selectedGender = 'Male';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _specializationController.dispose();
    _patientNameController.dispose();
    _patientAgeController.dispose();
    _patientDiseaseController.dispose();
    _patientGenderController.dispose();
    _patientNotesController.dispose();
    super.dispose();
  }

  Future<void> _handleDoctorAuth(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    if (_isLogin) {
      final success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted && authProvider.errorMessage != null) {
        _showErrorSnackBar(authProvider.errorMessage!);
      }
    } else {
      if (_nameController.text.isEmpty ||
          _specializationController.text.isEmpty) {
        _showErrorSnackBar('Please fill all fields');
        return;
      }

      final success = await authProvider.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        specialization: _specializationController.text.trim(),
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted && authProvider.errorMessage != null) {
        _showErrorSnackBar(authProvider.errorMessage!);
      }
    }
  }

  Future<void> _handlePatientAuth(BuildContext context) async {
    final patientAuthProvider = context.read<PatientAuthProvider>();

    if (_isLogin) {
      // Patient Login
      if (_patientNameController.text.isEmpty ||
          _patientDiseaseController.text.isEmpty) {
        _showErrorSnackBar('Please fill all fields');
        return;
      }

      final success = await patientAuthProvider.login(
        name: _patientNameController.text.trim(),
        disease: _patientDiseaseController.text.trim(),
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/patient-home');
      } else if (mounted && patientAuthProvider.errorMessage != null) {
        _showErrorSnackBar(patientAuthProvider.errorMessage!);
      }
    } else {
      // Patient Registration
      if (_patientNameController.text.isEmpty ||
          _patientAgeController.text.isEmpty) {
        _showErrorSnackBar('Please fill all required fields');
        return;
      }

      final success = await patientAuthProvider.register(
        name: _patientNameController.text.trim(),
        age: int.tryParse(_patientAgeController.text) ?? 0,
        gender: _selectedGender,
        notes: _patientNotesController.text.isEmpty ? null : _patientNotesController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/patient-home');
      } else if (mounted && patientAuthProvider.errorMessage != null) {
        _showErrorSnackBar(patientAuthProvider.errorMessage!);
      }
    }
  }

  Future<void> _handleAuth(BuildContext context) async {
    if (_isDoctorAuth) {
      await _handleDoctorAuth(context);
    } else {
      await _handlePatientAuth(context);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.lightBlueAccent.shade200,
              Colors.blueAccent.shade400,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          'MRI Analysis',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isDoctorAuth
                              ? (_isLogin ? 'Doctor Login' : 'Doctor Registration')
                              : (_isLogin ? 'Patient Login' : 'Patient Registration'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Toggle between Doctor and Patient auth
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Doctor'),
                                selected: _isDoctorAuth,
                                onSelected: (selected) {
                                  setState(() {
                                    _isDoctorAuth = selected;
                                    _isLogin = true;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Patient'),
                                selected: !_isDoctorAuth,
                                onSelected: (selected) {
                                  setState(() {
                                    _isDoctorAuth = !selected;
                                    _isLogin = true;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Doctor Auth Fields
                        if (_isDoctorAuth) ...[
                          // Name field (only for registration)
                          if (!_isLogin)
                            Column(
                              children: [
                                TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: const Icon(Icons.person),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                          // Email field
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Specialization field (only for registration)
                          if (!_isLogin)
                            Column(
                              children: [
                                TextField(
                                  controller: _specializationController,
                                  decoration: InputDecoration(
                                    labelText: 'Specialization',
                                    prefixIcon: const Icon(Icons.local_hospital),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                          // Password field
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              helperText: !_isLogin
                                  ? 'Must be at least 8 characters'
                                  : null,
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],

                        // Patient Auth Fields
                        if (!_isDoctorAuth) ...[
                          // Patient Name field
                          TextField(
                            controller: _patientNameController,
                            decoration: InputDecoration(
                              labelText: 'Your Name',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Patient Age and Gender row
                          if (!_isLogin)
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _patientAgeController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Age',
                                      prefixIcon: const Icon(Icons.cake),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedGender,
                                    decoration: InputDecoration(
                                      labelText: 'Gender',
                                      prefixIcon: const Icon(Icons.male),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedGender = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),

                          // Disease field (login only - for authentication)
                          if (_isLogin)
                            TextField(
                              controller: _patientDiseaseController,
                              decoration: InputDecoration(
                                labelText: 'Disease (for login)',
                                prefixIcon: const Icon(Icons.local_hospital),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                helperText: 'Enter your diagnosis to login',
                              ),
                            ),

                          // Notes field (only for registration)
                          if (!_isLogin)
                            TextField(
                              controller: _patientNotesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Notes (optional)',
                                prefixIcon: const Icon(Icons.note),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                        ],

                        const SizedBox(height: 24),

                        // Login/Register button
                        if (_isDoctorAuth)
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: authProvider.isLoading
                                      ? null
                                      : () => _handleAuth(context),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: authProvider.isLoading
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : Text(
                                    _isLogin ? 'Login' : 'Register',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          Consumer<PatientAuthProvider>(
                            builder: (context, patientAuthProvider, _) {
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: patientAuthProvider.isLoading
                                      ? null
                                      : () => _handleAuth(context),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: patientAuthProvider.isLoading
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : Text(
                                    _isLogin ? 'Login' : 'Register',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 16),

                        // Toggle login/register
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? "Don't have an account? "
                                  : "Already have an account? ",
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  // Clear fields
                                  _emailController.clear();
                                  _passwordController.clear();
                                  _nameController.clear();
                                  _specializationController.clear();
                                  _patientNameController.clear();
                                  _patientAgeController.clear();
                                  _patientDiseaseController.clear();
                                  _patientNotesController.clear();
                                });
                              },
                              child: Text(
                                _isLogin ? 'Register' : 'Login',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}