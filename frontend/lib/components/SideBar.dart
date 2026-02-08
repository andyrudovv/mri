import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/patient.dart';
import 'package:frontend/providers/auth_provider.dart';

class SideBar extends StatefulWidget {
  const SideBar({
    super.key,
    required this.addPatiantFunc,
    required this.patients,
    this.doctorName = 'Doctor',
    this.doctorImage,
  });

  final Future<void> Function(BuildContext context) addPatiantFunc;
  final List<Patient> patients;
  final String doctorName;
  final String? doctorImage;

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  static const double sidebarWidth = 300;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: sidebarWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade300,
            width: 4,
          ),
        ),
      ),
      child: Column(
        children: [
          // ================= HEADER =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                // LEFT PART (avatar + name)
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blueGrey,
                        radius: 18,
                        backgroundImage: widget.doctorImage != null
                            ? NetworkImage(widget.doctorImage!)
                            : null,
                        child: widget.doctorImage == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.doctorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Dr.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ADD PATIENT BUTTON
                ElevatedButton(
                  onPressed: () => widget.addPatiantFunc(context),
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all(const CircleBorder()),
                    padding: MaterialStateProperty.all(const EdgeInsets.all(12)),
                    elevation: MaterialStateProperty.all(0),
                    backgroundColor:
                        MaterialStateProperty.all(Colors.lightBlue),
                  ),
                  child:
                      const Icon(Icons.add, size: 20, color: Colors.white),
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: Colors.grey.shade300),

          // ================= PATIENTS LIST =================
          Expanded(
            child: widget.patients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No Patients',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Click + to add a patient',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    itemCount: widget.patients.length,
                    itemBuilder: (context, index) {
                      final patient = widget.patients[index];
                      return _PatientCard(patient: patient);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// =================== PATIENT CARD ======================
// =======================================================

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          Provider.of<AuthProvider>(context, listen: false).selectPatient(patient);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected: ${patient.name}')),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.cake,
                            size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${patient.age} years',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.wc,
                            size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          patient.gender,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _diseaseColor(patient.disease).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        patient.disease,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _diseaseColor(patient.disease),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // MENU
              Positioned(
                top: 4,
                right: 4,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      context
                          .read<AuthProvider>()
                          .removePatient(patient.id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.more_vert,
                        size: 16, color: Colors.grey.shade600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _diseaseColor(String disease) {
    final d = disease.toLowerCase();
    if (d.contains('glioma')) return Colors.red;
    if (d.contains('meningioma')) return Colors.orange;
    if (d.contains('pituitary')) return Colors.purple;
    if (d.contains('no')) return Colors.green;
    return Colors.blue;
  }
}
