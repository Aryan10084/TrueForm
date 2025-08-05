import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Exercise tracking and rep counting logic for different workout types
class ExerciseTracker {
  final String exerciseType;
  
  // Rep counting state
  int _repCount = 0;
  bool _inDownPosition = false;
  bool _inUpPosition = false;
  int _consecutiveFrames = 0;
  static const int _requiredFrames = 3; // Frames needed to confirm position
  
  // Form feedback state
  FormFeedback _currentFeedback = FormFeedback.good;
  String _feedbackMessage = "";
  
  ExerciseTracker(this.exerciseType);
  
  int get repCount => _repCount;
  FormFeedback get currentFeedback => _currentFeedback;
  String get feedbackMessage => _feedbackMessage;
  
  void resetReps() {
    _repCount = 0;
    _inDownPosition = false;
    _inUpPosition = false;
    _consecutiveFrames = 0;
  }
  
  /// Process pose keypoints and update rep count and feedback
  ExerciseResult processFrame(List<List<double>> keypoints) {
    if (keypoints.length < 33) {
      return ExerciseResult(
        repCounted: false,
        feedback: FormFeedback.noDetection,
        message: "No pose detected",
      );
    }
    
    switch (exerciseType.toLowerCase()) {
      case 'pushup':
      case 'push-up':
      case 'pushups':
      case 'push-ups':
        return _processPushUp(keypoints);
      case 'squat':
      case 'squats':
        return _processSquat(keypoints);
      case 'plank':
      case 'planks':
        return _processPlank(keypoints);
      case 'pullup':
      case 'pull-up':
      case 'pullups':
      case 'pull-ups':
        return _processPullUp(keypoints);
      case 'situp':
      case 'sit-up':
      case 'situps':
      case 'sit-ups':
        return _processSitUp(keypoints);
      case 'lunge':
      case 'lunges':
        return _processLunge(keypoints);
      default:
        return _processGeneric(keypoints);
    }
  }
  
  /// Push-up tracking logic (improved based on WorkOut.ai)
  ExerciseResult _processPushUp(List<List<double>> keypoints) {
    // Key points: shoulders (11, 12), elbows (13, 14), wrists (15, 16), hips (23, 24)
    final leftShoulder = keypoints[11];
    final rightShoulder = keypoints[12];
    final leftElbow = keypoints[13];
    final rightElbow = keypoints[14];
    final leftWrist = keypoints[15];
    final rightWrist = keypoints[16];
    final leftHip = keypoints[23];
    final rightHip = keypoints[24];
    
    // Check if key points are visible
    if (_getAverageConfidence([leftShoulder, rightShoulder, leftElbow, rightElbow]) < 0.5) {
      return ExerciseResult(
        repCounted: false,
        feedback: FormFeedback.poor,
        message: "Position yourself so your upper body is clearly visible",
      );
    }
    
    // Calculate angles for form analysis (based on WorkOut.ai)
    double? leftElbowAngle;
    double? rightElbowAngle;
    double? bodyAlignment;
    
    if (leftElbow[2] > 0.3 && leftShoulder[2] > 0.3 && leftWrist[2] > 0.3) {
      leftElbowAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
    }
    
    if (rightElbow[2] > 0.3 && rightShoulder[2] > 0.3 && rightWrist[2] > 0.3) {
      rightElbowAngle = _calculateAngle(rightShoulder, rightElbow, rightWrist);
    }
    
    // Check body alignment (straight line from shoulders to hips)
    if (leftShoulder[2] > 0.3 && rightShoulder[2] > 0.3 && leftHip[2] > 0.3 && rightHip[2] > 0.3) {
      final shoulderY = (leftShoulder[0] + rightShoulder[0]) / 2;
      final hipY = (leftHip[0] + rightHip[0]) / 2;
      bodyAlignment = (shoulderY - hipY).abs();
    }
    
    // Determine push-up state based on elbow angles (WorkOut.ai logic)
    bool isDown = false;
    bool isUp = false;
    String formFeedback = "";
    double accuracyScore = 100.0;
    
    if (leftElbowAngle != null && rightElbowAngle != null) {
      final avgElbowAngle = (leftElbowAngle + rightElbowAngle) / 2;
      
      // Push-up state detection
      if (avgElbowAngle < 90) {
        isDown = true; // Elbows bent (down position)
        isUp = false;
      } else if (avgElbowAngle > 160) {
        isUp = true; // Arms extended (up position)
        isDown = false;
      }
      
      // Form analysis
      if (avgElbowAngle < 60) {
        formFeedback = "Go lower - elbows should be at 90 degrees";
        accuracyScore = 70.0;
      } else if (avgElbowAngle > 170) {
        formFeedback = "Good extension!";
      } else if (avgElbowAngle >= 90 && avgElbowAngle <= 160) {
        formFeedback = "Good form!";
      }
    }
    
    // Body alignment check
    if (bodyAlignment != null && bodyAlignment > 0.1) {
      formFeedback += " Keep your body straight";
      accuracyScore = math.min(accuracyScore, 85.0);
    }
    
    // Update rep count
    Map<String, double> anglesMap = {};
    if (leftElbowAngle != null) anglesMap['leftElbowAngle'] = leftElbowAngle;
    if (rightElbowAngle != null) anglesMap['rightElbowAngle'] = rightElbowAngle;
    if (bodyAlignment != null) anglesMap['bodyAlignment'] = bodyAlignment;
    
    return _updateRepCount(isDown, isUp, 
      formFeedback.isNotEmpty ? FormFeedback.needsCorrection : FormFeedback.good,
      formFeedback.isNotEmpty ? formFeedback : "Good form!",
      accuracyScore: accuracyScore,
      angles: anglesMap.isNotEmpty ? anglesMap : null
    );
  }
  
