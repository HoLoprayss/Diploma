import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tesseract_ocr/android_ios.dart';
import 'package:mealsafe/models/product.dart';
import 'package:mealsafe/preview_edit_screen.dart';
import 'package:uuid/uuid.dart';

class PreviewScreen extends StatefulWidget {
  final File imageFile;

  const PreviewScreen({super.key, required this.imageFile});

  @override
  _PreviewScreenState createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _isProcessing = false;
  final Uuid _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Предпросмотр'),
        backgroundColor: Colors.lightGreen[600],
        actions: [
          if (!_isProcessing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => _processImage(),
            ),
        ],
      ),
      body: Stack(
        children: [
          Center(child: Image.file(widget.imageFile)),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        backgroundColor: Colors.red,
        child: const Icon(Icons.cancel),
      ),
    );
  }

  Future<void> _processImage() async {
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      final products = await _parseReceipt(widget.imageFile);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProductsScreen(products: products),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ошибка'),
          content: Text('Не удалось обработать чек: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<List<Product>> _parseReceipt(File image) async {
    final String text = await FlutterTesseractOcr.extractText(
      image.path,
      language: 'rus',
      args: {"preserve_interword_spaces": "1"},
    );

    List<Product> products = [];
    final lines = text.split('\n');

    for (String line in lines) {
      final cleanedLine = line.replaceAll(RegExp(r'[^а-яА-Я0-9\s]'), '');

      // Основной паттерн
      final quantityMatch = RegExp(r'(\d+[\.,]?\d*)\s*(л|кг|г|мл|шт)').firstMatch(cleanedLine);
      if (quantityMatch != null) {
        final productName = cleanedLine.substring(0, quantityMatch.start).trim();
        final quantity = '${quantityMatch.group(1)} ${quantityMatch.group(2)}';

        products.add(Product(
          _uuid.v4(),
          productName,
          quantity,
          'Pantry',
          expirationDate: _estimateExpirationDate(productName),
        ));
      }

      // Дополнительные паттерны
      final patterns = [
        RegExp(r'([а-яА-Я\s]+)\s+(\d+[\.,]?\d*)\s*(л|кг|г|мл|шт)'),
        RegExp(r'(\d+[\.,]?\d*)\s*(л|кг|г|мл|шт)\s+([а-яА-Я\s]+)'),
      ];

      for (var pattern in patterns) {
        final match = pattern.firstMatch(cleanedLine);
        if (match != null) {
          final productName = match.group(1)?.trim() ?? '';
          final quantity = '${match.group(2)} ${match.group(3)}';

          if (!products.any((p) => p.name == productName)) {
            products.add(Product(
              _uuid.v4(),
              productName,
              quantity,
              'Pantry',
              expirationDate: _estimateExpirationDate(productName),
            ));
          }
          break;
        }
      }
    }

    return products;
  }

  DateTime _estimateExpirationDate(String productName) {
    final now = DateTime.now();
    // Простая логика определения срока годности
    const defaultExpiration = Duration(days: 7);
    final productType = productName.toLowerCase();

    if (productType.contains('молоко') || productType.contains('йогурт')) {
      return now.add(const Duration(days: 5));
    }
    if (productType.contains('сыр') || productType.contains('колбаса')) {
      return now.add(const Duration(days: 10));
    }
    return now.add(defaultExpiration);
  }
}