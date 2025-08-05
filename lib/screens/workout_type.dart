import 'package:flutter/material.dart';
import 'plan_selector.dart';

class WorkoutTypeScreen extends StatelessWidget {
  static const String routeName = '/workout-type';
  const WorkoutTypeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final exercises = [
      {'icon': 'assets/weight_icon.png', 'label': 'Pullups', 'type': 'pullup'},
      {'icon': 'assets/pushup_icon.png', 'label': 'Pushups', 'type': 'pushup'},
      {'icon': 'assets/squat_icon.png', 'label': 'Squats', 'type': 'squat'},
      {'icon': 'assets/other_icon.png', 'label': 'Others', 'type': 'other'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
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
                    'Intensity',
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
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: exercises.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (context, idx) {
                  final ex = exercises[idx];
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      PlanSelectorScreen.routeName,
                      arguments: {'exerciseType': ex['type']},
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00203F),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                      child: Row(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF2196F3),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(12),
                            child: ex['icon'] != null
                                ? Image.asset(
                                    ex['icon'] as String,
                                    width: 32,
                                    height: 32,
                                    color: Colors.white,
                                  )
                                : const Icon(Icons.fitness_center, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Text(
                              ex['label'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward, color: Colors.white, size: 28),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              color: const Color(0xFF2196F3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavIcon(icon: Icons.home, label: 'Home'),
                  _NavIcon(icon: Icons.fitness_center, label: 'Workouts', selected: true),
                  _NavIcon(icon: Icons.menu_book, label: 'Instructions/Tutorial'),
                  _NavIcon(icon: Icons.history, label: 'History'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _NavIcon({required this.icon, required this.label, this.selected = false});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: selected ? Colors.white : Colors.white70, size: 28),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
} 