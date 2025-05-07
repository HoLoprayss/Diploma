import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Измененный импорт
import 'package:camera/camera.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'preview_screen.dart';

class ScanReceiptScreen extends StatefulWidget {
  @override
  _ScanReceiptScreenState createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  late CameraController _cameraController;
  late Future<void> _initializeCameraFuture;
  MobileScannerController _mobileScannerController = MobileScannerController(); // Новый контроллер
  bool _isLoading = false;
  bool _isQRMode = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    _initializeCameraFuture = _cameraController.initialize();
    setState(() {});
  }

  void _handleBarcode(Barcode barcode) { // Обновленный обработчик
    if (barcode.rawValue != null) {
      _mobileScannerController.stop();
      _processQRCode(barcode.rawValue!);
    }
  }

  Future<void> _processQRCode(String qrData) async {
    setState(() => _isLoading = true);

    try {
      Map<String, String> params = Uri.splitQueryString(qrData);
      String fiscalNumber = params['fn'] ?? '';
      String fiscalDocument = params['i'] ?? '';
      String fiscalSign = params['fp'] ?? '';
      int operationType = int.parse(params['n'] ?? '1');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('QR-код распознан'),
          content: Text('Фискальный номер: $fiscalNumber\nДокумент: $fiscalDocument\nПризнак: $fiscalSign'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _mobileScannerController.start(); // Возобновление сканирования
              },
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
          content: Text('Не удалось обработать QR-код: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _mobileScannerController.start();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _takePicture() async {
    try {
      final imagePath = await _cameraController.takePicture();
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

  @override
  void dispose() {
    _cameraController.dispose();
    _mobileScannerController.dispose(); // Освобождение ресурсов
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сканирование чека'),
        backgroundColor: Colors.lightGreen[600],
        actions: [
          IconButton(
            icon: Icon(_isQRMode ? Icons.camera : Icons.qr_code),
            onPressed: () {
              setState(() {
                _isQRMode = !_isQRMode;
                if (_isQRMode) {
                  _mobileScannerController.start();
                } else {
                  _mobileScannerController.stop();
                }
              });
            },
          ),
        ],
      ),
      body: _isQRMode
          ? MobileScanner( // Новый виджет сканера
        controller: _mobileScannerController,
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          _handleBarcode(barcode);
        },
      )
          : FutureBuilder<void>(
        future: _initializeCameraFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_cameraController),
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
      floatingActionButton: _isQRMode
          ? null
          : FloatingActionButton(
        onPressed: _takePicture,
        backgroundColor: Colors.lightGreen[600],
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}