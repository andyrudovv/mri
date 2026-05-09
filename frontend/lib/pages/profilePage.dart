import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _profileImageController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isChangingPassword = false;
  bool _showPasswordSection = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final doctor = authProvider.currentDoctor;

    if (doctor != null) {
      _nameController.text = doctor.name;
      _specializationController.text = doctor.specialization;
      _profileImageController.text = doctor.profileImage ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _profileImageController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty || _specializationController.text.trim().isEmpty) {
      _showSnack('Please fill all required fields', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      specialization: _specializationController.text.trim(),
      profileImage: _profileImageController.text.trim().isEmpty
          ? null
          : _profileImageController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        _showSnack('Profile updated successfully', Colors.green);
        Navigator.pop(context);
      } else {
        _showSnack(authProvider.errorMessage ?? 'Failed to update profile', Colors.red);
      }
    }
  }

  Future<void> _changePassword() async {
    if (_oldPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      _showSnack('Please fill all password fields', Colors.red);
      return;
    }

    if (_newPasswordController.text.length < 8) {
      _showSnack('New password must be at least 8 characters', Colors.red);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnack('Passwords do not match', Colors.red);
      return;
    }

    setState(() => _isChangingPassword = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.changePassword(
      oldPassword: _oldPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    setState(() => _isChangingPassword = false);

    if (mounted) {
      if (success) {
        _showSnack('Password changed successfully', Colors.green);
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() => _showPasswordSection = false);
      } else {
        _showSnack(authProvider.errorMessage ?? 'Failed to change password', Colors.red);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {String? helper}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0077B6), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF0077B6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0077B6), Color(0xFFF0F4F8)],
            stops: [0.0, 0.3],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF0077B6),
                        backgroundImage: _profileImageController.text.isNotEmpty
                            ? NetworkImage(_profileImageController.text)
                            : null,
                        child: _profileImageController.text.isEmpty
                            ? const Icon(Icons.person, size: 50, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 24),

                      TextField(
                        controller: _nameController,
                        decoration: _inputDecoration('Full Name *', Icons.person),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _specializationController,
                        decoration: _inputDecoration('Specialization *', Icons.local_hospital),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: _profileImageController,
                        decoration: _inputDecoration('Profile Image URL', Icons.image, helper: 'Optional'),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0077B6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password change section
                      Divider(color: Colors.grey.shade200),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() => _showPasswordSection = !_showPasswordSection),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline, size: 20, color: Color(0xFF0077B6)),
                            const SizedBox(width: 8),
                            const Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0077B6),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _showPasswordSection ? Icons.expand_less : Icons.expand_more,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),

                      if (_showPasswordSection) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _oldPasswordController,
                          obscureText: true,
                          decoration: _inputDecoration('Current Password', Icons.lock),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: _inputDecoration('New Password', Icons.lock_outline, helper: 'At least 8 characters'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: _inputDecoration('Confirm New Password', Icons.lock_outline),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: _isChangingPassword ? null : _changePassword,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0077B6)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isChangingPassword
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Update Password', style: TextStyle(color: Color(0xFF0077B6))),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 15)),
                        ),
                      ),
                    ],
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
