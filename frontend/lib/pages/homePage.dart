import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/components/AddPatientDialog.dart';
import 'package:frontend/components/SideBar.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/pages/profilePage.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Show Add Patient Dialog
  Future<void> _showAddPatientDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => Addpatientdialog(),
    );

    if (result != null) {
      final authProvider = context.read<AuthProvider>();

      // Add patient through auth provider
      final success = await authProvider.addPatient(
        name: result['name'] ?? '',
        age: result['age'] ?? 0,
        gender: result['gender'] ?? '',
        disease: result['disease'] ?? '',
        notes: result['notes'],
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient added successfully')),
        );
      } else if (mounted && authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Error adding patient'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ---------------------------
  /// UI
  /// ---------------------------
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        appBar: null,
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return Row(
              children: [
                SideBar(
                  addPatiantFunc: _showAddPatientDialog,
                  patients: authProvider.patients,
                  doctorName: authProvider.currentDoctor?.name ?? 'Doctor',
                  doctorImage: authProvider.currentDoctor?.profileImage,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10.0, vertical: 9.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 8),
                              ],
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'logout') {
                                  _handleLogout(context);
                                } else if (value == 'profile') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ProfilePage(),
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem(
                                  value: 'profile',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person),
                                      SizedBox(width: 8),
                                      Text('Profile'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'logout',
                                  child: Row(
                                    children: [
                                      Icon(Icons.logout, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Logout', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              child: const Icon(Icons.more_vert),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 120,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Select a patient from the sidebar',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'to view details and run analysis',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    }
  }
}
