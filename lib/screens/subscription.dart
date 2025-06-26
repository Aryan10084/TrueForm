import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  static const String routeName = '/subscription';
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: const Center(child: Text('Subscription Screen')),
    );
  }
} 