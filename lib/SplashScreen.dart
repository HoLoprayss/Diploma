import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // Контроллеры анимаций
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoSlideAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Устанавливаем полноэкранный режим для SplashScreen
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersive,
      overlays: [],
    );
    
    // Настраиваем анимации
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    
    // Анимация появления
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    // Анимация масштабирования
    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    
    // Анимация слайда логотипа
    _logoSlideAnimation = Tween<double>(
      begin: -30.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    
    // Анимация слайда текста
    _textSlideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    
    // Анимация пульсации
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOutSine),
      ),
    )..addListener(() {
      setState(() {});  // Обновляем состояние для пульсации
    });
    
    // Анимация свечения
    _glowAnimation = Tween<double>(
      begin: 3.0,
      end: 8.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOutSine),
      ),
    );
    
    // Запускаем анимацию и зацикливаем пульсацию
    _animationController.forward();
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Зацикливаем только пульсацию после завершения основной анимации
        _animationController.repeat(
          reverse: true, 
          period: Duration(milliseconds: 2000),
          min: 0.7, 
          max: 1.0
        );
      }
    });
    
    // Переход на главный экран после задержки
    Timer(const Duration(milliseconds: 2800), () {
      Navigator.pushReplacementNamed(context, '/main');
      // Возвращаем системный интерфейс после перехода
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[50]!,
              Colors.grey[100]!,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value * _pulseAnimation.value,
                child: FadeTransition(
                  opacity: _fadeInAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Логотип (иконка)
                      Transform.translate(
                        offset: Offset(_logoSlideAnimation.value, 0),
                        child: _buildLogoIcon(),
                      ),
                      SizedBox(width: 15),
                      // Текст "MEALSAFE"
                      Transform.translate(
                        offset: Offset(_textSlideAnimation.value, 0),
                        child: Text(
                          'MEALSAFE',
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2A9D8F),
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.1),
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  // Создаем логотип приложения (SVG с буквой Y)
  Widget _buildLogoIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF2A9D8F).withOpacity(0.4 * _pulseAnimation.value),
                blurRadius: _glowAnimation.value * _pulseAnimation.value,
                spreadRadius: _glowAnimation.value / 4 * _pulseAnimation.value,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: Color(0xFF2A9D8F).withOpacity(0.2 * _pulseAnimation.value),
                blurRadius: _glowAnimation.value * 2 * _pulseAnimation.value,
                spreadRadius: _glowAnimation.value / 2 * _pulseAnimation.value,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SvgPicture.asset(
              'assets/icons/app_logo.svg',
              width: 76,
              height: 76,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}

