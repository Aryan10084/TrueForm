import 'package:flutter/material.dart';
import 'live_workout_mlkit.dart';

class SetRepTimerEditScreen extends StatefulWidget {
  static const String routeName = '/set-rep-timer-edit';
  const SetRepTimerEditScreen({Key? key}) : super(key: key);

  @override
  State<SetRepTimerEditScreen> createState() => _SetRepTimerEditScreenState();
}

class _SetRepTimerEditScreenState extends State<SetRepTimerEditScreen> {
  int sets = 5;
  int reps = 10;
  int timer = 30; // seconds

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final exerciseType = args != null && args['exerciseType'] != null ? args['exerciseType'] as String : 'pushup';
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF2196F3)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Edit Workout',
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    radius: 22,
                    child: const Icon(Icons.person, color: Colors.blue, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _EditCard(
              label: 'Sets',
              value: sets,
              onChanged: (v) => setState(() => sets = v),
              min: 1,
              max: 10,
            ),
            const SizedBox(height: 18),
            _EditCard(
              label: 'Reps',
              value: reps,
              onChanged: (v) => setState(() => reps = v),
              min: 1,
              max: 30,
            ),
            const SizedBox(height: 18),
            _EditCard(
              label: 'Timer (sec)',
              value: timer,
              onChanged: (v) => setState(() => timer = v),
              min: 10,
              max: 300,
              step: 10,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      LiveWorkoutMLKitScreen.routeName,
                      arguments: {
                        'exerciseType': exerciseType,
                        'sets': sets,
                        'reps': reps,
                        'timer': timer,
                      },
                    );
                  },
                  child: const Text(
                    'Start Workout',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditCard extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  const _EditCard({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    this.step = 1,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth * 0.85,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Color(0xFF2196F3)),
                onPressed: value > min ? () => onChanged(value - step) : null,
              ),
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF2196F3)),
                onPressed: value < max ? () => onChanged(value + step) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
} 