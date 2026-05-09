import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';

class Addpatientdialog extends StatefulWidget {
  const Addpatientdialog({super.key});

  @override
  State<Addpatientdialog> createState() => _AddpatientdialogState();
}

enum _Step { enterIIN, existingFound, fillNewData }

class _AddpatientdialogState extends State<Addpatientdialog> {
  final _iinController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedGender;
  String? _selectedDisease;

  _Step _currentStep = _Step.enterIIN;
  bool _isChecking = false;
  Map<String, dynamic>? _existingPatient;

  static const List<String> _diseases = [
    '',
    'Glioma',
    'Meningioma',
    'Pituitary',
    'No Tumor',
    'Astrocytoma',
    'Oligodendroglioma',
    'Ependymoma',
    'Craniopharyngioma',
    'Medulloblastoma',
    'Schwannoma',
    'Lymphoma',
    'Hemangioblastoma',
    'Metastatic Tumor',
  ];

  @override
  void dispose() {
    _iinController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkIIN() async {
    final iin = _iinController.text.trim();

    if (iin.isEmpty) {
      setState(() => _currentStep = _Step.fillNewData);
      return;
    }

    if (iin.length != 12) {
      _showError('IIN must be exactly 12 digits');
      return;
    }

    setState(() => _isChecking = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;
      final dio = Dio();
      final response = await dio.get(
        'http://127.0.0.1:8000/api/patients/check-iin/$iin',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['exists'] == true) {
        setState(() {
          _existingPatient = Map<String, dynamic>.from(response.data['patient']);
          _currentStep = _Step.existingFound;
          _isChecking = false;
        });
      } else {
        setState(() {
          _currentStep = _Step.fillNewData;
          _isChecking = false;
        });
      }
    } catch (e) {
      setState(() => _isChecking = false);
      _showError('Failed to check IIN');
    }
  }

  void _linkExisting() {
    final iin = _iinController.text.trim();
    Navigator.pop(context, {
      'name': _existingPatient!['name'] ?? '',
      'age': _existingPatient!['age'] ?? 0,
      'gender': _existingPatient!['gender'] ?? 'Other',
      'disease': _existingPatient!['disease'] ?? '',
      'notes': null,
      'iin': iin,
      'password': null,
    });
  }

  void _submitNew() {
    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();
    final gender = _selectedGender ?? 'Not specified';
    final disease = _selectedDisease ?? '';
    final notes = _notesController.text.trim();
    final iin = _iinController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      _showError('Please enter patient name');
      return;
    }
    if (ageText.isEmpty) {
      _showError('Please enter patient age');
      return;
    }
    int age = int.tryParse(ageText) ?? 0;
    if (age <= 0 || age > 150) {
      _showError('Please enter a valid age');
      return;
    }
    if (iin.isNotEmpty && password.isEmpty) {
      _showError('Please set a temporary password for the patient');
      return;
    }
    if (password.isNotEmpty && password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    Navigator.pop(context, {
      'name': name,
      'age': age,
      'gender': gender,
      'disease': disease,
      'notes': notes.isEmpty ? null : notes,
      'iin': iin.isEmpty ? null : iin,
      'password': password.isEmpty ? null : password,
    });
  }

  InputDecoration _inputDecoration(String label, IconData icon, {String? hint, String? helper}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0077B6), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, minWidth: 400),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  if (_currentStep == _Step.enterIIN) _buildStepIIN(),
                  if (_currentStep == _Step.existingFound) _buildStepExisting(),
                  if (_currentStep == _Step.fillNewData) _buildStepNewData(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title;
    String subtitle;
    switch (_currentStep) {
      case _Step.enterIIN:
        title = 'Add Patient';
        subtitle = 'Step 1: Enter IIN to check';
        break;
      case _Step.existingFound:
        title = 'Patient Found';
        subtitle = 'A patient with this IIN already exists';
        break;
      case _Step.fillNewData:
        title = 'New Patient';
        subtitle = 'Step 2: Fill in patient details';
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0077B6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _currentStep == _Step.existingFound ? Icons.person_search : Icons.person_add,
            color: const Color(0xFF0077B6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepIIN() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _iinController,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          decoration: _inputDecoration(
            'IIN (Individual ID Number)',
            Icons.badge,
            hint: '12-digit number',
            helper: 'Leave empty to create without IIN',
          ),
          onSubmitted: (_) => _checkIIN(),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isChecking ? null : _checkIIN,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077B6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isChecking
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepExisting() {
    final p = _existingPatient!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          color: const Color(0xFFE8F4FD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: const Color(0xFF0077B6).withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF0077B6),
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['name'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'IIN: ${_iinController.text.trim()}',
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
                  children: [
                    if (p['age'] != null)
                      Chip(
                        avatar: const Icon(Icons.cake, size: 14),
                        label: Text('${p['age']} years', style: const TextStyle(fontSize: 12)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (p['gender'] != null)
                      Chip(
                        avatar: const Icon(Icons.wc, size: 14),
                        label: Text(p['gender'], style: const TextStyle(fontSize: 12)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'This patient is already registered. Would you like to add them to your patient list?',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() {
                _currentStep = _Step.enterIIN;
                _existingPatient = null;
              }),
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _linkExisting,
              icon: const Icon(Icons.link, size: 18),
              label: const Text('Add to My Patients', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077B6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepNewData() {
    final hasIIN = _iinController.text.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasIIN)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge, size: 16, color: Color(0xFF0077B6)),
                  const SizedBox(width: 8),
                  Text(
                    'IIN: ${_iinController.text.trim()}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _currentStep = _Step.enterIIN),
                    child: Text('Change', style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                  ),
                ],
              ),
            ),
          ),

        TextField(
          controller: _nameController,
          decoration: _inputDecoration('Patient Name *', Icons.person, hint: 'Full name'),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDecoration('Age *', Icons.cake),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _selectedGender = v),
                decoration: _inputDecoration('Gender *', Icons.wc),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: _selectedDisease,
          items: _diseases.map((d) {
            return DropdownMenuItem(
              value: d,
              child: Text(d.isEmpty ? 'Not specified' : d),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedDisease = v),
          decoration: _inputDecoration('Disease/Diagnosis', Icons.local_hospital),
        ),
        const SizedBox(height: 12),

        if (hasIIN) ...[
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: _inputDecoration(
              'Temporary Password *',
              Icons.lock_outline,
              helper: 'Patient will use this to log in (min 6 chars)',
            ),
          ),
          const SizedBox(height: 12),
        ],

        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: _inputDecoration('Additional Notes', Icons.note, hint: 'Optional'),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() => _currentStep = _Step.enterIIN),
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _submitNew,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077B6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Add Patient', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}
