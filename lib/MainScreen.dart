import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'fridge_screen.dart';
import 'pantry_screen.dart';
import 'services/realm_service.dart';
import 'models/product.dart';
import 'add_product_screen.dart';
import 'scan_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/theme_provider.dart';
import 'settings_screen.dart';
import 'shopping_screen.dart';
import 'recipe_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isExpanded = false;
  final double _expandedFabSize = 150.0;
  final double _normalFabSize = 56.0;
  
  late RealmService realmService;
  
  // Переменные для хранения количества продуктов
  int _fridgeCount = 0;
  int _pantryCount = 0;
  int _expiredCount = 0;
  
  @override
  void initState() {
    super.initState();
    
    // Загрузка данных
    realmService = RealmService();
    
    // Получение актуальных данных о количестве продуктов
    _updateProductCounts();
    
    // Настройка системного UI
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    // Основная анимация появления
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    // Анимация для кнопки
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    // Пульсирующая анимация
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Запуск анимаций
    _fadeController.forward();
    Future.delayed(Duration(milliseconds: 400), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    realmService.close();
    super.dispose();
  }

  void _navigateToScan() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ScanReceiptScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    ).then((_) {
      // Обновляем статистику при возврате
      _updateProductCounts();
    });
  }

  void _navigateToAdd() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AddProductScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    ).then((_) {
      // Обновляем статистику при возврате
      _updateProductCounts();
    });
  }

  void _toggleFab() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }
  
  // Метод для подсчета продуктов по категориям
  void _updateProductCounts() {
    // Получаем все продукты
    final fridgeProducts = realmService.getProductsByCategory('Fridge');
    final pantryProducts = realmService.getProductsByCategory('Pantry');
    
    setState(() {
      _fridgeCount = fridgeProducts.length;
      _pantryCount = pantryProducts.length;
      
      // Подсчет просроченных продуктов
      DateTime now = DateTime.now();
      _expiredCount = 0;
      
      // Проверяем просроченные в холодильнике
      for (var product in fridgeProducts) {
        if (product.expirationDate != null && product.expirationDate!.isBefore(now)) {
          _expiredCount++;
        }
      }
      
      // Проверяем просроченные в кладовой
      for (var product in pantryProducts) {
        if (product.expirationDate != null && product.expirationDate!.isBefore(now)) {
          _expiredCount++;
        }
      }
    });
  }
  
  // Метод для навигации к экрану холодильника с обновлением статистики при возврате
  void _navigateToFridge() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FridgeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 400),
      ),
    ).then((_) {
      // Обновляем статистику при возврате
      _updateProductCounts();
    });
  }
  
  // Метод для навигации к экрану кладовой с обновлением статистики при возврате
  void _navigateToPantry() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PantryScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 400),
      ),
    ).then((_) {
      // Обновляем статистику при возврате
      _updateProductCounts();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildBackgroundDecoration(isDark),
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 10),
                      _buildWelcomeSection(),
                      SizedBox(height: 30),
                      _buildCategoriesSection(),
                      SizedBox(height: 30),
                      _buildStatsSection(size),
                      SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _buildExpandableFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF2A9D8F),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF2A9D8F).withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ]
              ),
              child: Icon(Icons.restaurant, color: Colors.white, size: 22),
            ),
            SizedBox(width: 12),
            Text(
              'MEALSAFE',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2A9D8F),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Color(0xFF2A9D8F)),
          onPressed: () {
            // Логика для уведомлений
          },
        ),
        IconButton(
          icon: Icon(Icons.settings, color: Color(0xFF2A9D8F)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBackgroundDecoration(bool isDark) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Color(0xFF2A9D8F).withOpacity(isDark ? 0.15 : 0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Color(0xFFF4A261).withOpacity(isDark ? 0.15 : 0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildWelcomeSection() {
    final theme = Theme.of(context);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Привет!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.displaySmall?.color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Отслеживайте свежесть своих продуктов',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoriesSection() {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _fadeController,
        curve: Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Категории',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          SizedBox(height: 16),
          _buildWideCategoryCard(
            title: 'ХОЛОДИЛЬНИК',
            icon: Icons.kitchen,
            gradientColors: [Color(0xFF2A9D8F), Color(0xFF56C4A8)],
            onTap: _navigateToFridge,
          ),
          SizedBox(height: 16),
          _buildWideCategoryCard(
            title: 'КЛАДОВАЯ',
            icon: Icons.storage,
            gradientColors: [Color(0xFFF4A261), Color(0xFFE76F51)],
            onTap: _navigateToPantry,
          ),
          SizedBox(height: 16),
          _buildWideCategoryCard(
            title: 'ПЛАН ПОКУПОК',
            icon: Icons.shopping_cart,
            gradientColors: [Color(0xFF4F8FFF), Color(0xFF38B6FF)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShoppingScreen()),
              );
            },
          ),
          SizedBox(height: 16),
          _buildWideCategoryCard(
            title: 'РЕЦЕПТЫ',
            icon: Icons.menu_book,
            gradientColors: [Color(0xFF8E54E9), Color(0xFF4776E6)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RecipeScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWideCategoryCard({
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.18),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 20),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                title.substring(0, 1) + title.substring(1).toLowerCase(),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ),
            SizedBox(width: 16),
            SizedBox(
              width: 90,
              child: Container(
                margin: EdgeInsets.only(right: 20),
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Открыть',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsSection(Size size) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Статистика хранения',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          SizedBox(height: 16),
          
          // Статистические карточки
          Container(
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF2D3748) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(
                        title: 'Холодильник',
                        count: _fridgeCount,
                        icon: Icons.kitchen,
                        color: Color(0xFF2A9D8F),
                      ),
                      _buildStatItem(
                        title: 'Кладовая',
                        count: _pantryCount,
                        icon: Icons.storage,
                        color: Color(0xFFF4A261),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Container(
                    height: 1,
                    color: isDark ? Colors.grey[700] : Colors.grey[200],
                  ),
                  SizedBox(height: 24),
                  _buildStatItem(
                    title: 'Просрочено',
                    count: _expiredCount,
                    icon: Icons.warning_amber_rounded,
                    color: Color(0xFFE76F51),
                    isWarning: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    bool isWarning = false,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        SizedBox(height: 12),
        Text(
          '$count',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: isWarning ? color : theme.textTheme.titleLarge?.color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  Widget _buildExpandableFab() {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: _isExpanded ? _expandedFabSize : _normalFabSize,
        height: _isExpanded ? _expandedFabSize : _normalFabSize,
        decoration: BoxDecoration(
          color: _isExpanded 
            ? (isDark ? Color(0xFF2D3748) : Colors.white) 
            : Color(0xFFF4A261),
          borderRadius: BorderRadius.circular(_isExpanded ? 30 : 16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFF4A261).withOpacity(_isExpanded 
                ? (isDark ? 0.3 : 0.2) 
                : (isDark ? 0.5 : 0.4)),
              blurRadius: 20,
              offset: Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(_isExpanded ? 30 : 16),
            onTap: _isExpanded ? null : _toggleFab,
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _isExpanded
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        // Закрыть кнопку
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: _toggleFab,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? Color(0xFF1E293B) : Color(0xFFE2E8F0),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, 
                                color: isDark ? Color(0xFFCBD5E1) : Color(0xFF718096), 
                                size: 16
                              ),
                            ),
                          ),
                        ),
                        // Кнопки действий
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildFabOption(
                              icon: Icons.qr_code_scanner,
                              label: 'Сканировать чек',
                              color: Color(0xFF2A9D8F),
                              onTap: () {
                                _toggleFab();
                                _navigateToScan();
                              },
                            ),
                            SizedBox(height: 16),
                            _buildFabOption(
                              icon: Icons.add_circle_outline,
                              label: 'Добавить продукт',
                              color: Color(0xFFF4A261),
                              onTap: () {
                                _toggleFab();
                                _navigateToAdd();
                              },
                            ),
                          ],
                        ),
                      ],
                    )
                  : Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFabOption({
    required IconData icon, 
    required String label, 
    required Color color,
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}