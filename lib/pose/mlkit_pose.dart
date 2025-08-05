import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// ML Kit Pose Detection implementation based on official documentation
/// https://developers.google.com/ml-kit/vision/pose-detection/android
class MLKitPoseDetector {
  static const int numKeypoints = 33; // ML Kit has 33 landmarks
  
  // ML Kit pose landmark indices (based on official documentation)
  static const int nose = 0;
  static const int leftEyeInner = 1;
  static const int leftEye = 2;
  static const int leftEyeOuter = 3;
  static const int rightEyeInner = 4;
  static const int rightEye = 5;
  static const int rightEyeOuter = 6;
  static const int leftEar = 7;
  static const int rightEar = 8;
  static const int leftMouth = 9;
  static const int rightMouth = 10;
  static const int leftShoulder = 11;
  static const int rightShoulder = 12;
  static const int leftElbow = 13;
  static const int rightElbow = 14;
  static const int leftWrist = 15;
  static const int rightWrist = 16;
  static const int leftPinky = 17;
  static const int rightPinky = 18;
  static const int leftIndex = 19;
  static const int rightIndex = 20;
  static const int leftThumb = 21;
  static const int rightThumb = 22;
  static const int leftHip = 23;
  static const int rightHip = 24;
  static const int leftKnee = 25;
  static const int rightKnee = 26;
  static const int leftAnkle = 27;
  static const int rightAnkle = 28;
  static const int leftHeel = 29;
  static const int rightHeel = 30;
  static const int leftFootIndex = 31;
  static const int rightFootIndex = 32;

  late PoseDetector _poseDetector;
  bool _isInitialized = false;
  int _frameCount = 0;
  
  // Smoothing for stable tracking
  List<List<double>> _lastKeypoints = [];
  List<List<double>> _stableKeypoints = [];

  /// Initialize ML Kit Pose Detection
  Future<void> initialize() async {
    try {
      print('🎯 ML Kit Pose: Initializing pose detection...');
      
      // Create pose detector with stream mode for real-time processing
      // Using base model for better performance (30 FPS vs 23 FPS for accurate)
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream, // For real-time video processing
          model: PoseDetectionModel.base, // Faster performance
        ),
      );
      
      _isInitialized = true;
      _frameCount = 0;
      _lastKeypoints = [];
      _stableKeypoints = [];
      
