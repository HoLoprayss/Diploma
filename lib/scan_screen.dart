import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import 'package:uuid/uuid.dart';
import 'package:mealsafe/models/product.dart';
import 'package:mealsafe/preview_screen.dart';
import 'package:mealsafe/preview_edit_screen.dart';
import 'package:mealsafe/models/product.dart';

class ScanReceiptScreen extends StatefulWidget {
  @override
  _ScanReceiptScreenState createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  MobileScannerController? _scannerController;
  bool _isLoading = false;
  bool _isQRMode = true; // Переключение между QR и фото
  final String TOKEN = '32894.FwqnuE9FZYMTdUPOs'; // токен

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

  void _handleBarcode(Barcode barcode) {
    if (barcode.rawValue != null && !_isLoading) {
      _scannerController?.stop();
      _processQRCode(barcode.rawValue!);
    }
  }

  Future<void> _processQRCode(String qrData) async {
    setState(() => _isLoading = true);
    try {
      var response = await http.post(
        Uri.parse('https://proverkacheka.com/api/v1/check/get'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: 'qrraw=${Uri.encodeQueryComponent(qrData)}&token=32894.FwqnuE9FZYMTdUPOs',
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['code'] == 1) {
          var items = data['data']['json']['items'] as List;
          List<Product> products = items.map((item) {
            // String category = _determineCategory(item['name']);
            // DateTime expirationDate = _calculateExpirationDate(category);
            return Product(
              Uuid().v4(),
              item['name'],
              item['quantity'].toString(),
              'Pantry',
              expirationDate: DateTime.now().add(Duration(days: 7)),
            );
          }).toList();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProductsScreen(products: products),
            ),
          );
        } else {
          throw Exception('API error: ${data['code']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Ошибка'),
          content: Text('Не удалось получить данные чека: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _scannerController?.start();
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

  // String _determineCategory(String name) {
  //   name = name.toLowerCase();
  //   if (name.contains('молоко') || name.contains('йогурт')) return 'Fridge';
  //   if (name.contains('зам.')) return 'Freezer'; // Замороженные продукты
  //   return 'Pantry';
  // }
  //
  // DateTime _calculateExpirationDate(String category) {
  //   switch (category) {
  //     case 'Fridge':
  //       return DateTime.now().add(Duration(days: 5));
  //     case 'Freezer':
  //       return DateTime.now().add(Duration(days: 30));
  //     default:
  //       return DateTime.now().add(Duration(days: 7));
  //   }
  // }

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

  @override
  void dispose() {
    _controller.dispose();
    _scannerController?.dispose();
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
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _isQRMode
              ? MobileScanner(
            controller: _scannerController = MobileScannerController(),
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              _handleBarcode(barcode);
            },
          )
              : FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          if (_isLoading) Center(child: CircularProgressIndicator()),
        ],
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