import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/patient_auth_provider.dart';
import 'package:frontend/services/analysis_summary_api.dart';
import 'package:frontend/utils/disease_info.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

bool _analysisHasPathology(String predictedClass) {
  final t = predictedClass.trim();
  if (t.isEmpty) return false;
  if (t.toLowerCase() == 'notumor') return false;
  if (t.startsWith('Normal ')) return false;
  return true;
}

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  Dio dio = Dio();
  Uint8List? selectedImageBytes;
  String? selectedImagePath;
  String predictionResult = "No analysis yet";
  Map<String, dynamic>? probabilities;
  String? aiSummary;
  bool _isAnalyzing = false;
  List<Map<String, dynamic>> _analysisHistory = [];
  String _selectedModel = "ensemble";

  static const Map<String, String> _modelOptions = {
    "ensemble": "MRI Ensemble (4 classes)",
    "efficientnet": "EfficientNetV2S (30 classes)",
  };

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _waitForTokenAndLoad();
    });
  }

  Future<void> _waitForTokenAndLoad() async {
    final provider = context.read<PatientAuthProvider>();
    if (provider.token != null) {
      _loadAnalysisHistory();
      return;
    }
    // Token not ready yet — listen for auth state change
    void listener() {
      if (provider.token != null) {
        provider.removeListener(listener);
        _loadAnalysisHistory();
      }
    }
    provider.addListener(listener);
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysisHistory() async {
    final patientAuthProvider = context.read<PatientAuthProvider>();
    final token = patientAuthProvider.token;
    if (token == null) return;

    try {
      final response = await dio.get(
        'http://127.0.0.1:8000/api/analysis/my-analyses',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _analysisHistory = List<Map<String, dynamic>>.from(response.data);
          if (_analysisHistory.isNotEmpty) {
            final latest = _analysisHistory.first;
            predictionResult = latest['predictedClass'] ?? 'Unknown';
            aiSummary = latest['aiSummary'];
            try {
              var probs = latest['probabilities'];
              if (probs is String) {
                probabilities = Map<String, dynamic>.from(json.decode(probs));
              } else if (probs is Map) {
                probabilities = Map<String, dynamic>.from(probs);
              }
            } catch (e) {
              probabilities = null;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading analysis history: $e');
    }
    if (_analysisHistory.isNotEmpty) {
      final latest = _analysisHistory.first;
      final pred = latest['predictedClass'] as String? ?? '';
      Map<String, dynamic>? latestProbs;
      try {
        final probs = latest['probabilities'];
        if (probs is String) {
          latestProbs = Map<String, dynamic>.from(json.decode(probs));
        } else if (probs is Map) {
          latestProbs = Map<String, dynamic>.from(probs);
        }
      } catch (_) {}
      await _refreshGenerativeAiSummary(token, pred, latestProbs);
    }
  }

  Future<void> _refreshGenerativeAiSummary(
    String token,
    String predictedClass,
    Map<String, dynamic>? probs,
  ) async {
    if (!_analysisHasPathology(predictedClass) || probs == null || probs.isEmpty) return;
    try {
      final s = await AnalysisSummaryApi.fetchGenerativeSummary(
        token: token,
        predictedClass: predictedClass,
        probabilities: probs,
      );
      if (s != null && s.isNotEmpty && mounted) {
        setState(() => aiSummary = s);
      }
    } catch (e) {
      debugPrint('generate-summary failed: $e');
    }
  }

  Future<String> predictMRI(Uint8List imageBytes) async {
    final String url = "http://127.0.0.1:8000/api/analysis/predict-patient";
    final patientAuthProvider = context.read<PatientAuthProvider>();
    final token = patientAuthProvider.token;

    final filename = selectedImagePath ?? "mri_image.jpg";
    FormData formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(imageBytes, filename: filename),
      "model_type": _selectedModel,
    });

    try {
      final response = await dio.post(
        url,
        data: formData,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final String diagnosis = response.data["predictedClass"];
      final probsData = response.data["probabilities"];
      aiSummary = response.data["aiSummary"];

      try {
        if (probsData is String) {
          probabilities = Map<String, dynamic>.from(json.decode(probsData));
        } else if (probsData is Map) {
          probabilities = Map<String, dynamic>.from(probsData);
        }
      } catch (e) {
        probabilities = null;
      }

      await _loadAnalysisHistory();
      return "Result: $diagnosis";
    } catch (e) {
      if (e is DioException) {
        return "Error: ${e.response?.data['detail'] ?? 'Connection failed'}";
      }
      return "error";
    }
  }

  Future runAnalysis() async {
    if (selectedImageBytes == null) {
      setState(() => predictionResult = "Please select an MRI image first.");
      return;
    }

    setState(() {
      _isAnalyzing = true;
      predictionResult = "Analysing...";
      aiSummary = null;
    });

    String result = await predictMRI(selectedImageBytes!);

    setState(() {
      _isAnalyzing = false;
      predictionResult = result;
    });

    // Reload patient data so the disease label updates
    if (result.startsWith("Result: ") && mounted) {
      await context.read<PatientAuthProvider>().init();
    }
  }

  Future pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() {
      selectedImageBytes = bytes;
      selectedImagePath = image.name;
    });
  }

  void _showHistoryDetail(Map<String, dynamic> analysis) {
    final probs = analysis['probabilities'];
    Map<String, dynamic>? parsedProbs;
    try {
      if (probs is String) {
        parsedProbs = Map<String, dynamic>.from(json.decode(probs));
      } else if (probs is Map) {
        parsedProbs = Map<String, dynamic>.from(probs);
      }
    } catch (_) {}

    final imagePath = analysis['imagePath'] as String?;
    final imageUrl = imagePath != null && imagePath.isNotEmpty
        ? 'http://127.0.0.1:8000/api/analysis/image/$imagePath'
        : null;
    final predicted = analysis['predictedClass'] ?? 'Unknown';
    final summary = analysis['aiSummary'] as String?;
    final date = DateTime.parse(analysis['createdAt']);
    final info = getDiseaseInfo(predicted);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, color: getDiseaseColor(predicted)),
                      const SizedBox(width: 8),
                      Text(
                        'Analysis from ${date.day}/${date.month}/${date.year}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          color: Colors.grey.shade200,
                          child: const Center(child: Text('Image unavailable')),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: getDiseaseColor(predicted).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      predicted,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: getDiseaseColor(predicted)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (parsedProbs != null) ..._buildProbBars(parsedProbs),
                  if (info != null) ...[
                    const SizedBox(height: 12),
                    _buildDiseaseCard(info),
                  ],
                  if (summary != null && summary.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildAICard(summary),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProbBars(Map<String, dynamic> probs) {
    return probs.entries.map((e) {
      final value = (e.value is num) ? (e.value as num).toDouble() : 0.0;
      final color = getDiseaseColor(e.key);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(width: 90, child: Text(e.key, style: const TextStyle(fontSize: 12))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 45,
              child: Text(
                '${(value * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDiseaseCard(DiseaseInfo info) {
    return Card(
      elevation: 0,
      color: info.color.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: info.color.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.info_outline, size: 18, color: info.color),
              const SizedBox(width: 6),
              Text(info.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: info.color)),
            ]),
            const SizedBox(height: 8),
            Text(info.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
            const SizedBox(height: 6),
            Text(info.details, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Text('Severity: ${info.severity}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: info.color)),
          ],
        ),
      ),
    );
  }

  Widget _buildAICard(String summary) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF0F7FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFF0077B6).withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.psychology, size: 18, color: Color(0xFF0077B6)),
              SizedBox(width: 6),
              Text('AI Analysis Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0077B6))),
            ]),
            const SizedBox(height: 8),
            Text(summary, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.5)),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    _oldPasswordController.clear();
    _newPasswordController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_outline),
                helperText: 'At least 6 characters',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<PatientAuthProvider>();
              final success = await provider.changePassword(
                oldPassword: _oldPasswordController.text,
                newPassword: _newPasswordController.text,
              );
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Password changed' : provider.errorMessage ?? 'Failed'),
                    backgroundColor: success ? Colors.green : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0077B6)),
            child: const Text('Change', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<PatientAuthProvider>().logout();
      if (mounted) Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final diseaseInfo = getDiseaseInfo(predictionResult.replaceFirst('Result: ', ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My MRI Analysis'),
        backgroundColor: const Color(0xFF0077B6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'password') _showChangePasswordDialog();
              if (v == 'logout') _handleLogout(context);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'password',
                child: Row(children: [
                  Icon(Icons.lock_outline, size: 18),
                  SizedBox(width: 8),
                  Text('Change Password'),
                ]),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<PatientAuthProvider>(
        builder: (context, patientAuthProvider, _) {
          final patient = patientAuthProvider.currentPatient;

          if (patient == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Container(
            color: const Color(0xFFF8FAFB),
            child: Row(
              children: [
                // Left panel
                Expanded(
                  child: Column(
                    children: [
                      // Patient info card
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          elevation: 2,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF0077B6).withOpacity(0.15),
                                      child: const Icon(Icons.person, color: Color(0xFF0077B6)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            patient.name,
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                          if (patient.iin != null)
                                            Text(
                                              'IIN: ${patient.iin}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _buildChip(Icons.cake, '${patient.age} years'),
                                    _buildChip(Icons.wc, patient.gender),
                                    if (patient.disease.isNotEmpty)
                                      _buildChip(
                                        Icons.medical_information,
                                        patient.disease,
                                        color: getDiseaseColor(patient.disease),
                                      ),
                                  ],
                                ),

                                // Doctor info
                                if (patient.doctorName != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0077B6).withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF0077B6).withOpacity(0.15)),
                                    ),
                                    child: Row(
                                      children: [
                                        const CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Color(0xFF0077B6),
                                          child: Icon(Icons.medical_services, size: 16, color: Colors.white),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Dr. ${patient.doctorName}',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                            ),
                                            if (patient.doctorSpecialization != null)
                                              Text(
                                                patient.doctorSpecialization!,
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                if (patient.notes != null && patient.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.amber.shade200),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.note, size: 16, color: Colors.amber.shade700),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            patient.notes!,
                                            style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      // MRI viewer
                      Expanded(
                        child: Card(
                          elevation: 2,
                          shadowColor: Colors.black12,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(children: [
                                  const Icon(Icons.image, size: 20, color: Color(0xFF0077B6)),
                                  const SizedBox(width: 8),
                                  const Text('MRI Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ]),
                              ),
                              Expanded(
                                child: selectedImageBytes != null
                                    ? Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.memory(selectedImageBytes!, fit: BoxFit.contain),
                                        ),
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey.shade300),
                                            const SizedBox(height: 12),
                                            Text('No MRI image selected', style: TextStyle(color: Colors.grey.shade500)),
                                          ],
                                        ),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: ElevatedButton.icon(
                                  onPressed: pickImage,
                                  icon: const Icon(Icons.upload_file, size: 18),
                                  label: Text(selectedImageBytes == null ? 'Select MRI Image' : 'Change Image'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0077B6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Right panel
                Container(
                  width: 420,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(left: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Analysis',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF023E8A)),
                              ),
                              const SizedBox(height: 14),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF0077B6).withOpacity(0.3)),
                                  color: const Color(0xFFF0F7FF),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedModel,
                                    isExpanded: true,
                                    icon: const Icon(Icons.model_training, color: Color(0xFF0077B6)),
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF023E8A), fontWeight: FontWeight.w500),
                                    items: _modelOptions.entries.map((entry) {
                                      return DropdownMenuItem<String>(
                                        value: entry.key,
                                        child: Text(entry.value),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) setState(() => _selectedModel = value);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isAnalyzing ? null : runAnalysis,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0077B6),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: _isAnalyzing
                                      ? const SizedBox(
                                          height: 20, width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text('Run Analysis', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(height: 16),

                              Card(
                                elevation: 1,
                                color: const Color(0xFFF8FAFB),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        predictionResult,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: getDiseaseColor(predictionResult),
                                        ),
                                      ),
                                      if (probabilities != null) ...[
                                        const SizedBox(height: 14),
                                        ..._buildProbBars(probabilities!),
                                      ],
                                    ],
                                  ),
                                ),
                              ),

                              if (diseaseInfo != null) ...[
                                const SizedBox(height: 12),
                                _buildDiseaseCard(diseaseInfo),
                              ],

                              if (aiSummary != null && aiSummary!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildAICard(aiSummary!),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // History
                      Container(
                        height: 280,
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(children: [
                                const Icon(Icons.history, size: 18, color: Color(0xFF0077B6)),
                                const SizedBox(width: 6),
                                Text(
                                  'History (${_analysisHistory.length})',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF023E8A)),
                                ),
                              ]),
                            ),
                            Expanded(
                              child: _analysisHistory.isEmpty
                                  ? Center(child: Text('No analysis history', style: TextStyle(color: Colors.grey.shade400)))
                                  : ListView.builder(
                                      itemCount: _analysisHistory.length,
                                      itemBuilder: (context, index) {
                                        final analysis = _analysisHistory[index];
                                        final date = DateTime.parse(analysis['createdAt']);
                                        final predicted = analysis['predictedClass'] ?? 'Unknown';
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: getDiseaseColor(predicted).withOpacity(0.15),
                                            child: Icon(Icons.analytics, color: getDiseaseColor(predicted), size: 18),
                                          ),
                                          title: Text(predicted, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                          subtitle: Text(
                                            '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                          ),
                                          trailing: const Icon(Icons.open_in_new, size: 16),
                                          dense: true,
                                          onTap: () => _showHistoryDetail(analysis),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, {Color? color}) {
    final c = color ?? Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