      print('✅ ML Kit Pose: Initialized successfully with 33 landmarks');
    } catch (e) {
      print('❌ ML Kit Pose: Initialization failed: $e');
      
      // For debug builds, try with default options as fallback
      try {
        print('🔄 ML Kit Pose: Trying fallback initialization...');
        _poseDetector = PoseDetector(
          options: PoseDetectorOptions(
            mode: PoseDetectionMode.stream, // Use stream mode as fallback
            model: PoseDetectionModel.base,
          ),
        );
        
        _isInitialized = true;
        _frameCount = 0;
        _lastKeypoints = [];
        _stableKeypoints = [];
        
        print('✅ ML Kit Pose: Fallback initialization successful');
      } catch (fallbackError) {
        print('❌ ML Kit Pose: Fallback initialization also failed: $fallbackError');
        _isInitialized = false;
        rethrow; // Re-throw to handle in the calling code
      }
    }
  }

  /// Predict pose from camera image
  Future<List<List<double>>> predict(CameraImage image) async {
    if (!_isInitialized) {
      print('❗ ML Kit Pose: Not initialized');
      return generateDefaultPose();
    }

    try {
      _frameCount++;
      
      // Process every 2nd frame for better real-time performance (30 FPS -> 15 FPS)
      if (_frameCount % 2 != 0) {
        return _lastKeypoints.isNotEmpty ? _lastKeypoints : generateDefaultPose();
      }
      
      // Debug every 30 frames
      if (_frameCount % 30 == 0) {
        print('🎯 ML Kit Pose: Processing frame $_frameCount');
      }

      // Convert camera image to InputImage for ML Kit
      final inputImage = _convertToInputImage(image);
      if (inputImage == null) {
        return _stableKeypoints.isNotEmpty ? _stableKeypoints : generateDefaultPose();
      }

             // Detect poses
       final poses = await _poseDetector.processImage(inputImage);
       
       // Debug pose detection results
       if (_frameCount % 30 == 0) {
         print('🔍 ML Kit Pose Frame $_frameCount: Detected ${poses.length} poses');
         if (poses.isNotEmpty) {
           final pose = poses.first;
           print('🔍 ML Kit Pose: First pose has ${pose.landmarks.length} landmarks');
           
           // Log some key landmarks
           final nose = pose.landmarks[PoseLandmarkType.nose];
           final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
           final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
           
           if (nose != null) print('🔍 ML Kit Pose: Nose at (${nose.x.toStringAsFixed(2)}, ${nose.y.toStringAsFixed(2)}) confidence: ${nose.likelihood.toStringAsFixed(2)}');
           if (leftShoulder != null) print('🔍 ML Kit Pose: Left shoulder at (${leftShoulder.x.toStringAsFixed(2)}, ${leftShoulder.y.toStringAsFixed(2)}) confidence: ${leftShoulder.likelihood.toStringAsFixed(2)}');
           if (rightShoulder != null) print('🔍 ML Kit Pose: Right shoulder at (${rightShoulder.x.toStringAsFixed(2)}, ${rightShoulder.y.toStringAsFixed(2)}) confidence: ${rightShoulder.likelihood.toStringAsFixed(2)}');
         }
       }
       
       if (poses.isNotEmpty) {
         // Get the first (most prominent) pose
         final pose = poses.first;
         final keypoints = _extractKeypoints(pose, image.width, image.height);
         
         // Apply temporal smoothing for stability
         _stableKeypoints = smoothKeypoints(keypoints, _stableKeypoints);
         _lastKeypoints = _stableKeypoints;

                   // Debug output every 30 frames
          if (_frameCount % 30 == 0) {
            final avgConfidence = _stableKeypoints.fold(0.0, (sum, kp) => sum + kp[2]) / _stableKeypoints.length;
            print('✅ ML Kit Pose Frame $_frameCount: Person detected! Avg confidence: ${avgConfidence.toStringAsFixed(2)}');
            print('✅ ML Kit Pose: Extracted ${keypoints.length} keypoints');
            
            // Debug key landmark positions
            if (keypoints.length >= 33) {
              final nose = keypoints[0];
              final leftShoulder = keypoints[11];
              final rightShoulder = keypoints[12];
              final leftHip = keypoints[23];
              final rightHip = keypoints[24];
              final leftKnee = keypoints[25];
              final rightKnee = keypoints[26];
              
              print('🔍 ML Kit Pose Debug - Nose: (${nose[1].toStringAsFixed(3)}, ${nose[0].toStringAsFixed(3)}) conf: ${nose[2].toStringAsFixed(2)}');
              print('🔍 ML Kit Pose Debug - Left Shoulder: (${leftShoulder[1].toStringAsFixed(3)}, ${leftShoulder[0].toStringAsFixed(3)}) conf: ${leftShoulder[2].toStringAsFixed(2)}');
              print('🔍 ML Kit Pose Debug - Right Shoulder: (${rightShoulder[1].toStringAsFixed(3)}, ${rightShoulder[0].toStringAsFixed(3)}) conf: ${rightShoulder[2].toStringAsFixed(2)}');
              print('🔍 ML Kit Pose Debug - Left Hip: (${leftHip[1].toStringAsFixed(3)}, ${leftHip[0].toStringAsFixed(3)}) conf: ${leftHip[2].toStringAsFixed(2)}');
              print('🔍 ML Kit Pose Debug - Right Hip: (${rightHip[1].toStringAsFixed(3)}, ${rightHip[0].toStringAsFixed(3)}) conf: ${rightHip[2].toStringAsFixed(2)}');
              print('🔍 ML Kit Pose Debug - Left Knee: (${leftKnee[1].toStringAsFixed(3)}, ${leftKnee[0].toStringAsFixed(3)}) conf: ${leftKnee[2].toStringAsFixed(2)}');
              print('🔍 ML Kit Pose Debug - Right Knee: (${rightKnee[1].toStringAsFixed(3)}, ${rightKnee[0].toStringAsFixed(3)}) conf: ${rightKnee[2].toStringAsFixed(2)}');
            }
          }

         return _stableKeypoints;
       } else {
         // No pose detected
         if (_frameCount % 30 == 0) {
           print('❌ ML Kit Pose Frame $_frameCount: No pose detected in frame');
         }
         return _stableKeypoints.isNotEmpty ? _stableKeypoints : generateDefaultPose();
       }
    } catch (e) {
      print('❗ ML Kit Pose prediction error: $e');
      return _stableKeypoints.isNotEmpty ? _stableKeypoints : generateDefaultPose();
    }
  }

  /// Convert CameraImage to InputImage for ML Kit
  /// Based on the tutorial: https://hamzaasif-mobileml.medium.com/build-an-exercise-detector-and-counter-app-in-flutter-with-pose-detection-59b4002f1b48
  InputImage? _convertToInputImage(CameraImage image) {
    try {
      // Validate image data
      if (image.planes.isEmpty || image.planes[0].bytes.isEmpty) {
        print('❗ ML Kit Pose: Empty image planes');
        return null;
      }

      // Debug image format info
      print('📸 ML Kit Pose: Image format - width: ${image.width}, height: ${image.height}');
      print('📸 ML Kit Pose: Planes count: ${image.planes.length}');
      for (int i = 0; i < image.planes.length; i++) {
        print('📸 ML Kit Pose: Plane $i - bytes: ${image.planes[i].bytes.length}, bytesPerRow: ${image.planes[i].bytesPerRow}');
      }

      // According to the tutorial, ML Kit expects:
      // - Android: nv21 format (single plane)
      // - iOS: bgra8888 format (single plane)
      
      if (Platform.isAndroid) {
        // For Android, we need to convert YUV420 to NV21
        if (image.planes.length >= 3) {
          try {
            final yPlane = image.planes[0];
            final uPlane = image.planes[1];
            final vPlane = image.planes[2];
            
            // Create NV21 format (Y plane + VU interleaved)
            final ySize = yPlane.bytes.length;
            final uvSize = uPlane.bytes.length + vPlane.bytes.length;
            final nv21Bytes = Uint8List(ySize + uvSize);
            
            // Copy Y plane
            nv21Bytes.setRange(0, ySize, yPlane.bytes);
            
            // Interleave V and U planes (VU format)
            int uvIndex = ySize;
            for (int i = 0; i < vPlane.bytes.length; i++) {
              nv21Bytes[uvIndex++] = vPlane.bytes[i];
              if (i < uPlane.bytes.length) {
                nv21Bytes[uvIndex++] = uPlane.bytes[i];
              }
            }
            
            final inputImage = InputImage.fromBytes(
              bytes: nv21Bytes,
              metadata: InputImageMetadata(
                size: ui.Size(image.width.toDouble(), image.height.toDouble()),
                rotation: InputImageRotation.rotation0deg,
                format: InputImageFormat.nv21, // Use NV21 for Android
                bytesPerRow: yPlane.bytesPerRow,
              ),
            );
            print('✅ ML Kit Pose: InputImage created successfully with NV21 format');
            return inputImage;
          } catch (e1) {
            print('❌ ML Kit Pose: NV21 conversion failed: $e1');
          }
        }
      } else if (Platform.isIOS) {
        // For iOS, use BGRA8888 format
        if (image.planes.length == 1) {
          try {
            final inputImage = InputImage.fromBytes(
              bytes: image.planes[0].bytes,
              metadata: InputImageMetadata(
                size: ui.Size(image.width.toDouble(), image.height.toDouble()),
                rotation: InputImageRotation.rotation0deg,
                format: InputImageFormat.bgra8888, // Use BGRA8888 for iOS
                bytesPerRow: image.planes[0].bytesPerRow,
              ),
            );
            print('✅ ML Kit Pose: InputImage created successfully with BGRA8888 format');
            return inputImage;
          } catch (e1) {
            print('❌ ML Kit Pose: BGRA8888 conversion failed: $e1');
          }
        }
      }
      
      // Fallback: Try with just Y plane as grayscale
      try {
        final format = Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;
        final inputImage = InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: ui.Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            format: format,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
        print('✅ ML Kit Pose: InputImage created successfully with Y plane only');
        return inputImage;
      } catch (e2) {
        print('❌ ML Kit Pose: Y plane only failed: $e2');
      }
      
      return null;
    } catch (e) {
      print('❗ ML Kit Pose: Error converting to InputImage: $e');
      return null;
    }
  }

  /// Extract keypoints from ML Kit pose (33 landmarks)
  List<List<double>> _extractKeypoints(Pose pose, int imageWidth, int imageHeight) {
    final keypoints = List<List<double>>.filled(numKeypoints, [0.0, 0.0, 0.0]);
    
    // Get all pose landmarks
    final allLandmarks = pose.landmarks;
    
    // Map each landmark to our keypoint format
    for (final entry in allLandmarks.entries) {
      final landmarkType = entry.key;
      final landmark = entry.value;
      
      // Get the index for this landmark type
      final index = _getLandmarkIndex(landmarkType);
      if (index >= 0 && index < numKeypoints) {
        keypoints[index] = [
          landmark.y / imageHeight, // y (normalized)
          landmark.x / imageWidth,  // x (normalized)
          landmark.likelihood,      // confidence
        ];
      }
    }
    
    return keypoints;
  }

  /// Get landmark index based on ML Kit landmark type
  int _getLandmarkIndex(PoseLandmarkType landmarkType) {
    switch (landmarkType) {
      case PoseLandmarkType.nose:
        return nose;
      case PoseLandmarkType.leftEyeInner:
        return leftEyeInner;
      case PoseLandmarkType.leftEye:
        return leftEye;
      case PoseLandmarkType.leftEyeOuter:
        return leftEyeOuter;
      case PoseLandmarkType.rightEyeInner:
        return rightEyeInner;
      case PoseLandmarkType.rightEye:
        return rightEye;
      case PoseLandmarkType.rightEyeOuter:
        return rightEyeOuter;
      case PoseLandmarkType.leftEar:
        return leftEar;
      case PoseLandmarkType.rightEar:
        return rightEar;
      case PoseLandmarkType.leftMouth:
        return leftMouth;
      case PoseLandmarkType.rightMouth:
        return rightMouth;
      case PoseLandmarkType.leftShoulder:
        return leftShoulder;
      case PoseLandmarkType.rightShoulder:
        return rightShoulder;
      case PoseLandmarkType.leftElbow:
        return leftElbow;
      case PoseLandmarkType.rightElbow:
        return rightElbow;
      case PoseLandmarkType.leftWrist:
        return leftWrist;
      case PoseLandmarkType.rightWrist:
        return rightWrist;
      case PoseLandmarkType.leftPinky:
        return leftPinky;
      case PoseLandmarkType.rightPinky:
        return rightPinky;
      case PoseLandmarkType.leftIndex:
        return leftIndex;
      case PoseLandmarkType.rightIndex:
        return rightIndex;
      case PoseLandmarkType.leftThumb:
        return leftThumb;
      case PoseLandmarkType.rightThumb:
        return rightThumb;
      case PoseLandmarkType.leftHip:
        return leftHip;
      case PoseLandmarkType.rightHip:
        return rightHip;
      case PoseLandmarkType.leftKnee:
        return leftKnee;
      case PoseLandmarkType.rightKnee:
        return rightKnee;
      case PoseLandmarkType.leftAnkle:
        return leftAnkle;
      case PoseLandmarkType.rightAnkle:
        return rightAnkle;
      case PoseLandmarkType.leftHeel:
        return leftHeel;
      case PoseLandmarkType.rightHeel:
        return rightHeel;
      case PoseLandmarkType.leftFootIndex:
        return leftFootIndex;
      case PoseLandmarkType.rightFootIndex:
        return rightFootIndex;
      default:
        return -1; // Unknown landmark type
    }
  }

  /// Generate default pose with 33 keypoints
  List<List<double>> generateDefaultPose() {
    final defaultPose = <List<double>>[];
    
    for (int i = 0; i < numKeypoints; i++) {
      defaultPose.add([0.5, 0.5, 0.1]); // Center of frame with low confidence
    }
    
    return defaultPose;
  }

  /// Apply temporal smoothing to keypoints
  List<List<double>> smoothKeypoints(List<List<double>> newKeypoints, List<List<double>> oldKeypoints) {
    if (oldKeypoints.isEmpty) return newKeypoints;
    
    final smoothed = <List<double>>[];
    final smoothingFactor = 0.3; // Reduced for more responsive real-time tracking
    
    for (int i = 0; i < newKeypoints.length; i++) {
      if (i < oldKeypoints.length) {
        final oldKp = oldKeypoints[i];
        final newKp = newKeypoints[i];
        
        // Smooth position and confidence
        final smoothedX = oldKp[1] * smoothingFactor + newKp[1] * (1 - smoothingFactor);
        final smoothedY = oldKp[0] * smoothingFactor + newKp[0] * (1 - smoothingFactor);
        final smoothedConf = oldKp[2] * smoothingFactor + newKp[2] * (1 - smoothingFactor);
        
        smoothed.add([smoothedY, smoothedX, smoothedConf]);
      } else {
        smoothed.add(newKeypoints[i]);
      }
    }
    
    return smoothed;
  }

  /// Dispose resources
  void dispose() {
    _lastKeypoints.clear();
    _stableKeypoints.clear();
  }

  /// Close the pose detection model
  void close() {
    _poseDetector.close();
    dispose();
  }
} 