import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/components/AddPatientDialog.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/pages/profilePage.dart';
import 'package:frontend/pages/analysisPage.dart';
import 'package:frontend/models/patient.dart';
import 'package:frontend/utils/disease_info.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

enum _SortOption { nameAsc, nameDesc, dateNew, dateOld, disease }

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _SortOption _sortOption = _SortOption.nameAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Patient> _filterAndSort(List<Patient> patients) {
    var list = patients.toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            (p.iin?.toLowerCase().contains(q) ?? false) ||
            p.disease.toLowerCase().contains(q);
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

  Future<void> _showAddPatientDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const Addpatientdialog(),
    );

    if (result != null) {
      final authProvider = context.read<AuthProvider>();
      final oldCount = authProvider.patients.length;

      final success = await authProvider.addPatient(
        name: result['name'] ?? '',
        age: result['age'] ?? 0,
        gender: result['gender'] ?? '',
        disease: result['disease'] ?? '',
        notes: result['notes'],
        iin: result['iin'],
        password: result['password'],
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient added successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        final newPatients = authProvider.patients;
        if (newPatients.length > oldCount) {
          final newPatient = newPatients.last;
          authProvider.selectPatient(newPatient);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnalysisPage(patient: newPatient),
            ),
          );
        }
      } else if (mounted && authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Error adding patient'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _sortLabel(_SortOption opt) {
    switch (opt) {
      case _SortOption.nameAsc:
        return 'Name A-Z';
      case _SortOption.nameDesc:
        return 'Name Z-A';
      case _SortOption.dateNew:
        return 'Newest';
      case _SortOption.dateOld:
        return 'Oldest';
      case _SortOption.disease:
        return 'Disease';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final patients = _filterAndSort(authProvider.patients);
            final doctor = authProvider.currentDoctor;

            return Column(
              children: [
                _buildTopBar(doctor, authProvider),
                _buildToolbar(patients.length, authProvider.patients.length),
                Expanded(child: _buildGrid(patients)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(dynamic doctor, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0077B6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.psychology, color: Color(0xFF0077B6), size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MRI Analysis Platform',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF023E8A)),
              ),
              if (doctor != null)
                Text(
                  'Dr. ${doctor.name}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
            ],
          ),
          const Spacer(),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout(context);
              } else if (value == 'profile') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF0077B6),
              child: Text(
                (doctor?.name ?? 'D')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(int filteredCount, int totalCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Text(
            'Patients',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0077B6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$filteredCount',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0077B6)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by name, IIN, or disease...',
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
          ),
          const SizedBox(width: 12),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: PopupMenuButton<_SortOption>(
              onSelected: (v) => setState(() => _sortOption = v),
              tooltip: 'Sort',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(_sortLabel(_sortOption), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey.shade500),
                  ],
                ),
              ),
              itemBuilder: (_) => _SortOption.values
                  .map((opt) => PopupMenuItem(
                        value: opt,
                        child: Row(
                          children: [
                            if (opt == _sortOption)
                              const Icon(Icons.check, size: 14, color: Color(0xFF0077B6))
                            else
                              const SizedBox(width: 14),
                            const SizedBox(width: 8),
                            Text(_sortLabel(opt)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () => _showAddPatientDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Patient', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077B6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Patient> patients) {
    if (patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0077B6).withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty ? 'No patients found' : 'No patients yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search query'
                  : 'Click "Add Patient" to get started',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        if (width > 1400) {
          crossAxisCount = 4;
        } else if (width > 1000) {
          crossAxisCount = 3;
        } else if (width > 650) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          itemCount: patients.length,
          itemBuilder: (context, index) => _PatientGridCard(patient: patients[index]),
        );
      },
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    }
  }
}

class _PatientGridCard extends StatefulWidget {
  const _PatientGridCard({required this.patient});
  final Patient patient;

  @override
  State<_PatientGridCard> createState() => _PatientGridCardState();
}

class _PatientGridCardState extends State<_PatientGridCard> {
  bool _isHovered = false;

  void _openPatient() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.selectPatient(widget.patient);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AnalysisPage(patient: widget.patient)),
    );
  }

  void _unlinkPatient() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Patient'),
        content: Text('Remove ${widget.patient.name} from your patient list?\nThe patient\'s account will not be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AuthProvider>().removePatient(widget.patient.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getDiseaseColor(widget.patient.disease);
    final initials = widget.patient.name.isNotEmpty
        ? widget.patient.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _openPatient,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered ? const Color(0xFF0077B6).withOpacity(0.4) : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered ? const Color(0xFF0077B6).withOpacity(0.08) : Colors.black.withOpacity(0.03),
                blurRadius: _isHovered ? 16 : 6,
                offset: Offset(0, _isHovered ? 6 : 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.patient.disease.isNotEmpty ? color.withOpacity(0.7) : Colors.grey.shade300,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: color.withOpacity(0.15),
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.patient.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              if (widget.patient.iin != null)
                                Text(
                                  'IIN: ${widget.patient.iin}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _InfoChip(icon: Icons.cake_outlined, label: '${widget.patient.age} y.o.'),
                        const SizedBox(width: 8),
                        _InfoChip(icon: Icons.wc, label: widget.patient.gender),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (widget.patient.disease.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.patient.disease,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                            ),
                          )
                        else
                          Text(
                            'No diagnosis',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                          ),
                        const Spacer(),
                        AnimatedOpacity(
                          opacity: _isHovered ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ActionIcon(
                                icon: Icons.open_in_new,
                                tooltip: 'Open',
                                onTap: _openPatient,
                                color: const Color(0xFF0077B6),
                              ),
                              const SizedBox(width: 4),
                              _ActionIcon(
                                icon: Icons.link_off,
                                tooltip: 'Remove',
                                onTap: _unlinkPatient,
                                color: Colors.red.shade400,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.tooltip, required this.onTap, required this.color});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}
