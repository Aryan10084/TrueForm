import 'package:flutter/material.dart';
import 'dart:math';
import 'live_workout.dart';
import 'profile.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/string_extensions.dart';

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/dashboard';
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  File? profileImage;
  String name = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final imgPath = prefs.getString('profileImage');
    if (imgPath != null) {
      setState(() {
        profileImage = File(imgPath);
      });
    }
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'user@email.com';
    setState(() {
      name = email.split('@').first.split('.').first.capitalize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top wavy background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/Layer_1.png',
              width: screenWidth,
              fit: BoxFit.fitWidth,
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF2196F3)),
                        onPressed: () {}, // Placeholder
                      ),
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          color: Color(0xFF2196F3),
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.055,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                        },
                        child: profileImage != null
                            ? CircleAvatar(
                                backgroundColor: Color(0xFFEAF6FF),
                                radius: screenWidth * 0.06,
                                backgroundImage: FileImage(profileImage!),
                              )
                            : const CircleAvatar(
                                backgroundColor: Color(0xFFEAF6FF),
                                radius: 20,
                                child: Icon(Icons.person, color: Color(0xFF2196F3)),
                              ),
                      ),
                    ],
                  ),
                ),
                // Greeting
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenHeight * 0.01),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good morning,', style: TextStyle(color: Colors.black54, fontSize: screenWidth * 0.045)),
                      SizedBox(height: screenHeight * 0.003),
                      Text(
                        name.isNotEmpty ? name.capitalize() : '',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.06),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                // Stat cards
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _DashboardCard(
                        color: Color(0xFFFFF3F3),
                        borderColor: Color(0xFFFFC1C1),
                        icon: Icons.local_fire_department,
                        iconColor: Color(0xFFFF6B6B),
                        title: 'Calories',
                        subtitle: 'Great Physical activity',
                        value: '700/1290Kcal',
                        time: '1d',
                      ),
                      _DashboardCard(
                        color: Color(0xFFFFFDE7),
                        borderColor: Color(0xFFFFF59D),
                        icon: Icons.verified,
                        iconColor: Color(0xFFFFD600),
                        title: 'Streak Breaks',
                        subtitle: 'Healthy weight is 72-82kg',
                        value: '198 lbs',
                        time: '1d',
                        extra: '6\'0"',
                      ),
                      _DashboardCard(
                        color: Color(0xFFE3F6FF),
                        borderColor: Color(0xFFB3E5FC),
                        icon: Icons.timer,
                        iconColor: Color(0xFF29B6F6),
                        title: 'Sessions',
                        subtitle: 'Full-body workout to boost strength',
                        value: '30min/120kcal',
                        time: '1d',
                      ),
                      _DashboardCard(
                        color: Color(0xFFEDE7F6),
                        borderColor: Color(0xFFD1C4E9),
                        icon: Icons.bar_chart,
                        iconColor: Color(0xFF7C4DFF),
                        title: 'Posture Accuracy',
                        subtitle: 'Measures how correctly your body aligns during exercise.',
                        value: '30min/100 kcal',
                        time: '1d',
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Individual bottom buttons
                Padding(
                  padding: EdgeInsets.only(bottom: screenHeight * 0.03, left: screenWidth * 0.08, right: screenWidth * 0.08),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _BottomButton(icon: Icons.home, label: 'Home', selected: true, onTap: () {}),
                      _BottomButton(icon: Icons.fitness_center, label: 'Workouts', onTap: () {}),
                      _BottomButton(icon: Icons.menu_book, label: 'Tutorial', onTap: () {}),
                      _BottomButton(icon: Icons.history, label: 'History', onTap: () {}),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _DashboardCard extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String value;
  final String time;
  final String? extra;
  const _DashboardCard({
    required this.color,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.time,
    this.extra,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 24,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 28),
              if (extra != null)
                Text(extra!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
              Text(time, style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
        ],
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _BottomButton({required this.icon, required this.label, this.selected = false, required this.onTap, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: selected ? Color(0xFF2196F3) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: Color(0x332196F3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
              ],
            ),
            padding: EdgeInsets.all(screenWidth * 0.035),
            child: Icon(icon, color: selected ? Colors.white : Color(0xFF2196F3)),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? Color(0xFF2196F3) : Colors.black54,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: screenWidth * 0.032,
            ),
          ),
        ],
      ),
    );
  }
} 