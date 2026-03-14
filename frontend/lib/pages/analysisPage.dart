import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/models/patient.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

class AnalysisPage extends StatefulWidget {
  final Patient patient;

  const AnalysisPage({super.key, required this.patient});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  Dio dio = Dio();
  Uint8List? selectedImageBytes;
  String? selectedImagePath;
  String predictionResult = "No analysis yet";
  Map<String, dynamic>? probabilities;
  bool _isAnalyzing = false;
  List<Map<String, dynamic>> _analysisHistory = [];

  @override
  void initState() {
    super.initState();
    _loadAnalysisHistory();
  }

  Future<void> _loadAnalysisHistory() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    
    if (token == null) return;

    try {
      final response = await dio.get(
        'http://127.0.0.1:8000/api/analysis/patient/${widget.patient.id}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _analysisHistory = List<Map<String, dynamic>>.from(response.data);
          if (_analysisHistory.isNotEmpty) {
            final latest = _analysisHistory.first;
            predictionResult = latest['predictedClass'] ?? 'Unknown';
            try {
              var probs = latest['probabilities'];
              if (probs is String) {
                probabilities = Map<String, dynamic>.from(json.decode(probs));
              } else if (probs is Map) {
                probabilities = Map<String, dynamic>.from(probs);
              } else {
                probabilities = {
                  'glioma': 0.0,
                  'meningioma': 0.0,
                  'notumor': 0.0,
                  'pituitary': 0.0,
                };
              }
            } catch (e) {
              probabilities = {
                'glioma': 0.0,
                'meningioma': 0.0,
                'notumor': 0.0,
                'pituitary': 0.0,
              };
            }
          }
        });
      }
    } catch (e) {
      print('Error loading analysis history: $e');
    }
  }

  Future<String> predictMRI(Uint8List imageBytes, int patientId) async {
    final String url = "http://127.0.0.1:8000/api/analysis/predict/$patientId";
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    FormData formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(
        imageBytes,
        filename: "mri_image.jpg",
      )
    });

    try {
      final response = await dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      final String diagnosis = response.data["predictedClass"];
      final probsData = response.data["probabilities"];

      // Parse probabilities
      try {
        if (probsData is String) {
          probabilities = Map<String, dynamic>.from(json.decode(probsData));
        } else if (probsData is Map) {
          probabilities = Map<String, dynamic>.from(probsData);
        } else {
          probabilities = {
            'glioma': 0.0,
            'meningioma': 0.0,
            'notumor': 0.0,
            'pituitary': 0.0,
          };
        }
      } catch (e) {
        probabilities = {
          'glioma': 0.0,
          'meningioma': 0.0,
          'notumor': 0.0,
          'pituitary': 0.0,
        };
      }

      // Reload history to get the latest analysis
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
    });

    String result = await predictMRI(selectedImageBytes!, int.parse(widget.patient.id.toString()));

    setState(() {
      _isAnalyzing = false;
      predictionResult = result;
      // Update the patient's disease field if analysis was successful
      if (result.startsWith("Result: ")) {
        final newDisease = result.substring(8); // Extract disease name after "Result: "
        // Update the patient object's disease
        widget.patient.disease = newDisease;
      }
    });
  }

  Future pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    if (kIsWeb) {
      // For web, read bytes directly
      final bytes = await image.readAsBytes();
      setState(() {
        selectedImageBytes = bytes;
        selectedImagePath = image.name;
      });
    } else {
      // For mobile/desktop, use File
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        selectedImageBytes = bytes;
        selectedImagePath = image.path;
      });
    }
  }

  Color _getDiseaseColor(String disease) {
    final d = disease.toLowerCase();
    if (d.contains('glioma')) return Colors.red;
    if (d.contains('meningioma')) return Colors.orange;
    if (d.contains('pituitary')) return Colors.purple;
    if (d.contains('no')) return Colors.green;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analysis: ${widget.patient.name}'),
        backgroundColor: _getDiseaseColor(widget.patient.disease),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade100,
              Colors.grey.shade200,
            ],
          ),
        ),
        child: Row(
          children: [
            // Left panel - Patient Info & MRI Viewer
            Expanded(
              child: Column(
                children: [
                  // Patient Info Card - fixed height
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.patient.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildInfoChip(
                                  icon: Icons.cake,
                                  label: '${widget.patient.age} years',
                                ),
                                const SizedBox(width: 16),
                                _buildInfoChip(
                                  icon: Icons.wc,
                                  label: widget.patient.gender,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getDiseaseColor(widget.patient.disease)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.patient.disease,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _getDiseaseColor(widget.patient.disease),
                                ),
                              ),
                            ),
                            if (widget.patient.notes != null &&
                                widget.patient.notes!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Notes: ${widget.patient.notes}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  // MRI Viewer - takes remaining space
                  Expanded(
                    child: Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'MRI Image',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: selectedImageBytes != null
                                ? Image.memory(
                                    selectedImageBytes!,
                                    fit: BoxFit.contain,
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.medical_services_outlined,
                                          size: 80,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No MRI image selected',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ElevatedButton.icon(
                              onPressed: pickImage,
                              icon: const Icon(Icons.upload_file),
                              label: Text(
                                selectedImageBytes == null
                                    ? 'Select MRI Image'
                                    : 'Change Image',
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Right panel - Analysis Results & History
            Container(
              width: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  left: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Analysis section
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Analysis',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Analyze button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isAnalyzing ? null : runAnalysis,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.lightBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isAnalyzing
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Run Analysis',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Results
                          Card(
                            elevation: 2,
                            color: Colors.grey.shade100,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    predictionResult,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (probabilities != null) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      'Probabilities:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...probabilities!.entries.map(
                                      (e) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              e.key,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            Text(
                                              '${(e.value * 100).toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: _getProbabilityColor(e.value),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ]
                              )
                            ),
                          )
                        ]
                      ),
                    ),
                  ),
                  // History Panel
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'History',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _analysisHistory.isEmpty
                              ? Center(
                                  child: Text(
                                    'No analysis history',
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _analysisHistory.length,
                                  itemBuilder: (context, index) {
                                    final analysis = _analysisHistory[index];
                                    final date = DateTime.parse(analysis['createdAt']);
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: _getDiseaseColor(
                                          analysis['predictedClass'] ?? 'Unknown',
                                        ),
                                        child: const Icon(
                                          Icons.analytics,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(analysis['predictedClass'] ?? 'Unknown'),
                                      subtitle: Text(
                                        '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                      ),
                                      onTap: () {
                                        setState(() {
                                          predictionResult = analysis['predictedClass'] ?? 'Unknown';
                                          try {
                                            probabilities = Map<String, dynamic>.from(
                                              analysis['probabilities'] ?? {},
                                            );
                                          } catch (e) {
                                            probabilities = null;
                                          }
                                        });
                                      },
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
          ]
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Color _getProbabilityColor(double value) {
    if (value >= 0.7) return Colors.green;
    if (value >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
