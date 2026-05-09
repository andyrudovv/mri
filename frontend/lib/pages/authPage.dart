import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/patient_auth_provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();

  final _patientIINController = TextEditingController();
  final _patientPasswordController = TextEditingController();
  final _patientNameController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _patientNotesController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isDoctorAuth = true;
  String _selectedGender = 'Male';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _specializationController.dispose();
    _patientIINController.dispose();
    _patientPasswordController.dispose();
    _patientNameController.dispose();
    _patientAgeController.dispose();
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
      if (_nameController.text.isEmpty || _specializationController.text.isEmpty) {
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
      if (_patientIINController.text.isEmpty || _patientPasswordController.text.isEmpty) {
        _showErrorSnackBar('Please fill IIN and password');
        return;
      }

      final success = await patientAuthProvider.login(
        iin: _patientIINController.text.trim(),
        password: _patientPasswordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/patient-home');
      } else if (mounted && patientAuthProvider.errorMessage != null) {
        _showErrorSnackBar(patientAuthProvider.errorMessage!);
      }
    } else {
      if (_patientIINController.text.isEmpty ||
          _patientNameController.text.isEmpty ||
          _patientAgeController.text.isEmpty ||
          _patientPasswordController.text.isEmpty) {
        _showErrorSnackBar('Please fill all required fields');
        return;
      }

      if (_patientIINController.text.trim().length != 12) {
        _showErrorSnackBar('IIN must be exactly 12 digits');
        return;
      }

      final success = await patientAuthProvider.register(
        iin: _patientIINController.text.trim(),
        name: _patientNameController.text.trim(),
        age: int.tryParse(_patientAgeController.text) ?? 0,
        gender: _selectedGender,
        password: _patientPasswordController.text,
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
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _switchMode() {
    _animController.reset();
    setState(() {
      _isLogin = !_isLogin;
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _specializationController.clear();
      _patientIINController.clear();
      _patientPasswordController.clear();
      _patientNameController.clear();
      _patientAgeController.clear();
      _patientNotesController.clear();
    });
    _animController.forward();
  }

  InputDecoration _inputDecoration(String label, IconData icon, {String? helper}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0077B6), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0077B6), Color(0xFF00B4D8), Color(0xFF90E0EF)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Card(
                  elevation: 12,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0077B6).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.psychology_outlined,
                              size: 48,
                              color: Color(0xFF0077B6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'MRI Analysis',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF023E8A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isDoctorAuth
                                ? (_isLogin ? 'Doctor Login' : 'Doctor Registration')
                                : (_isLogin ? 'Patient Login' : 'Patient Registration'),
                            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),

                          // Doctor / Patient toggle
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _ToggleButton(
                                    label: 'Doctor',
                                    icon: Icons.medical_services,
                                    isSelected: _isDoctorAuth,
                                    onTap: () => setState(() {
                                      _isDoctorAuth = true;
                                      _isLogin = true;
                                    }),
                                  ),
                                ),
                                Expanded(
                                  child: _ToggleButton(
                                    label: 'Patient',
                                    icon: Icons.person,
                                    isSelected: !_isDoctorAuth,
                                    onTap: () => setState(() {
                                      _isDoctorAuth = false;
                                      _isLogin = true;
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (_isDoctorAuth) ..._buildDoctorFields(),
                          if (!_isDoctorAuth) ..._buildPatientFields(),

                          const SizedBox(height: 24),
                          _buildAuthButton(),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLogin ? "Don't have an account? " : "Already have an account? ",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              TextButton(
                                onPressed: _switchMode,
                                child: Text(
                                  _isLogin ? 'Register' : 'Login',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0077B6),
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
      ),
    );
  }

  List<Widget> _buildDoctorFields() {
    return [
      if (!_isLogin) ...[
        TextField(
          controller: _nameController,
          decoration: _inputDecoration('Full Name', Icons.person),
        ),
        const SizedBox(height: 14),
      ],
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: _inputDecoration('Email', Icons.email),
      ),
      const SizedBox(height: 14),
      if (!_isLogin) ...[
        TextField(
          controller: _specializationController,
          decoration: _inputDecoration('Specialization', Icons.local_hospital),
        ),
        const SizedBox(height: 14),
      ],
      TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: _inputDecoration(
          'Password',
          Icons.lock,
          helper: !_isLogin ? 'At least 8 characters' : null,
        ).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildPatientFields() {
    return [
      TextField(
        controller: _patientIINController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(12),
        ],
        decoration: _inputDecoration(
          'IIN (Individual ID Number)',
          Icons.badge,
          helper: '12-digit identification number',
        ),
      ),
      const SizedBox(height: 14),
      if (!_isLogin) ...[
        TextField(
          controller: _patientNameController,
          decoration: _inputDecoration('Full Name', Icons.person),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _patientAgeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDecoration('Age', Icons.cake),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: _inputDecoration('Gender', Icons.wc),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _selectedGender = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _patientNotesController,
          maxLines: 2,
          decoration: _inputDecoration('Notes (optional)', Icons.note),
        ),
        const SizedBox(height: 14),
      ],
      TextField(
        controller: _patientPasswordController,
        obscureText: _obscurePassword,
        decoration: _inputDecoration(
          'Password',
          Icons.lock,
          helper: !_isLogin ? 'At least 6 characters' : null,
        ).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    ];
  }

  Widget _buildAuthButton() {
    if (_isDoctorAuth) {
      return Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : () => _handleAuth(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077B6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: authProvider.isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isLogin ? 'Login' : 'Register',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          );
        },
      );
    } else {
      return Consumer<PatientAuthProvider>(
        builder: (context, patientAuthProvider, _) {
          return SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: patientAuthProvider.isLoading ? null : () => _handleAuth(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077B6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: patientAuthProvider.isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isLogin ? 'Login' : 'Register',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          );
        },
      );
    }
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0077B6) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