  /// Squat tracking logic (based on WorkOut.ai)
  ExerciseResult _processSquat(List<List<double>> keypoints) {
    // Key points: hips (23, 24), knees (25, 26), ankles (27, 28)
    final leftHip = keypoints[23];
    final rightHip = keypoints[24];
    final leftKnee = keypoints[25];
    final rightKnee = keypoints[26];
    final leftAnkle = keypoints[27];
    final rightAnkle = keypoints[28];
    final leftShoulder = keypoints[11];
    final rightShoulder = keypoints[12];
    
    // Check if key points are visible
    if (_getAverageConfidence([leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle]) < 0.5) {
      return ExerciseResult(
        repCounted: false,
        feedback: FormFeedback.poor,
        message: "Position yourself so your legs are clearly visible",
      );
    }
    
    // Calculate knee angles for form analysis
    double? leftKneeAngle;
    double? rightKneeAngle;
    double? bodyAlignment;
    
    if (leftHip[2] > 0.3 && leftKnee[2] > 0.3 && leftAnkle[2] > 0.3) {
      leftKneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
    }
    
    if (rightHip[2] > 0.3 && rightKnee[2] > 0.3 && rightAnkle[2] > 0.3) {
      rightKneeAngle = _calculateAngle(rightHip, rightKnee, rightAnkle);
    }
    
    // Check body alignment (shoulders to hips)
    if (leftShoulder[2] > 0.3 && rightShoulder[2] > 0.3 && leftHip[2] > 0.3 && rightHip[2] > 0.3) {
      final shoulderY = (leftShoulder[0] + rightShoulder[0]) / 2;
      final hipY = (leftHip[0] + rightHip[0]) / 2;
      bodyAlignment = (shoulderY - hipY).abs();
    }
    
    // Determine squat state based on knee angles
    bool isDown = false;
    bool isUp = false;
    String formFeedback = "";
    double accuracyScore = 100.0;
    
    if (leftKneeAngle != null && rightKneeAngle != null) {
      final avgKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;
      
      // Squat state detection
      if (avgKneeAngle < 120) {
        isDown = true; // Knees bent (down position)
        isUp = false;
      } else if (avgKneeAngle > 160) {
        isUp = true; // Legs extended (up position)
        isDown = false;
      }
      
      // Form analysis
      if (avgKneeAngle < 90) {
        formFeedback = "Go deeper - aim for thighs parallel to ground";
        accuracyScore = 75.0;
      } else if (avgKneeAngle > 170) {
        formFeedback = "Good extension!";
      } else if (avgKneeAngle >= 120 && avgKneeAngle <= 160) {
        formFeedback = "Good form!";
      }
    }
    
    // Body alignment check
    if (bodyAlignment != null && bodyAlignment > 0.1) {
      formFeedback += " Keep your back straight";
      accuracyScore = math.min(accuracyScore, 85.0);
    }
    
    // Update rep count
    Map<String, double> anglesMap = {};
    if (leftKneeAngle != null) anglesMap['leftKneeAngle'] = leftKneeAngle;
    if (rightKneeAngle != null) anglesMap['rightKneeAngle'] = rightKneeAngle;
    if (bodyAlignment != null) anglesMap['bodyAlignment'] = bodyAlignment;
    
    return _updateRepCount(isDown, isUp,
      formFeedback.isNotEmpty ? FormFeedback.needsCorrection : FormFeedback.good,
      formFeedback.isNotEmpty ? formFeedback : "Good form!",
      accuracyScore: accuracyScore,
      angles: anglesMap.isNotEmpty ? anglesMap : null
    );
  }
  
