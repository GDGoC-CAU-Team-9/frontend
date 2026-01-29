import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Use the first available camera (usually rear on mobile, or webcam on desktop)
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.low, // Try low resolution for maximum compatibility
          enableAudio: false,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } else {
        _showError('No cameras found.');
      }
    } catch (e) {
      _showError('Camera error: $e. Make sure no other app is using it.');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Use Gallery',
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).hideCurrentSnackBar(); // Hide error immediately
              Navigator.pop(context); // Go back to Home to pick gallery
            },
          ),
        ),
      );
    }
  }

  Future<void> _takePicture() async {
    if (!_isInitialized || _controller == null || _isTakingPicture) {
      return;
    }

    try {
      setState(() {
        _isTakingPicture = true;
      });

      final XFile image = await _controller!.takePicture();

      if (mounted) {
        // Return the captured XFile to the previous screen or navigate directly
        context.pushReplacement('/analysis-loading', extra: image);
      }
    } catch (e) {
      _showError('Failed to capture image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                'Initializing Camera...',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  context.pop();
                }, // Go back so they can use Gallery
                icon: const Icon(Icons.image, color: Colors.white),
                label: const Text(
                  'Use Gallery instead',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(child: CameraPreview(_controller!)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        backgroundColor: Colors.white,
        child: _isTakingPicture
            ? const CircularProgressIndicator(color: Colors.black)
            : const Icon(Icons.camera_alt, color: Colors.black),
      ),
    );
  }
}
