import 'package:flutter/material.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  // Use const for variables that don't change
  static const double sidebarWidth = 300; 
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
          // 1. Top Bar (User Profile & New Chat Button)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // User Profile Section
                Row(
                  mainAxisSize: MainAxisSize.min, // Prevents layout overflow
                  children: <Widget>[
                    const CircleAvatar(
                      backgroundColor: Colors.blueGrey,
                      radius: 15,
                    ),
                    const SizedBox(width: 8), // Spacing
                    const Text(
                      "My Name",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                // Circular New Chat Button
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement new chat functionality
                  },
                  style: ButtonStyle(
                    // Set the shape to CircleBorder
                    shape: WidgetStateProperty.all<OutlinedBorder>(
                      const CircleBorder(),
                    ),
                    // Set padding to control the size of the circle
                    padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(12),
                    ),
                    // Optional: Remove shadow
                    elevation: WidgetStateProperty.all(0),
                  ),
                  child: const Icon(Icons.add, size: 20),
                )
              ],
            ),
          ),
          
          // Separator line
          Divider(height: 1, thickness: 1, color: Colors.grey.shade300),

          // 2. Chat List (Takes up ALL remaining vertical height)
          Expanded( // FIX: Gives the ListView constrained height
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      color: Colors.grey.shade200,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(chats[index][0]),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      title: Text(chats[index]),
                      subtitle: const Text('Diagnose'),
                      onTap: () {
                        // TODO: handle chat selection
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}