  /// Plank tracking logic (not rep-based, but holds)
  ExerciseResult _processPlank(List<List<double>> keypoints) {
    final leftShoulder = keypoints[11];
    final rightShoulder = keypoints[12];
    final leftHip = keypoints[23];
    final rightHip = keypoints[24];
    final leftAnkle = keypoints[27];
    final rightAnkle = keypoints[28];
    
    if (_getAverageConfidence([leftShoulder, rightShoulder, leftHip, rightHip]) < 0.5) {
      return ExerciseResult(
        repCounted: false,
        feedback: FormFeedback.poor,
        message: "Position yourself so your body is clearly visible",
      );
    }
    
    final double shoulderY = (leftShoulder[0] + rightShoulder[0]) / 2;
    final double hipY = (leftHip[0] + rightHip[0]) / 2;
    final double ankleY = (leftAnkle[0] + rightAnkle[0]) / 2;
    
    // Check plank alignment - body should be straight
    final double bodyLine1 = (shoulderY - hipY).abs();
    final double bodyLine2 = (hipY - ankleY).abs();
    
    FormFeedback feedback;
    String message;
    
    if (bodyLine1 < 0.05 && bodyLine2 < 0.05) {
      feedback = FormFeedback.excellent;
      message = "Perfect plank form!";
    } else if (hipY > shoulderY + 0.05) {
      feedback = FormFeedback.needsCorrection;
      message = "Lift your hips - avoid sagging";
    } else if (hipY < shoulderY - 0.05) {
      feedback = FormFeedback.needsCorrection;
      message = "Lower your hips - avoid piking";
    } else {
      feedback = FormFeedback.good;
      message = "Hold steady!";
    }
    
    return ExerciseResult(repCounted: false, feedback: feedback, message: message);
  }
  
  /// Pull-up tracking logic
  ExerciseResult _processPullUp(List<List<double>> keypoints) {
    final leftShoulder = keypoints[11];
    final rightShoulder = keypoints[12];
    final leftElbow = keypoints[13];
    final rightElbow = keypoints[14];
    final leftWrist = keypoints[15];
    final rightWrist = keypoints[16];
    
    if (_getAverageConfidence([leftShoulder, rightShoulder, leftElbow, rightElbow]) < 0.5) {
      return ExerciseResult(
        repCounted: false,
        feedback: FormFeedback.poor,
        message: "Position yourself so your upper body is clearly visible",
      );
    }
    
    final double shoulderY = (leftShoulder[0] + rightShoulder[0]) / 2;
    final double elbowY = (leftElbow[0] + rightElbow[0]) / 2;
    final double wristY = (leftWrist[0] + rightWrist[0]) / 2;
    
    // Pull-up: chin should come above the bar (wrists)
    final bool isUp = shoulderY < wristY - 0.05;   // Shoulders above wrists
    final bool isDown = shoulderY > wristY + 0.1;  // Shoulders well below wrists
    
    String formFeedback = isUp ? "Great pull-up!" : "Pull higher to complete the rep";
    
    return _updateRepCount(isDown, isUp, FormFeedback.good, formFeedback);
  }
  
  /// Sit-up tracking logic
  ExerciseResult _processSitUp(List<List<double>> keypoints) {
    final nose = keypoints[0];
    final leftShoulder = keypoints[11];
    final rightShoulder = keypoints[12];
    final leftHip = keypoints[23];
    final rightHip = keypoints[24];
    
    if (_getAverageConfidence([nose, leftShoulder, rightShoulder, leftHip, rightHip]) < 0.5) {
      return ExerciseResult(
        repCounted: false,
        feedback: FormFeedback.poor,
        message: "Position yourself so your torso is clearly visible",
      );
    }
    
    final double headY = nose[0];
    final double shoulderY = (leftShoulder[0] + rightShoulder[0]) / 2;
    final double hipY = (leftHip[0] + rightHip[0]) / 2;
    
    // Sit-up: torso should come up significantly
    final bool isUp = shoulderY < hipY - 0.1;    // Shoulders well above hips
    final bool isDown = shoulderY > hipY + 0.05; // Shoulders at or below hip level
    
    String formFeedback = isUp ? "Good sit-up!" : "Lift your torso higher";
    
    return _updateRepCount(isDown, isUp, FormFeedback.good, formFeedback);
  }
  
