import 'package:flutter/material.dart';
import 'package:frontend/components/AddPatientDialog.dart';
import 'package:frontend/components/MRIViewer.dart';
import 'package:frontend/components/MRIsummary.dart';
import 'package:frontend/components/SideBar.dart';

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
  void _showAddPatientDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Addpatientdialog(),
    );
  }

  /// Upload & Predict MRI
  Future<String> predictMRI(File imageFile) async {
    final String url = "http://127.0.0.1:8000/predict";

    String fileName = imageFile.path.split('/').last;

    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      )
    });

    try {
      final response = await dio.post(url, data: formData);

      final disg = response.data["prediction"]["predicted_class"].toString();
      final probs = response.data["prediction"]["probabilities"].toString();

      return "$disg $probs";
    } catch (e) {
      print("Prediction error: $e");
      return "error";
    }
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

  /// Run prediction
  Future runAnalysis() async {
    if (selectedImage == null) {
      setState(() {
        predictionResult = "Please select an MRI image first.";
      });
      return;
    }

    String result = await predictMRI(selectedImage!);

    setState(() {
      predictionResult = result;
    });
  }

  /// ---------------------------
  /// UI
  /// ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Row(
        children: [
          SideBar(addPatiantFunc: _showAddPatientDialog),

          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 9.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          CircleAvatar(
                            backgroundColor: Colors.greenAccent,
                            radius: 15,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Name",
                          ),
                        ],
                      ),
                      
                    ],
                  ),
                ),

                Divider(height: 1, thickness: 1, color: Colors.grey.shade300),

                Column(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
