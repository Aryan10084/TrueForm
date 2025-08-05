import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../pose/mlkit_pose.dart';
import '../utils/exercise_tracker.dart';
import '../utils/audio_feedback.dart';

class LiveWorkoutMLKitScreen extends StatefulWidget {
  static const String routeName = '/live-workout';

  final String exerciseType;
  final int sets;
  final int reps;
  final int timer;

  const LiveWorkoutMLKitScreen({
    super.key,
    required this.exerciseType,
    required this.sets,
    required this.reps,
    required this.timer,
  });

  @override
  State<LiveWorkoutMLKitScreen> createState() => _LiveWorkoutMLKitScreenState();
}

class _LiveWorkoutMLKitScreenState extends State<LiveWorkoutMLKitScreen> {
  CameraController? _controller;
  Future<void>? _initCamFuture;
  MLKitPoseDetector? _poseModel;
  ExerciseTracker? _exerciseTracker;
  bool _isProcessing = false;
  bool _isResting = false;
  int _frameCount = 0;
  List<List<double>> _keypoints = [];
  String _status = 'Initializing...';
  DateTime? _camStart;
  
  // Camera rotation state
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isSwitchingCamera = false;
  
  // Workout tracking
  int _currentSet = 1;
  int _currentRep = 0;
  int _autoRepCount = 0;
  int _timerSeconds = 0;
  Timer? _workoutTimer;
  
  // Form feedback
  FormFeedback _currentFeedback = FormFeedback.good;
  String _feedbackMessage = "";
  
