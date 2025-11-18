import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MRIViewer extends StatefulWidget {
  const MRIViewer({super.key});

  @override
  State<MRIViewer> createState() => _MRIViewerState();
}

class _MRIViewerState extends State<MRIViewer> {
  File? _imageFile;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(),
      child: Column(
        children: [
          SizedBox(
            height: 500,
            child: _imageFile != null
                ? Image.file(_imageFile!, fit: BoxFit.contain)
                : const Center(child: Text("No image selected")),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Icon(Icons.upload),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
