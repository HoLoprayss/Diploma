import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import 'package:uuid/uuid.dart';
import 'package:mealsafe/models/product.dart';
import 'package:mealsafe/preview_screen.dart';
import 'package:mealsafe/preview_edit_screen.dart';

class ScanReceiptScreen extends StatefulWidget {
  @override
  _ScanReceiptScreenState createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> with SingleTickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  MobileScannerController? _scannerController;
  bool _isLoading = false;
  bool _isQRMode = true; // Переключение между QR и фото
  final String TOKEN = '32894.FwqnuE9FZYMTdUPOs'; // токен
  
  // Для анимаций
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;
  
  // Для сообщений пользователю
  String _statusMessage = 'Наведите камеру на QR-код чека';
  bool _hasError = false;
  
  // Ключ для ScaffoldMessenger
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  // Основной акцентный цвет приложения
  Color get primaryColor => Color(0xFF2A9D8F);

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    
    // Инициализация анимаций
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000), // 2 секунды на полный цикл
    )..repeat(reverse: true);
    
    _scanAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Создаем контроллер для сканера
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _controller.initialize();
      setState(() {});
    } catch (e) {
      setState(() {
        _hasError = true;
        _statusMessage = 'Ошибка камеры: $e';
      });
      print('Ошибка камеры: $e');
    }
  }

  void _toggleFlash() async {
    await _scannerController?.toggleTorch();
    setState(() {}); // Обновляем UI для отображения изменения
  }

  void _handleBarcode(Barcode barcode) {
    if (barcode.rawValue != null && !_isLoading) {
      _scannerController?.stop();
      _processQRCode(barcode.rawValue!);
    }
  }

  Future<void> _processQRCode(String qrData) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Получение данных чека...';
      _hasError = false;
    });
    
    try {
      // Показываем анимированное уведомление
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                height: 20, 
                width: 20, 
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Обработка данных QR-кода чека...',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
          backgroundColor: primaryColor,
          duration: Duration(seconds: 2),
        ),
      );
      
      var response = await http.post(
        Uri.parse('https://proverkacheka.com/api/v1/check/get'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'qrraw=${Uri.encodeQueryComponent(qrData)}&token=$TOKEN',
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['code'] == 1) {
          var items = data['data']['json']['items'] as List;
          
          if (items.isEmpty) {
            throw Exception('В чеке не найдено товаров');
          }
          
          List<Product> products = items.map((item) {
            // Определяем категорию и срок годности на основе имени продукта
            String category = _determineCategory(item['name']);
            DateTime expirationDate = _calculateExpirationDate(category);
            
            return Product(
              Uuid().v4(),
              item['name'],
              item['quantity'].toString(),
              category,
              expirationDate: expirationDate,
            );
          }).toList();
          
          // Небольшая задержка для лучшего UX
          await Future.delayed(Duration(milliseconds: 500));

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProductsScreen(products: products),
            ),
          ).then((value) {
            // Восстанавливаем сканер при возврате на эту страницу
            if (mounted && _isQRMode) {
              _scannerController?.start();
              setState(() {
                _isLoading = false;
                _statusMessage = 'Наведите камеру на QR-код чека';
              });
            }
          });
        } else {
          throw Exception('Ошибка API: ${data['message'] ?? 'Код ошибки ${data['code']}'}');
        }
      } else {
        throw Exception('Ошибка HTTP: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _statusMessage = 'Ошибка: $e';
      });
      
      showDialog(
        context: context,
        builder: (context) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          
          return AlertDialog(
            title: Text(
              'Ошибка сканирования',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            content: Text(
              'Не удалось получить данные чека:\n\n$e\n\nПопробуйте еще раз или сделайте фото чека.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            backgroundColor: isDark ? Color(0xFF1E2937) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _scannerController?.start();
                },
                child: Text(
                  'Повторить',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isQRMode = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  'Сделать фото',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      // Если не отошли на другой экран, сбрасываем состояние загрузки
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _determineCategory(String name) {
    name = name.toLowerCase();
    
    // Продукты для холодильника
    List<String> fridgeKeywords = [
      'молоко', 'йогурт', 'кефир', 'творог', 'сметана', 'сыр', 'масло',
      'колбаса', 'сосиски', 'мясо', 'филе', 'рыба', 'яйца', 'яйцо',
      'тушенка', 'соус', 'майонез', 'сливки', 'десерт', 'молочный'
    ];
    
    // Проверка на ключевые слова для холодильника
    for (var keyword in fridgeKeywords) {
      if (name.contains(keyword)) return 'Fridge';
    }
    
    // По умолчанию - кладовая
    return 'Pantry';
  }
  
  DateTime _calculateExpirationDate(String category) {
    switch (category) {
      case 'Fridge':
        return DateTime.now().add(Duration(days: 7)); // Неделя для продуктов холодильника
      default:
        return DateTime.now().add(Duration(days: 30)); // Месяц для продуктов кладовой
    }
  }

  Future<void> _takePicture() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Делаем фото...';
    });
    
    try {
      await _initializeControllerFuture; // Убедимся, что камера инициализирована
      final imagePath = await _controller.takePicture();
      
      if (!mounted) return;

      // Небольшая задержка для лучшего UX
      await Future.delayed(Duration(milliseconds: 300));
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewScreen(imageFile: File(imagePath.path)),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _statusMessage = _isQRMode 
                ? 'Наведите камеру на QR-код чека'
                : 'Сделайте фото чека';
          });
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _statusMessage = 'Ошибка фото: $e';
      });
      print('Ошибка фотографии: $e');
      
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Не удалось сделать фото: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Камера или сканер
            _buildCameraView(),
            
            // Верхний бар с заголовком и кнопками
            _buildTopBar(),
            
            // Информационное сообщение
            _buildStatusMessage(),
            
            // Индикатор загрузки
            if (_isLoading) _buildLoadingIndicator(),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _buildActionButton(),
      ),
    );
  }
  
  Widget _buildCameraView() {
    if (_isQRMode) {
      return Container(
        color: Colors.black,
        child: Stack(
          children: [
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final barcode = barcodes.first;
                  _handleBarcode(barcode);
                }
              },
            ),
            // Добавляем накладку как отдельный слой поверх MobileScanner
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ScannerOverlayPainter(
                    scanPosition: _scanAnimation.value,
                    borderColor: primaryColor,
                  ),
                  child: Container(),
                );
              },
            ),
          ],
        ),
      );
    } else {
      return FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            );
          }
        },
      );
    }
  }
  
  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 48, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0),
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Text(
              _isQRMode ? 'Сканирование QR-кода' : 'Фото чека',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.flashlight_on_outlined,
                color: Colors.white,
              ),
              onPressed: _toggleFlash,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusMessage() {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _hasError ? 1.0 : _pulseAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              margin: EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: _hasError 
                    ? Colors.red.withOpacity(0.8)
                    : primaryColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E2937) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              SizedBox(height: 24),
              Text(
                _statusMessage,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton() {
    if (_isQRMode) {
      return Container(
        margin: EdgeInsets.only(bottom: 32),
        child: Text(
          'Удерживайте QR-код в рамке',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else {
      return Container(
        margin: EdgeInsets.only(bottom: 32),
        child: FloatingActionButton.extended(
          onPressed: _isLoading ? null : _takePicture,
          backgroundColor: primaryColor,
          icon: Icon(Icons.camera_alt),
          label: Text(
            'Сфотографировать',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
  }
}

// Кастомная отрисовка рамки сканера с анимированной линией
class ScannerOverlayPainter extends CustomPainter {
  final double scanPosition;
  final Color borderColor;

  ScannerOverlayPainter({
    required this.scanPosition, 
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    
    // Размеры рамки для QR-кода
    final double frameWidth = width * 0.7;
    final double frameHeight = frameWidth;
    final double left = (width - frameWidth) / 2;
    final double top = (height - frameHeight) / 2;
    
    // Рисуем полупрозрачный фон
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    // Верхняя часть фона
    canvas.drawRect(
      Rect.fromLTRB(0, 0, width, top),
      backgroundPaint,
    );
    
    // Нижняя часть фона
    canvas.drawRect(
      Rect.fromLTRB(0, top + frameHeight, width, height),
      backgroundPaint,
    );
    
    // Левая часть фона
    canvas.drawRect(
      Rect.fromLTRB(0, top, left, top + frameHeight),
      backgroundPaint,
    );
    
    // Правая часть фона
    canvas.drawRect(
      Rect.fromLTRB(left + frameWidth, top, width, top + frameHeight),
      backgroundPaint,
    );
    
    // Рисуем рамку
    final framePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    final frameRect = Rect.fromLTWH(left, top, frameWidth, frameHeight);
    canvas.drawRect(frameRect, framePaint);
    
    // Рисуем углы рамки для выделения
    final cornerSize = 20.0;
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
      
    // Верхний левый угол
    canvas.drawLine(
      Offset(left, top + cornerSize),
      Offset(left, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerSize, top),
      cornerPaint,
    );
    
    // Верхний правый угол
    canvas.drawLine(
      Offset(left + frameWidth - cornerSize, top),
      Offset(left + frameWidth, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + frameWidth, top),
      Offset(left + frameWidth, top + cornerSize),
      cornerPaint,
    );
    
    // Нижний левый угол
    canvas.drawLine(
      Offset(left, top + frameHeight - cornerSize),
      Offset(left, top + frameHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + frameHeight),
      Offset(left + cornerSize, top + frameHeight),
      cornerPaint,
    );
    
    // Нижний правый угол
    canvas.drawLine(
      Offset(left + frameWidth - cornerSize, top + frameHeight),
      Offset(left + frameWidth, top + frameHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + frameWidth, top + frameHeight),
      Offset(left + frameWidth, top + frameHeight - cornerSize),
      cornerPaint,
    );
    
    // Рисуем анимированную линию сканирования
    final scanPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    // Рассчитываем положение линии сканирования в пределах рамки
    final scanY = top + (frameHeight * (scanPosition + 1) / 2);
    
    // Рисуем линию с градиентом
    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          borderColor.withOpacity(0),
          borderColor.withOpacity(0.8),
          borderColor.withOpacity(0),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(left, scanY - 2, frameWidth, 4))
      ..style = PaintingStyle.fill;
      
    canvas.drawRect(
      Rect.fromLTWH(left, scanY - 2, frameWidth, 4),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanPosition != scanPosition;
  }
}