  // Audio feedback
  final AudioFeedback _audioFeedback = AudioFeedback();
  DateTime? _lastRepTime;
  DateTime? _lastFeedbackTime;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _initCamera();
    _timerSeconds = widget.timer;
    _exerciseTracker = ExerciseTracker(widget.exerciseType);
  }

  Future<void> _loadModel() async {
    try {
      setState(() {
        _status = 'Loading pose detection model...';
      });
      
      print('🔧 Debug: Starting ML Kit Pose model initialization...');
      final model = MLKitPoseDetector();
      
      print('🔧 Debug: Calling model.initialize()...');
      await model.initialize();
      
      if (mounted) {
        setState(() {
          _poseModel = model;
          _status = 'Model loaded successfully';
        });
        print('✅ ML Kit Pose model loaded successfully');
        print('🔧 Debug: Model initialization completed successfully');
      }
    } catch (e) {
      print('❌ Error loading ML Kit Pose model: $e');
      print('🔧 Debug: Model initialization failed with error: $e');
      if (mounted) {
        setState(() {
          _status = 'Model loading failed: $e';
        });
        
        // Show error dialog with retry option
        _showModelErrorDialog();
      }
    }
  }

  void _showModelErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pose Detection Error'),
          content: const Text(
            'Failed to load pose detection model. This might be due to:\n\n'
            '• Insufficient device memory\n'
            '• Outdated ML Kit dependencies\n'
            '• Debug build configuration issues\n\n'
            'Would you like to retry loading the model?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadModel(); // Retry loading
              },
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _initCamera() async {
    if (await Permission.camera.request().isDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission required for pose detection')),
      );
      setState(() {
        _status = 'Camera permission denied';
      });
      return;
    }

    try {
      setState(() {
        _status = 'Searching for cameras...';
      });
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _status = 'No cameras found on device';
        });
        return;
      }
      
      // Debug: Log available cameras
      print('📸 Available cameras:');
      for (int i = 0; i < _cameras.length; i++) {
        print('  Camera $i: ${_cameras[i].lensDirection.name}');
      }
      
      setState(() {
        _status = 'Found ${_cameras.length} cameras, initializing...';
      });
      
      // Start with front camera if available
      _currentCameraIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      if (_currentCameraIndex == -1) _currentCameraIndex = 0;
      print('📸 Starting with camera index: $_currentCameraIndex (${_cameras[_currentCameraIndex].lensDirection.name})');
      
      await _initializeCameraController();
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Camera initialization error: $e';
        });
      }
      try {
        _controller?.dispose();
        _controller = null;
      } catch (_) {}
    }
  }

  Future<void> _initializeCameraController() async {
    if (_cameras.isEmpty) return;
    
    try {
      // Properly dispose previous controller
      if (_controller != null) {
        await _controller!.stopImageStream();
        await _controller!.dispose();
        _controller = null;
      }
      
      final camera = _cameras[_currentCameraIndex];
      print('📸 Initializing camera: ${camera.lensDirection.name} (index: $_currentCameraIndex)');
      
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      setState(() {
        _status = 'Initializing ${camera.lensDirection.name} camera...';
      });
      
      _initCamFuture = _controller!.initialize();
      await _initCamFuture;
      
      if (mounted) {
        setState(() {
          _status = 'Camera ready - ${camera.lensDirection.name} camera';
          _camStart = DateTime.now();
        });
        
        // Restart image stream for pose detection
        await _controller!.startImageStream(_processImage);
        print('✅ Camera switched to: ${camera.lensDirection.name}');
      }
    } catch (e) {
      print('❌ Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _status = 'Camera error: $e';
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) {
      print('⚠️ Only one camera available, cannot switch');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only one camera available')),
      );
      return;
    }
    
    print('🔄 Switching camera from index $_currentCameraIndex');
    
    // Show loading state
    setState(() {
      _status = 'Switching camera...';
      _isSwitchingCamera = true;
    });
    
    try {
      // Calculate next camera index
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
      print('🔄 New camera index: $_currentCameraIndex (${_cameras[_currentCameraIndex].lensDirection.name})');
      
      // Initialize new camera
      await _initializeCameraController();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${_cameras[_currentCameraIndex].lensDirection.name} camera'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('❌ Camera switch error: $e');
      if (mounted) {
        setState(() {
          _status = 'Camera switch failed: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera switch failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSwitchingCamera = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _poseModel?.close();
    _workoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _processImage(CameraImage image) async {
    if (_poseModel == null || _isProcessing || _exerciseTracker == null || _isResting) return;
    
    _frameCount++;
    
    // Process every 5th frame to reduce CPU load (20fps -> ~4fps processing)
    if (_frameCount % 5 != 0) return;
    
    _isProcessing = true;
    
    try {
      final keypoints = await _poseModel!.predict(image);
      if (mounted) {
        // Process exercise tracking
        final result = _exerciseTracker!.processFrame(keypoints);
        
        setState(() {
          _keypoints = keypoints;
          _autoRepCount = _exerciseTracker!.repCount;
          _currentFeedback = result.feedback;
          _feedbackMessage = result.message;
          
          if (keypoints.isNotEmpty) {
            _status = 'Tracking ${widget.exerciseType} - ${result.message}';
          } else {
            _status = 'No pose detected - position yourself in frame';
          }
        });
        
        // Handle rep counting
        if (result.repCounted) {
          _onRepCounted();
        }
        
        // Provide form feedback
        if (result.feedback != FormFeedback.good && result.feedback != _currentFeedback) {
          _audioFeedback.playFormFeedback(result.feedback, result.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Pose detection error: $e');
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _onRepCounted() {
    // Audio and haptic feedback
    _audioFeedback.playRepCountFeedback(_autoRepCount);
    
    // Update current rep count
    setState(() {
      _currentRep = _autoRepCount;
    });
    
    _lastRepTime = DateTime.now();
    
    // Check if set is complete
    if (_currentRep >= widget.reps) {
      _completeSet();
    }
  }

  void _startRestTimer() {
    setState(() {
      _isResting = true;
      _timerSeconds = widget.timer;
    });

    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timerSeconds--;
      });

      // Audio feedback for rest timer
      _audioFeedback.playRestTimerTick(_timerSeconds);

      if (_timerSeconds <= 0) {
        timer.cancel();
        setState(() {
          _isResting = false;
          _timerSeconds = widget.timer;
        });
        // Reset exercise tracker for new set
        _exerciseTracker?.resetReps();
        _autoRepCount = 0;
      }
    });
  }

  void _completeSet() {
    // Set completion feedback
    _audioFeedback.playSetComplete();
    
    if (_currentSet < widget.sets) {
      setState(() {
        _currentSet++;
        _currentRep = 0;
      });
      _startRestTimer();
    } else {
      // Workout complete feedback
      _audioFeedback.playWorkoutComplete();
      
      Navigator.pushReplacementNamed(context, '/session-summary', arguments: {
        'exerciseType': widget.exerciseType,
        'totalSets': widget.sets,
        'totalReps': widget.reps * widget.sets,
        'duration': DateTime.now().difference(_camStart ?? DateTime.now()).inMinutes,
      });
    }
  }

  void _incrementRep() {
    setState(() {
      _currentRep++;
    });

    if (_currentRep >= widget.reps) {
      _completeSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
        children: [
            // Camera Preview with 640x480 aspect ratio and mirroring
            Positioned.fill(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 640 / 480, // 4:3 aspect ratio (640x480)
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi), // Mirror the camera
                      child: CameraPreview(_controller!),
                    ),
                  ),
                ),
              ),
            ),

            // Camera Rotate Button - Top right of 640x480 camera screen
            Positioned.fill(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 640 / 480,
                  child: Stack(
                    children: [
                      // Camera rotate button positioned in top right of camera area
                      Positioned(
                        top: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () async {
                            print('🔄 Camera button tapped!');
                            await _switchCamera();
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                            ),
                            child: _isSwitchingCamera
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  )
                                : const Icon(
                                    Icons.cameraswitch,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Pose Overlay with 640x480 aspect ratio
            if (_keypoints.isNotEmpty)
              Positioned.fill(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 640 / 480, // 4:3 aspect ratio (640x480)
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                        painter: PoseOverlayPainter(
                          _keypoints, 
                          _currentFeedback,
                          Size(640, 480), // Fixed size for ML Kit coordinates
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Top Status Bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.exerciseType.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // Camera indicator
                    if (_cameras.isNotEmpty && _currentCameraIndex < _cameras.length)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _cameras[_currentCameraIndex].lensDirection.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),

            // Form Feedback Bar
            Positioned(
              top: 88,
              left: 16,
              right: 16,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _currentFeedback.color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFeedbackIcon(_currentFeedback),
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _feedbackMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _currentFeedback.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Workout Stats Overlay
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isResting) ...[
                      const Text(
                        'REST TIME',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_timerSeconds}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatCard(
                            label: 'SET',
                            value: '$_currentSet/${widget.sets}',
                            color: Colors.blue,
                          ),
                          _StatCard(
                            label: 'REPS',
                            value: '$_currentRep/${widget.reps}',
                            color: Colors.green,
                          ),
                          _StatCard(
                            label: 'AUTO',
                            value: '$_autoRepCount',
                            color: Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(
                            width: 120,
                            child: ElevatedButton(
                              onPressed: _incrementRep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text(
                                'MANUAL +1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _currentRep = _autoRepCount;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: const Text(
                                'SYNC AUTO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Debug Status
          Positioned(
              bottom: 200,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _status,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_controller != null)
                      Text(
                        'Camera: ${_controller!.value.isInitialized ? "Ready" : "Not Ready"}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    if (_poseModel != null)
                      Text(
                        'Pose Model: Loaded | Keypoints: ${_keypoints.length}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ],
          ),
      ),
    );
  }

  IconData _getFeedbackIcon(FormFeedback feedback) {
    switch (feedback) {
      case FormFeedback.excellent:
        return Icons.star;
      case FormFeedback.good:
        return Icons.check_circle;
      case FormFeedback.needsCorrection:
        return Icons.warning;
      case FormFeedback.poor:
        return Icons.error;
      case FormFeedback.noDetection:
        return Icons.visibility_off;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class PoseOverlayPainter extends CustomPainter {
  final List<List<double>> keypoints;
  final FormFeedback feedback;
  final Size absoluteImageSize;

  PoseOverlayPainter(
    this.keypoints, 
    this.feedback,
    this.absoluteImageSize,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (keypoints.isEmpty) return;

    print('🎨 PoseOverlayPainter: Painting ${keypoints.length} keypoints');
    print('🎨 PoseOverlayPainter: Canvas size: ${size.width}x${size.height}');
    print('🎨 PoseOverlayPainter: Image size: ${absoluteImageSize.width}x${absoluteImageSize.height}');

    // Fix 180-degree rotation by inverting y-coordinate
    // ML Kit returns [y, x, confidence], but camera preview is rotated
    final double scaleX = size.width;
    final double scaleY = size.height;

    // Create paints (exactly like the tutorial)
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.yellow;

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.blueAccent;

    // Draw keypoints (exactly like the tutorial)
    for (int i = 0; i < keypoints.length; i++) {
      final kp = keypoints[i];
      final confidence = kp[2];

      if (confidence > 0.2) {
        // Fix 180-degree rotation: swap x/y and invert y
        // Original: kp[1] = x, kp[0] = y
        // Fixed: kp[0] = x, (1 - kp[1]) = y (inverted)
        final x = kp[0] * scaleX; // Use y coordinate as x
        final y = (1 - kp[1]) * scaleY; // Invert x coordinate for y
        
        // Debug: Log first few keypoints
        if (i < 3) {
          print('🎯 PoseOverlayPainter: Keypoint $i - Original: (${kp[1].toStringAsFixed(3)}, ${kp[0].toStringAsFixed(3)}) -> Fixed: (${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})');
        }
        
        canvas.drawCircle(Offset(x, y), 3, paint);
      }
    }

    // Draw skeleton connections (exactly like the tutorial)
    void paintLine(int index1, int index2, Paint paintType) {
      if (index1 < keypoints.length && index2 < keypoints.length) {
        final kp1 = keypoints[index1];
        final kp2 = keypoints[index2];
        
        if (kp1[2] > 0.2 && kp2[2] > 0.2) {
          // Fix 180-degree rotation: swap x/y and invert y
          final x1 = kp1[0] * scaleX; // Use y coordinate as x
          final y1 = (1 - kp1[1]) * scaleY; // Invert x coordinate for y
          final x2 = kp2[0] * scaleX; // Use y coordinate as x
          final y2 = (1 - kp2[1]) * scaleY; // Invert x coordinate for y
          
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paintType);
        }
      }
    }

    // ML Kit keypoint indices (33 landmarks)
    const nose = 0;
    const leftShoulder = 11;
    const rightShoulder = 12;
    const leftElbow = 13;
    const rightElbow = 14;
    const leftWrist = 15;
    const rightWrist = 16;
    const leftHip = 23;
    const rightHip = 24;
    const leftKnee = 25;
    const rightKnee = 26;
    const leftAnkle = 27;
    const rightAnkle = 28;

    // Draw arms (exactly like the tutorial)
    paintLine(leftShoulder, leftElbow, leftPaint);
    paintLine(leftElbow, leftWrist, leftPaint);
    paintLine(rightShoulder, rightElbow, rightPaint);
    paintLine(rightElbow, rightWrist, rightPaint);

    // Draw body (exactly like the tutorial)
    paintLine(leftShoulder, leftHip, leftPaint);
    paintLine(rightShoulder, rightHip, rightPaint);

    // Draw legs (exactly like the tutorial)
    paintLine(leftHip, leftKnee, leftPaint);
    paintLine(leftKnee, leftAnkle, leftPaint);
    paintLine(rightHip, rightKnee, rightPaint);
    paintLine(rightKnee, rightAnkle, rightPaint);
  }

  @override
  bool shouldRepaint(PoseOverlayPainter oldDelegate) {
    return oldDelegate.keypoints != keypoints || 
           oldDelegate.feedback != feedback ||
           oldDelegate.absoluteImageSize != absoluteImageSize;
  }
}
