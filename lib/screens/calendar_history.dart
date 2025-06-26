import 'package:flutter/material.dart';

class CalendarHistoryScreen extends StatelessWidget {
  static const String routeName = '/calendar-history';
  const CalendarHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar History')),
      body: const Center(child: Text('Calendar History Screen')),
    );
  }
} 