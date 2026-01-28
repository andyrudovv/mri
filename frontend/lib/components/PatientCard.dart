import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/patient.dart';
import 'package:frontend/providers/auth_provider.dart';

class PatientCard extends StatelessWidget {
  final Patient patient;
  final int index;

  const PatientCard({
    super.key,
    required this.patient,
    required this.index,
  });

  Color _getDiseaseColor(String disease) {
    switch (disease.toLowerCase()) {
      case 'glioma':
        return Colors.red.shade200;
      case 'meningioma':
        return Colors.orange.shade200;
      case 'pituitary':
        return Colors.purple.shade200;
      case 'no tumor':
        return Colors.green.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getDiseaseTextColor(String disease) {
    switch (disease.toLowerCase()) {
      case 'glioma':
        return Colors.red.shade700;
      case 'meningioma':
        return Colors.orange.shade700;
      case 'pituitary':
        return Colors.purple.shade700;
      case 'no tumor':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarChar = patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to patient detail page
      },
      onLongPress: () {
        _showDeleteConfirmation(context);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient name and avatar
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    radius: 18,
                    child: Text(
                      avatarChar,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          patient.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Age: ${patient.age}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteConfirmation(context);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Gender and Disease info
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Gender: ${patient.gender}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Disease badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDiseaseColor(patient.disease),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  patient.disease,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getDiseaseTextColor(patient.disease),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text('Are you sure you want to delete ${patient.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false)
                  .removePatient(patient.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
