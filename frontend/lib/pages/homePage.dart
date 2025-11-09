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
      appBar: AppBar(
        title: const Text('MRIs'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              const SideBar(),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 500,
                        maxHeight: 500,
                        minWidth: 200,
                        minHeight: 200,
                      ),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: MRIViewer(
                          
                        ),
                      ),
                    ),
                    MRIsummary()
                  ]
                ),
              ),
            ],
          );
        },
      )
      
    );
  }
}
