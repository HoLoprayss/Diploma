import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Переход на главный экран через 2 секунды
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/main');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Светло-серый фон
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Верхний прямоугольник с "MEAL"
            Transform.rotate(
              angle: -0.1, // Небольшой наклон
              child: Container(
                width: 300,
                height: 80,
                margin: EdgeInsets.only(bottom: 100),
                decoration: BoxDecoration(
                  color: Colors.lightGreen[600],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'MEAL',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            // Нижний прямоугольник с "SAFE"
            Transform.rotate(
              angle: -0.1,
              child: Container(
                width: 300,
                height: 80,
                margin: EdgeInsets.only(top: 100), // Сдвиг вниз для пересечения
                decoration: BoxDecoration(
                  color: Colors.lightGreen[600],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'SAFE',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

