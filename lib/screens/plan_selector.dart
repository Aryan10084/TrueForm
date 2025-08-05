import 'package:flutter/material.dart';
import 'set_rep_timer_edit.dart';

class PlanSelectorScreen extends StatelessWidget {
  static const String routeName = '/plan-selector';
  const PlanSelectorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final exerciseType = args != null && args['exerciseType'] != null ? args['exerciseType'] as String : 'pushup';
    final plans = [
      {
        'icon': 'assets/beginner_icon.png',
        'label': 'Beginner',
        'desc': '4 Sets × 6 Reps',
        'color': Color(0xFF00BFAE),
      },
      {
        'icon': 'assets/intermediate_icon.png',
        'label': 'Intermediate',
        'desc': '5 Sets × 10 Reps',
        'color': Color(0xFFFF6B81),
      },
      {
        'icon': 'assets/expert_icon.png',
        'label': 'Expert',
        'desc': '5 Sets × 15 Reps',
        'color': Color(0xFFFFB200),
      },
      {
        'icon': 'assets/customize_icon.png',
        'label': 'Customize',
        'desc': '3 Sets × 7 Reps',
        'color': Color(0xFF2196F3),
      },
      {
        'icon': 'assets/opengoal_icon.png',
        'label': 'Opengoal',
        'desc': '4,200 steps | 32 mins',
        'color': Color(0xFF7C4DFF),
      },
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
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: plans.length,
                itemBuilder: (context, idx) {
                  final plan = plans[idx];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        SetRepTimerEditScreen.routeName,
                        arguments: {'exerciseType': exerciseType},
                      );
                    },
                    child: Container(
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
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            plan['icon'] as String,
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            plan['label'] as String,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan['desc'] as String,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 