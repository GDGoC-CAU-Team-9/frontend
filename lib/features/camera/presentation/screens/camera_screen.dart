import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';

class CameraScreen extends StatefulWidget {
  final int? teamMemberId;

  const CameraScreen({super.key, this.teamMemberId});

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
        _showError(tr('camera.no_cameras_found'));
      }
    } catch (e) {
      _showError(
        tr('camera.camera_error_with_message', namedArgs: {'message': '$e'}),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: tr('camera.use_gallery'),
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
      final menuLang = await _showMenuLanguageSelectionSheet();
      if (!mounted || menuLang == null) return;

      if (mounted) {
        // Return the captured XFile to the previous screen or navigate directly
        context.pushReplacement(
          '/analysis-loading',
          extra: {
            'imageFile': image,
            'teamMemberId': widget.teamMemberId,
            'menuLang': menuLang,
          },
        );
      }
    } catch (e) {
      _showError(
        tr('camera.capture_failed_with_message', namedArgs: {'message': '$e'}),
      );
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

  Future<String?> _showMenuLanguageSelectionSheet() {
    final List<Map<String, String>> languages = AppConstants.supportedLanguages;
    const selectableLanguageCodes = {'ko', 'en', 'es'};
    final currentCode = context.locale.languageCode;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF11191A),
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                tr('home.menu_lang_sheet_title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tr('home.menu_lang_sheet_desc'),
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: languages.length,
                separatorBuilder: (_, __) =>
                    Divider(color: Colors.white.withOpacity(0.14), height: 1),
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  final code = lang['code']!;
                  final isEnabled = selectableLanguageCodes.contains(code);
                  final isCurrent = currentCode == code;

                  return ListTile(
                    enabled: isEnabled,
                    leading: Text(
                      lang['icon']!,
                      style: TextStyle(
                        fontSize: 22,
                        color: isEnabled
                            ? Colors.white
                            : Colors.white.withOpacity(0.35),
                      ),
                    ),
                    title: Text(
                      tr('language.$code'),
                      style: TextStyle(
                        color: !isEnabled
                            ? Colors.white.withOpacity(0.45)
                            : isCurrent
                            ? const Color(0xFF18B4A6)
                            : Colors.white,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: isCurrent && isEnabled
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF18B4A6),
                          )
                        : !isEnabled
                        ? Icon(
                            Icons.remove_circle_outline_rounded,
                            color: Colors.white.withOpacity(0.45),
                            size: 20,
                          )
                        : null,
                    onTap: !isEnabled
                        ? null
                        : () => Navigator.pop(sheetContext, code),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
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
              Text(
                tr('camera.initializing'),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  context.pop();
                }, // Go back so they can use Gallery
                icon: const Icon(Icons.image, color: Colors.white),
                label: Text(
                  tr('camera.use_gallery_instead'),
                  style: const TextStyle(color: Colors.white),
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
