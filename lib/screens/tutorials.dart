import 'package:flutter/material.dart';

class TutorialsScreen extends StatelessWidget {
  static const String routeName = '/tutorials';
  const TutorialsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutorials')),
      body: const Center(child: Text('Tutorials Screen')),
    );
  }
} 