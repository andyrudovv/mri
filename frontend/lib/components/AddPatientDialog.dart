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

  Future pickMRI() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      selectedMRI = File(image.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Patient"),
      content: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(), // BLABLA BLA
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 800,
              minWidth: 600,
              maxHeight: 700,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
        
                // ROW WITH FORM + AVATAR
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT — Name + Surname
                    Expanded(
                      child: Column(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: TextField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Enter patient's name",
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: TextField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Enter patient's surname",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        
                    const SizedBox(width: 20),
        
                    // RIGHT — Avatar
                    Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.blueGrey,
                              radius: 60,
                            ),
                            Positioned(
                              bottom: -5,
                              right: -5,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(10),
                                ),
                                onPressed: () {},
                                child: const Icon(Icons.edit, size: 18),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
        
                const SizedBox(height: 20),
        
                // ADDITIONAL INFORMATION — FULL WIDTH
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 300,
                    child: TextField(
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Additional information...",
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                ),
        
                const SizedBox(height: 20),
        
                // UPLOAD MRI BUTTON
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: pickMRI,
                    icon: const Icon(Icons.upload_file),
                    label: Text(selectedMRI == null
                        ? "Upload MRI"
                        : "Selected: ${selectedMRI!.path.split('\\').last}"),
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
            // save action here, include selectedMRI if needed
            Navigator.pop(context);
          },
          child: const Text("Add"),
        ),
      ],
    );
  }
}
