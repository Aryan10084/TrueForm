import 'package:flutter/services.dart';
import '../utils/exercise_tracker.dart';

/// Audio feedback system for workout guidance
class AudioFeedback {
  static const Duration _minFeedbackInterval = Duration(seconds: 3);
  DateTime? _lastRepFeedback;
  DateTime? _lastFormFeedback;
  
  /// Play rep count feedback
  Future<void> playRepCountFeedback(int repCount) async {
    final now = DateTime.now();
    if (_lastRepFeedback != null && 
        now.difference(_lastRepFeedback!) < const Duration(milliseconds: 500)) {
      return; // Prevent spam
    }
    
    _lastRepFeedback = now;
    
    // Provide haptic feedback for rep
    await HapticFeedback.mediumImpact();
    
    // In a real app, you could use text-to-speech or audio files
    // For now, we'll use different haptic patterns
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }
  
  /// Play form feedback based on quality
  Future<void> playFormFeedback(FormFeedback feedback, String message) async {
    final now = DateTime.now();
    if (_lastFormFeedback != null && 
        now.difference(_lastFormFeedback!) < _minFeedbackInterval) {
      return; // Don't spam feedback
    }
    
    _lastFormFeedback = now;
    
    switch (feedback) {
      case FormFeedback.excellent:
        await HapticFeedback.mediumImpact();
        break;
      case FormFeedback.good:
        await HapticFeedback.lightImpact();
        break;
      case FormFeedback.needsCorrection:
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 200));
        await HapticFeedback.heavyImpact();
        break;
      case FormFeedback.poor:
        // Strong vibration pattern for poor form
        for (int i = 0; i < 3; i++) {
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
        }
        break;
      case FormFeedback.noDetection:
        await HapticFeedback.selectionClick();
        break;
    }
  }
  
  /// Play workout completion feedback
  Future<void> playWorkoutComplete() async {
    // Celebratory pattern
    for (int i = 0; i < 5; i++) {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }
  
  /// Play set completion feedback
  Future<void> playSetComplete() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.heavyImpact();
  }
  
  /// Play rest timer feedback
  Future<void> playRestTimerTick(int secondsRemaining) async {
    if (secondsRemaining <= 3 && secondsRemaining > 0) {
      await HapticFeedback.mediumImpact();
    } else if (secondsRemaining == 0) {
      await playSetComplete(); // Rest is over
    }
  }
} 