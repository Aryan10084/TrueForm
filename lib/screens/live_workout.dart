import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class LiveWorkoutScreen extends StatefulWidget {
  static const String routeName = '/live-workout';
  const LiveWorkoutScreen({Key? key}) : super(key: key);

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.isNotEmpty ? cameras.first : null;
    if (camera != null) {
      _controller = CameraController(camera, ResolutionPreset.medium);
      _initializeControllerFuture = _controller!.initialize();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Workout')),
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_controller!),
                      Center(
                        child: Container(
                          width: 200,
                          height: 100,
                          color: Colors.blue.withOpacity(0.3),
                          child: const Center(
                            child: Text(
                              'Dummy Overlay',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
    );
  }
} 