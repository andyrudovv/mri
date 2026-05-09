import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/patient.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/pages/analysisPage.dart';
import 'package:frontend/utils/disease_info.dart';

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

enum _SortOption { nameAsc, nameDesc, dateNew, dateOld, disease }

class _SideBarState extends State<SideBar> {
  static const double sidebarWidth = 300;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _SortOption _sortOption = _SortOption.nameAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Patient> get _filteredPatients {
    var list = widget.patients.toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            (p.iin?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    switch (_sortOption) {
      case _SortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _SortOption.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case _SortOption.dateNew:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortOption.dateOld:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _SortOption.disease:
        list.sort((a, b) => a.disease.toLowerCase().compareTo(b.disease.toLowerCase()));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPatients;

    return Container(
      width: sidebarWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0077B6),
                  radius: 20,
                  backgroundImage: widget.doctorImage != null
                      ? NetworkImage(widget.doctorImage!)
                      : null,
                  child: widget.doctorImage == null
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Doctor',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: const Color(0xFF0077B6),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => widget.addPatiantFunc(context),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.add, size: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search patients...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF0077B6)),
                ),
              ),
            ),
          ),

          // Sort options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${filtered.length} patients',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const Spacer(),
                PopupMenuButton<_SortOption>(
                  onSelected: (v) => setState(() => _sortOption = v),
                  tooltip: 'Sort',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sort, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text('Sort', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: _SortOption.nameAsc, child: Text('Name A-Z')),
                    PopupMenuItem(value: _SortOption.nameDesc, child: Text('Name Z-A')),
                    PopupMenuItem(value: _SortOption.dateNew, child: Text('Newest first')),
                    PopupMenuItem(value: _SortOption.dateOld, child: Text('Oldest first')),
                    PopupMenuItem(value: _SortOption.disease, child: Text('By disease')),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

          // Patients list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty ? 'No results found' : 'No Patients',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        ),
                        if (_searchQuery.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Click + to add a patient',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _PatientCard(patient: filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatefulWidget {
  const _PatientCard({required this.patient});
  final Patient patient;

  @override
  State<_PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<_PatientCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = getDiseaseColor(widget.patient.disease);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () {
            Provider.of<AuthProvider>(context, listen: false).selectPatient(widget.patient);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnalysisPage(patient: widget.patient),
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _isHovered ? const Color(0xFFE8F4FD) : Colors.white,
              border: Border.all(
                color: _isHovered ? const Color(0xFF0077B6).withOpacity(0.3) : Colors.grey.shade200,
              ),
              boxShadow: _isHovered
                  ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
                  : [],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.cake, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(
                            '${widget.patient.age}y',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.wc, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(
                            widget.patient.gender,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          if (widget.patient.iin != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.badge, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Text(
                              widget.patient.iin!,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ],
                      ),
                      if (widget.patient.disease.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.patient.disease,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        context.read<AuthProvider>().removePatient(widget.patient.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.more_vert, size: 14, color: Colors.grey.shade500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
