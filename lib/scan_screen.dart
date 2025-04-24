import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'preview_screen.dart';

class ScanReceiptScreen extends StatefulWidget {
  @override
  _ScanReceiptScreenState createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
    setState(() {});
  }

  Future<void> _takePicture() async {
    try {
      final imagePath = await _controller.takePicture();
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewScreen(imageFile: File(imagePath.path)),
        ),
      );
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  Future<void> _processImage(String imagePath) async {
    setState(() => _isLoading = true);

    try {
      final String recognizedText = await FlutterTesseractOcr.extractText(
        imagePath,
        language: 'rus',
        args: {
          "preserve_interword_spaces": "1",
        },
      );

      // Показываем результат в диалоге
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Результат распознавания'),
          content: SingleChildScrollView(
            child: Text(recognizedText.isEmpty ? 'Текст не найден' : recognizedText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );

    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Ошибка'),
          content: Text('Не удалось распознать текст: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сканирование чека'),
        backgroundColor: Colors.lightGreen[600],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                if (_isLoading)
                  Center(child: CircularProgressIndicator()),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final imagePath = await _takePicture();
        },
        backgroundColor: Colors.lightGreen[600],
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}