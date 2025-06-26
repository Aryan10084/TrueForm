import 'package:flutter/material.dart';
import 'dart:math';
import 'live_workout.dart';

class DashboardScreen extends StatelessWidget {
  static const String routeName = '/dashboard';
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232531),
      body: SafeArea(
        child: Column(
          children: [
            // Profile and greeting
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Color(0xFF232531)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text('Hello,', style: TextStyle(color: Colors.white, fontSize: 18)),
                          Text('Alice ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('👋', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Tuesday, 24 July', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            // Progress ring and stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress ring
                  CustomPaint(
                    painter: _MultiRingPainter(),
                    child: const SizedBox(width: 120, height: 120),
                  ),
                  const SizedBox(width: 24),
                  // Stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SizedBox(height: 8),
                        Text('Calories burn', style: TextStyle(color: Colors.white54, fontSize: 14)),
                        Text('1074', style: TextStyle(color: Color(0xFFFF4D6D), fontWeight: FontWeight.bold, fontSize: 22)),
                        SizedBox(height: 8),
                        Text('Workout time', style: TextStyle(color: Colors.white54, fontSize: 14)),
                        Text('1hr 24min', style: TextStyle(color: Color(0xFFB2FF59), fontWeight: FontWeight.bold, fontSize: 22)),
                        SizedBox(height: 8),
                        Text('No of seasons', style: TextStyle(color: Colors.white54, fontSize: 14)),
                        Text('4', style: TextStyle(color: Color(0xFF00E0FF), fontWeight: FontWeight.bold, fontSize: 22)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Start Workout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, LiveWorkoutScreen.routeName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Start Workout'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Steps and Streaks
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Steps',
                      subtitle: '2h ago',
                      child: _StepsRing(steps: 5623, percent: 0.7),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Streaks',
                      subtitle: '69 Days',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.local_fire_department, color: Color(0xFFFFA726), size: 40),
                          SizedBox(height: 8),
                          Text('69 Days', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Posture accuracy
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Posture accuracy', style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('3h ago', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: CustomPaint(
                        painter: _LineChartPainter(),
                        child: Container(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.center,
                      child: Text('74%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF232531),
        selectedItemColor: const Color(0xFFB2FF59),
        unselectedItemColor: Colors.white38,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
        onTap: (i) {},
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: false,
      ),
    );
  }
}

class _MultiRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final rings = [
      [0.0, 0.8, Color(0xFF00E0FF)],
      [0.0, 0.6, Color(0xFFB2FF59)],
      [0.0, 0.4, Color(0xFFFF4D6D)],
    ];
    for (var i = 0; i < rings.length; i++) {
      final paint = Paint()
        ..color = rings[i][2] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16 - i * 4
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - i * 10),
        -pi / 2,
        2 * pi * (rings[i][1] as double),
        false,
        paint,
      );
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StepsRing extends StatelessWidget {
  final int steps;
  final double percent;
  const _StepsRing({required this.steps, required this.percent});
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            value: percent,
            strokeWidth: 8,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB2FF59)),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$steps', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Steps', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _StatCard({required this.title, required this.subtitle, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Center(child: child),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E0FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.2, size.height * 0.4),
      Offset(size.width * 0.4, size.height * 0.6),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.5),
      Offset(size.width, size.height * 0.4),
    ];
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 