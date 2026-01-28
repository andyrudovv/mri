import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/components/AddPatientDialog.dart';
import 'package:frontend/components/MRIViewer.dart';
import 'package:frontend/components/MRIsummary.dart';
import 'package:frontend/components/SideBar.dart';
import 'package:frontend/providers/auth_provider.dart';

import 'package:dio/dio.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Dio dio = Dio();
  File? selectedImage;
  String predictionResult = "No analysis yet";

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

  /// Upload & Predict MRI
  Future<String> predictMRI(File imageFile, int patientId) async {
    // 1. Updated URL to match backend router prefix and path variable
    final String url = "http://127.0.0.1:8000/api/analysis/predict/$patientId";
    
    // 2. Get the token from AuthProvider
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    String fileName = imageFile.path.split('/').last;

    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      )
    });

    try {
      final response = await dio.post(
        url, 
        data: formData,
        options: Options(
          headers: {
            // 3. Add Bearer Token for authentication
            "Authorization": "Bearer $token",
          },
        ),
      );

      // 4. Access keys using camelCase to match your MRIAnalysisResponse schema
      final String diagnosis = response.data["predictedClass"];
      final String probabilities = response.data["probabilities"];

      return "Result: $diagnosis\n$probabilities";
    } catch (e) {
      if (e is DioException) {
        return "Error: ${e.response?.data['detail'] ?? 'Connection failed'}";
      }
      return "error";
    }
  }

  /// Run prediction
  Future runAnalysis() async {
    final authProvider = context.read<AuthProvider>();
    
    if (selectedImage == null) {
      setState(() => predictionResult = "Please select an MRI image first.");
      return;
    }

    // Safety check: Ensure there is at least one patient to attach this analysis to
    if (authProvider.patients.isEmpty) {
      setState(() => predictionResult = "Please add a patient first.");
      return;
    }

    // For now, we take the first patient. Ideally, you'd have a 'selectedPatientId'
    int patientId = authProvider.patients.first.id;

    setState(() => predictionResult = "Analysing...");
    
    String result = await predictMRI(selectedImage!, patientId);

    setState(() {
      predictionResult = result;
    });
  }
  /// Select MRI image
  Future pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      selectedImage = File(image.path);
    });
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
                                CircleAvatar(
                                  backgroundColor: Colors.greenAccent,
                                  radius: 15,
                                  backgroundImage: authProvider
                                              .currentDoctor?.profileImage !=
                                          null
                                      ? NetworkImage(
                                          authProvider.currentDoctor!.profileImage!)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authProvider.currentDoctor?.name ??
                                          'Doctor',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      authProvider.currentDoctor?.specialization ??
                                          'Specialist',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'logout') {
                                  _handleLogout(context);
                                } else if (value == 'profile') {
                                  // Handle profile edit
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                /// MRI Viewer
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MRIViewer(imageFile: selectedImage),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: pickImage,
                                      child: const Text("Select MRI Image"),
                                    ),
                                  ],
                                ),
                                /// MRI Summary panel
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: runAnalysis,
                                      child: const Text("Get Analysis"),
                                    ),
                                    const SizedBox(height: 20),
                                    MRIsummary(result: predictionResult),
                                  ],
                                ),
                              ],
                            ),
                          ],
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
