import 'package:flutter/material.dart';
import 'package:frontend/components/MRIViewer.dart';
import 'package:frontend/components/MRIsummary.dart';
import 'package:frontend/components/SideBar.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Row(
        children: [
          const SideBar(),

          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                /// MRI Viewer with REAL height + width constraints
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MRIViewer(),
                  ],
                ),
                
                /// MRI Summary panel
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        
                        onPressed: () {}, 
                        child: Text("Get Analysis")
                      ),
                    ),
                    const MRIsummary(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
