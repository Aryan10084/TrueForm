import 'package:flutter/material.dart';

class SessionSummaryScreen extends StatelessWidget {
  static const String routeName = '/session-summary';
  const SessionSummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Summary')),
      body: const Center(child: Text('Session Summary Screen')),
    );
  }
} 