  /// Lunge tracking logic
  ExerciseResult _processLunge(List<List<double>> keypoints) {
    final leftHip = keypoints[23];
    final rightHip = keypoints[24];
    final leftKnee = keypoints[25];
    final rightKnee = keypoints[26];
    final leftAnkle = keypoints[27];
    final rightAnkle = keypoints[28];
    
    if (_getAverageConfidence([leftHip, rightHip, leftKnee, rightKnee]) < 0.5) {
      return ExerciseResult(
        repCounted: false,
        feedback: FormFeedback.poor,
        message: "Position yourself so your legs are clearly visible",
      );
    }
    
    final double hipY = (leftHip[0] + rightHip[0]) / 2;
    final double frontKneeY = math.min(leftKnee[0], rightKnee[0]);
    
    // Lunge depth: front knee should bend significantly
    final bool isDown = hipY > frontKneeY + 0.08; // Deep lunge position
    final bool isUp = hipY < frontKneeY + 0.02;   // Standing position
    
    String formFeedback = isDown ? "Good lunge depth!" : "Lunge deeper";
    
    return _updateRepCount(isDown, isUp, FormFeedback.good, formFeedback);
  }
  
  /// Generic exercise tracking
  ExerciseResult _processGeneric(List<List<double>> keypoints) {
    return ExerciseResult(
      repCounted: false,
      feedback: FormFeedback.good,
      message: "Exercise detected - manual counting",
    );
  }
  
  /// Update rep count based on position detection
  ExerciseResult _updateRepCount(bool isDown, bool isUp, FormFeedback feedback, String message, {
    double accuracyScore = 100.0,
    Map<String, double>? angles,
  }) {
    bool repCounted = false;
    
    // State machine for rep counting
    if (isDown && !_inDownPosition) {
      _consecutiveFrames++;
      if (_consecutiveFrames >= _requiredFrames) {
        _inDownPosition = true;
        _inUpPosition = false;
        _consecutiveFrames = 0;
      }
    } else if (isUp && _inDownPosition && !_inUpPosition) {
      _consecutiveFrames++;
      if (_consecutiveFrames >= _requiredFrames) {
        _inUpPosition = true;
        _consecutiveFrames = 0;
      }
    } else if (isUp && _inDownPosition && _inUpPosition) {
      // Complete rep: down -> up
      _repCount++;
      repCounted = true;
      _inDownPosition = false;
      _inUpPosition = false;
      _consecutiveFrames = 0;
    } else if (!isDown && !isUp) {
      _consecutiveFrames = 0;
    }
    
    _currentFeedback = feedback;
    _feedbackMessage = message;
    
    return ExerciseResult(
      repCounted: repCounted,
      feedback: feedback,
      message: message,
      accuracyScore: accuracyScore,
      angles: angles,
    );
  }
  
  /// Calculate average confidence for a set of keypoints
  double _getAverageConfidence(List<List<double>> keypoints) {
    if (keypoints.isEmpty) return 0.0;
    double totalConfidence = 0.0;
    for (final kp in keypoints) {
      totalConfidence += kp[2]; // confidence is the third value
    }
    return totalConfidence / keypoints.length;
  }
  
  /// Calculate angle between three points (improved from WorkOut.ai)
  double _calculateAngle(List<double> a, List<double> b, List<double> c) {
    final radians = math.atan2(c[1] - b[1], c[0] - b[0]) - 
                    math.atan2(a[1] - b[1], a[0] - b[0]);
    double angle = (radians * 180.0 / math.pi).abs();
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }
  
  /// Calculate form accuracy score (0-100)
  double _calculateFormAccuracy(List<List<double>> keypoints, String exerciseType) {
    double accuracy = 100.0;
    
    switch (exerciseType.toLowerCase()) {
      case 'pushup':
        accuracy = _calculatePushupAccuracy(keypoints, accuracy);
        break;
      case 'squat':
        accuracy = _calculateSquatAccuracy(keypoints, accuracy);
        break;
      case 'pullup':
        accuracy = _calculatePullupAccuracy(keypoints, accuracy);
        break;
    }
    
    return accuracy.clamp(0.0, 100.0);
  }
  
