import 'package:flutter/material.dart';

class PlanSelectorScreen extends StatelessWidget {
  static const String routeName = '/plan-selector';
  const PlanSelectorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan Selector')),
      body: const Center(child: Text('Plan Selector Screen')),
    );
  }
} 