import 'package:flutter/material.dart';


class PatientCart extends StatelessWidget {
  final String name;
  final String diagnose;
  final int index;

  const PatientCart({super.key, required this.index, required this.name, required this.diagnose});


  @override
  Widget build(BuildContext context) {
    final avatarChar = (name.isNotEmpty) ? name[0].toUpperCase() : '?';

    return ListTile(
      leading: CircleAvatar(
        child: Text(avatarChar),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      title: Text(name),
      subtitle: Text(diagnose),
      onTap: () {},
    );
  }
}