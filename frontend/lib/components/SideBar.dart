import 'package:flutter/material.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  double sidebarWidth = 250; // initial sidebar width
  final List<String> chats = const [
    'Alice',
    'Bob',
    'Charlie',
    'David',
    'Eve',
    'Alice',
    'Bob',
    'Charlie',
    'David',
    'Eve',
    'Alice',
    'Bob',
    'Charlie',
    'David',
    'Eve',
    'Alice',
    'Bob',
    'Charlie',
    'David',
    'Eve',
    'Alice',
    'Bob',
    'Charlie',
    'David',
  ];

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
      child: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              child: Text(chats[index][0]),
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            title: Text(chats[index]),
            subtitle: const Text('Last message preview...'),
            onTap: () {
              // handle chat selection
            },
          );
        },
      ),
    );
  }
}