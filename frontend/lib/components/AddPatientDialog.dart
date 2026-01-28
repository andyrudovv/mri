import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class Addpatientdialog extends StatefulWidget {
  const Addpatientdialog({super.key});

  @override
  State<Addpatientdialog> createState() => _AddpatientdialogState();
}

class _AddpatientdialogState extends State<Addpatientdialog> {
  File? selectedMRI;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _diseaseController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedGender;

  Future pickMRI() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      selectedMRI = File(image.path);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _diseaseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Patient"),
      content: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600,
              minWidth: 500,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Patient Name
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Patient Name',
                      hintText: "Enter patient's full name",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                // Age
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Age',
                      hintText: "Enter patient's age",
                      prefixIcon: const Icon(Icons.cake),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                // Gender
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedGender,
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: const Icon(Icons.wc),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                // Disease/Diagnosis
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    value: _diseaseController.text.isEmpty
                        ? null
                        : _diseaseController.text,
                    items: const [
                      DropdownMenuItem(value: 'Glioma', child: Text('Glioma')),
                      DropdownMenuItem(value: 'Meningioma', child: Text('Meningioma')),
                      DropdownMenuItem(
                          value: 'Pituitary', child: Text('Pituitary')),
                      DropdownMenuItem(value: 'No Tumor', child: Text('No Tumor')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _diseaseController.text = value;
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Disease/Diagnosis',
                      prefixIcon: const Icon(Icons.local_hospital),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                // Notes
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Additional Notes',
                      hintText: "Add any additional information...",
                      prefixIcon: const Icon(Icons.note),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Upload MRI Button
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: pickMRI,
                    icon: const Icon(Icons.upload_file),
                    label: Text(selectedMRI == null
                        ? "Upload MRI"
                        : "Selected: ${selectedMRI!.path.split('/').last}"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final ageText = _ageController.text.trim();
            final gender = _selectedGender ?? 'Not specified';
            final disease = _diseaseController.text.trim();
            final notes = _notesController.text.trim();

            // Validation
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter patient name')),
              );
              return;
            }

            if (ageText.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter patient age')),
              );
              return;
            }

            if (disease.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a diagnosis')),
              );
              return;
            }

            int age = int.tryParse(ageText) ?? 0;

            if (age <= 0 || age > 150) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid age')),
              );
              return;
            }

            final patient = {
              'name': name,
              'age': age,
              'gender': gender,
              'disease': disease,
              'notes': notes.isEmpty ? null : notes,
              'mriPath': selectedMRI?.path,
            };

            Navigator.pop(context, patient);
          },
          child: const Text("Add"),
        ),
      ],
    );
  }
}
