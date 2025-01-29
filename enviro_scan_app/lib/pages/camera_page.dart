import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'analysis_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  CameraPageState createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  final List<File> _capturedPhotos = []; // List of captured photos

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        debugPrint('No cameras found');
        return;
      }

      _cameraController?.dispose(); // Dispose old controller before initializing

      _cameraController = CameraController(
        _cameras.first, // Use the first camera (usually back camera)
        ResolutionPreset.high,
        enableAudio: false, // Avoids errors with audio permissions
        imageFormatGroup: ImageFormatGroup.yuv420, // Prevents rotation issues
      );

      await _cameraController!.initialize();

      if (!mounted) return; // Avoid setState() if the widget is disposed

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      // Take photo and save to temporary directory
      final XFile photo = await _cameraController!.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final String photoPath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File savedPhoto = File(photoPath);
      await File(photo.path).copy(photoPath);

      if (!mounted) return;

      setState(() {
        _capturedPhotos.add(savedPhoto);
      });
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  void _deletePhoto(int index) {
    setState(() {
      _capturedPhotos.removeAt(index);
    });
  }

  Future<void> _sendPhotosToBackend() async {
    if (_capturedPhotos.isEmpty) {
      debugPrint("No photos to send");
      return;
    }

    try {
      final Uri uri = Uri.parse("http://10.0.2.2:8000/analyze/");
      debugPrint("API URL: $uri");

      final request = http.MultipartRequest('POST', uri);

      // Add all captured photos to the request
      for (File photo in _capturedPhotos) {
        debugPrint("Adding photo: ${photo.path}");
        request.files.add(await http.MultipartFile.fromPath('files', photo.path));
      }

      final response = await request.send();
      debugPrint("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final jsonResponse = await http.Response.fromStream(response);
        final data = jsonDecode(jsonResponse.body);

        debugPrint("Received response: $data");

        // Navigate to Analysis Page with results for all images
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisPage(results: data['results']),
          ),
        );
      } else {
        debugPrint("Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error sending photos to backend: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/pngtree-green-nature-page-border-image_13367772.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Make Camera Preview Bigger
            if (_isCameraInitialized && _cameraController != null)
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.height * 0.9,  // Increase height
                      height: MediaQuery.of(context).size.width * 1.5,  // Maintain aspect ratio
                      child: Transform.rotate(
                        angle: pi / 2, // Rotate 90 degrees clockwise
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(
                              _cameraController!.description.lensDirection == CameraLensDirection.front ? pi : 0),
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),

            // Photo Gallery
            if (_capturedPhotos.isNotEmpty)
              Container(
                height: 100,
                margin: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _capturedPhotos.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Image.file(
                            _capturedPhotos[index],
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _deletePhoto(index),
                        ),
                      ],
                    );
                  },
                ),
              ),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _takePhoto,
                  child: const Text('Take Photo'),
                ),
                if (_capturedPhotos.isNotEmpty)
                  ElevatedButton(
                    onPressed: () async {
                      debugPrint("Proceed to Analysis button pressed");
                      await _sendPhotosToBackend();
                    },
                    child: const Text('Proceed to Analysis'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
