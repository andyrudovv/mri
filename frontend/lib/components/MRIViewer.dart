import 'dart:io';
import 'package:flutter/material.dart';

class MRIViewer extends StatelessWidget {
  final File? imageFile;

  const MRIViewer({super.key, this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      height: 500,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(10),
      ),
      child: imageFile != null
          ? Image.file(imageFile!, fit: BoxFit.contain)
          : const Center(child: Text("No MRI image selected")),
    );
  }
}
