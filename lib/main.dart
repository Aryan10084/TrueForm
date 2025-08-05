import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
// Import all screens (to be created in lib/screens/)
import 'screens/splash_login_signup.dart';
import 'screens/dashboard.dart';
import 'screens/plan_selector.dart';
import 'screens/workout_type.dart';
import 'screens/live_workout_mlkit.dart';
import 'screens/session_summary.dart';
import 'screens/calendar_history.dart';
import 'screens/settings.dart';
import 'screens/tutorials.dart';
import 'screens/subscription.dart';
import 'screens/set_rep_timer_edit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TrueFormApp());
}

class TrueFormApp extends StatelessWidget {
  const TrueFormApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrueForm',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF232531),
        primaryColor: const Color(0xFF6C63FF),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6C63FF),
          secondary: const Color(0xFF00E0FF),
          background: const Color(0xFF232531),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2F3A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          labelStyle: const TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
      initialRoute: SplashLoginSignupScreen.routeName,
      routes: {
        SplashLoginSignupScreen.routeName: (context) => const SplashLoginSignupScreen(),
        DashboardScreen.routeName: (context) => const DashboardScreen(),
        PlanSelectorScreen.routeName: (context) => const PlanSelectorScreen(),
        SetRepTimerEditScreen.routeName: (context) => const SetRepTimerEditScreen(),
        WorkoutTypeScreen.routeName: (context) => const WorkoutTypeScreen(),
        LiveWorkoutMLKitScreen.routeName: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return LiveWorkoutMLKitScreen(
            exerciseType: args['exerciseType'] as String,
            sets: args['sets'] as int,
            reps: args['reps'] as int,
            timer: args['timer'] as int,
          );
        },
        SessionSummaryScreen.routeName: (context) => const SessionSummaryScreen(),
        CalendarHistoryScreen.routeName: (context) => const CalendarHistoryScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
        TutorialsScreen.routeName: (context) => const TutorialsScreen(),
        SubscriptionScreen.routeName: (context) => const SubscriptionScreen(),
      },
    );
  }
}
