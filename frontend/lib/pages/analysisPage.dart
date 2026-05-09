import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/models/patient.dart';
import 'package:frontend/utils/disease_info.dart';
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
  String? aiSummary;
  bool _isAnalyzing = false;
  List<Map<String, dynamic>> _analysisHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _waitForTokenAndLoad();
    });
  }

  Future<void> _waitForTokenAndLoad() async {
    final provider = context.read<AuthProvider>();
    if (provider.token != null) {
      _loadAnalysisHistory();
      return;
    }
    void listener() {
      if (provider.token != null) {
        provider.removeListener(listener);
        _loadAnalysisHistory();
      }
    }
    provider.addListener(listener);
  }

  Future<void> _loadAnalysisHistory() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    if (token == null) return;

    try {
      final response = await dio.get(
        'http://127.0.0.1:8000/api/analysis/patient/${widget.patient.id}',
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
  }

  Future<String> predictMRI(Uint8List imageBytes, int patientId) async {
    final String url = "http://127.0.0.1:8000/api/analysis/predict/$patientId";
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    final filename = selectedImagePath ?? "mri_image.jpg";
    FormData formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(imageBytes, filename: filename)
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

    String result = await predictMRI(selectedImageBytes!, int.parse(widget.patient.id.toString()));

    setState(() {
      _isAnalyzing = false;
      predictionResult = result;
      if (result.startsWith("Result: ")) {
        widget.patient.disease = result.substring(8);
      }
    });
  }

  Future pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() {
        selectedImageBytes = bytes;
        selectedImagePath = image.name;
      });
    } else {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        selectedImageBytes = bytes;
        selectedImagePath = image.path;
      });
    }
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
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: getDiseaseColor(predicted),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (parsedProbs != null) ..._buildProbBars(parsedProbs),
                  if (info != null) ...[
                    const SizedBox(height: 12),
                    _DiseaseInfoCard(info: info),
                  ],
                  if (summary != null && summary.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _AISummaryCard(summary: summary),
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
            SizedBox(
              width: 90,
              child: Text(e.key, style: const TextStyle(fontSize: 12)),
            ),
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

  @override
  Widget build(BuildContext context) {
    final diseaseColor = getDiseaseColor(widget.patient.disease);
    final diseaseInfo = getDiseaseInfo(predictionResult.replaceFirst('Result: ', ''));

    return Scaffold(
      appBar: AppBar(
        title: Text('Analysis: ${widget.patient.name}'),
        backgroundColor: diseaseColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: const Color(0xFFF8FAFB),
        child: Row(
          children: [
            // Left panel
            Expanded(
              child: Column(
                children: [
                  // Patient info
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
                                  backgroundColor: diseaseColor.withOpacity(0.15),
                                  child: Icon(Icons.person, color: diseaseColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.patient.name,
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                      if (widget.patient.iin != null)
                                        Text(
                                          'IIN: ${widget.patient.iin}',
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
                                _InfoChip(icon: Icons.cake, label: '${widget.patient.age} years'),
                                _InfoChip(icon: Icons.wc, label: widget.patient.gender),
                                if (widget.patient.disease.isNotEmpty)
                                  _InfoChip(
                                    icon: Icons.medical_information,
                                    label: widget.patient.disease,
                                    color: diseaseColor,
                                  ),
                              ],
                            ),
                            if (widget.patient.notes != null && widget.patient.notes!.isNotEmpty) ...[
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
                                        widget.patient.notes!,
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
                            child: Row(
                              children: [
                                const Icon(Icons.image, size: 20, color: Color(0xFF0077B6)),
                                const SizedBox(width: 8),
                                const Text(
                                  'MRI Image',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
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
                                        Text(
                                          'No MRI image selected',
                                          style: TextStyle(color: Colors.grey.shade500),
                                        ),
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

                          // Result card
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
                            _DiseaseInfoCard(info: diseaseInfo),
                          ],

                          if (aiSummary != null && aiSummary!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _AISummaryCard(summary: aiSummary!),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // History panel
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
                          child: Row(
                            children: [
                              const Icon(Icons.history, size: 18, color: Color(0xFF0077B6)),
                              const SizedBox(width: 6),
                              Text(
                                'History (${_analysisHistory.length})',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF023E8A)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _analysisHistory.isEmpty
                              ? Center(
                                  child: Text('No analysis history', style: TextStyle(color: Colors.grey.shade400)),
                                )
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
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
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

class _DiseaseInfoCard extends StatelessWidget {
  final DiseaseInfo info;
  const _DiseaseInfoCard({required this.info});

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: info.color),
                const SizedBox(width: 6),
                Text(
                  info.name,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: info.color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(info.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
            const SizedBox(height: 6),
            Text(info.details, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Text(
              'Severity: ${info.severity}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: info.color),
            ),
          ],
        ),
      ),
    );
  }
}

class _AISummaryCard extends StatelessWidget {
  final String summary;
  const _AISummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
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
            const Row(
              children: [
                Icon(Icons.psychology, size: 18, color: Color(0xFF0077B6)),
                SizedBox(width: 6),
                Text(
                  'AI Analysis Summary',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0077B6)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(summary, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
