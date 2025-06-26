import 'package:flutter/material.dart';

class WorkoutTypeScreen extends StatelessWidget {
  static const String routeName = '/workout-type';
  const WorkoutTypeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Type')),
      body: const Center(child: Text('Workout Type Screen')),
    );
  }
} 