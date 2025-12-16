import 'package:flutter/material.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key, required this.addPatiantFunc});

  final void Function(BuildContext context) addPatiantFunc;

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  static const double sidebarWidth = 300;

  final List<String> chats = const [
    'Alice', 'Bob', 'Charlie', 'David', 'Eve',
    'Mark', 'Julia', 'Sasha', 'Tom', 'Leo',
    'Alex', 'Sara', 'John', 'Nina', 'Max'
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    CircleAvatar(
                      backgroundColor: Colors.blueGrey,
                      radius: 15,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "My Name",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                ElevatedButton(
                  onPressed: () {
                    widget.addPatiantFunc(context);
                  },
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all(const CircleBorder()),
                    padding: WidgetStateProperty.all(const EdgeInsets.all(12)),
                    elevation: WidgetStateProperty.all(0),
                  ),
                  child: const Icon(Icons.add, size: 20),
                )
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: Colors.grey.shade300),

          Expanded(
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
                      onTap: () {},
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