  /// Calculate push-up specific accuracy
  double _calculatePushupAccuracy(List<List<double>> keypoints, double baseAccuracy) {
    double accuracy = baseAccuracy;
    
    final leftShoulder = keypoints[11];
    final rightShoulder = keypoints[12];
    final leftElbow = keypoints[13];
    final rightElbow = keypoints[14];
    final leftWrist = keypoints[15];
    final rightWrist = keypoints[16];
    
    // Check elbow angle consistency
    if (leftElbow[2] > 0.5 && rightElbow[2] > 0.5) {
      final leftAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
      final rightAngle = _calculateAngle(rightShoulder, rightElbow, rightWrist);
      final angleDiff = (leftAngle - rightAngle).abs();
      
      if (angleDiff > 20) {
        accuracy -= 15; // Penalize for uneven arm movement
      }
    }
    
    // Check body alignment
    final leftHip = keypoints[23];
    final rightHip = keypoints[24];
    if (leftShoulder[2] > 0.5 && leftHip[2] > 0.5) {
      final bodyAngle = _calculateAngle(leftShoulder, leftHip, leftWrist);
      if (bodyAngle < 160) {
        accuracy -= 10; // Penalize for poor body alignment
      }
    }
    
    return accuracy;
  }
  
  /// Calculate squat specific accuracy
  double _calculateSquatAccuracy(List<List<double>> keypoints, double baseAccuracy) {
    double accuracy = baseAccuracy;
    
    final leftHip = keypoints[23];
    final rightHip = keypoints[24];
    final leftKnee = keypoints[25];
    final rightKnee = keypoints[26];
    final leftAnkle = keypoints[27];
    final rightAnkle = keypoints[28];
    
    // Check knee angle consistency
    if (leftKnee[2] > 0.5 && rightKnee[2] > 0.5) {
      final leftAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
      final rightAngle = _calculateAngle(rightHip, rightKnee, rightAnkle);
      final angleDiff = (leftAngle - rightAngle).abs();
      
      if (angleDiff > 15) {
        accuracy -= 15; // Penalize for uneven knee movement
      }
    }
    
    return accuracy;
  }
  
  /// Calculate pull-up specific accuracy
  double _calculatePullupAccuracy(List<List<double>> keypoints, double baseAccuracy) {
    double accuracy = baseAccuracy;
    
    final leftShoulder = keypoints[11];
    final rightShoulder = keypoints[12];
    final leftElbow = keypoints[13];
    final rightElbow = keypoints[14];
    final leftWrist = keypoints[15];
    final rightWrist = keypoints[16];
    
    // Check elbow angle consistency
    if (leftElbow[2] > 0.5 && rightElbow[2] > 0.5) {
      final leftAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
      final rightAngle = _calculateAngle(rightShoulder, rightElbow, rightWrist);
      final angleDiff = (leftAngle - rightAngle).abs();
      
      if (angleDiff > 25) {
        accuracy -= 20; // Penalize for uneven pull
      }
    }
    
    return accuracy;
  }
}

/// Feedback levels for exercise form
enum FormFeedback {
  excellent,
  good,
  needsCorrection,
  poor,
  noDetection,
}

/// Result of processing a single frame
class ExerciseResult {
  final bool repCounted;
  final FormFeedback feedback;
  final String message;
  final double accuracyScore;
  final Map<String, double>? angles;
  
  ExerciseResult({
    required this.repCounted,
    required this.feedback,
    required this.message,
    this.accuracyScore = 100.0,
    this.angles,
  });
}

/// Extension to get color for feedback
extension FormFeedbackColors on FormFeedback {
  Color get color {
    switch (this) {
      case FormFeedback.excellent:
        return const Color(0xFF4CAF50); // Green
      case FormFeedback.good:
        return const Color(0xFF8BC34A); // Light Green
      case FormFeedback.needsCorrection:
        return const Color(0xFFFF9800); // Orange
      case FormFeedback.poor:
        return const Color(0xFFF44336); // Red
      case FormFeedback.noDetection:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
  
  String get description {
    switch (this) {
      case FormFeedback.excellent:
        return "EXCELLENT";
      case FormFeedback.good:
        return "GOOD";
      case FormFeedback.needsCorrection:
        return "NEEDS CORRECTION";
      case FormFeedback.poor:
        return "POOR FORM";
      case FormFeedback.noDetection:
        return "NO DETECTION";
    }
  }
} 