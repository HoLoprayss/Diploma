import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';
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
import 'package:flutter_svg/flutter_svg.dart';
import 'widgets/app_icon.dart';
import 'constants/app_icons.dart';
import 'notifications_history_screen.dart';
import 'services/notifications.dart';
import 'services/realm_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mealsafe/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int _totalCount = 0;
  int _expiringSoonCount = 0;
  Map<String, int> _categoryCounts = {};
  String _topCategory = '';
  
  @override
  void initState() {
    super.initState();
    
    // Загрузка данных
    realmService = RealmService();

    // Загружаем уже показанные уведомления
    _loadShownNotifications();
    
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
    final allProducts = realmService.getAllProducts();

    setState(() {
      _fridgeCount = fridgeProducts.length;
      _pantryCount = pantryProducts.length;
      _totalCount = allProducts.length;

      // Подсчет просроченных продуктов и истекающих скоро
      DateTime now = DateTime.now();
      DateTime soonDate = now.add(Duration(days: 3)); // Истекают в ближайшие 3 дня

      _expiredCount = allProducts
          .where((product) =>
      product.expirationDate != null &&
          product.expirationDate!.isBefore(now))
          .length;

      _expiringSoonCount = allProducts
          .where((product) =>
      product.expirationDate != null &&
          product.expirationDate!.isAfter(now) &&
          product.expirationDate!.isBefore(soonDate))
          .length;

      // Проверяем и планируем уведомления
      _checkAndScheduleExpiryNotifications(allProducts.toList(), now, soonDate);

      // Подсчет категорий
      _categoryCounts = {};
      allProducts.forEach((product) {
        _categoryCounts.update(product.category, (count) => count + 1, ifAbsent: () => 1);
      });

      if (_categoryCounts.isNotEmpty) {
        _topCategory = _categoryCounts.keys.reduce((a, b) =>
        _categoryCounts[a]! > _categoryCounts[b]! ? a : b);
      }
    });
  }

  void _checkAndScheduleExpiryNotifications(List<Product> products, DateTime now, DateTime soonDate) {
    for (final product in products) {
      if (product.expirationDate != null) {
        // Проверяем, что срок истекает в ближайшие 3 дня
        if (product.expirationDate!.isAfter(now) &&
            product.expirationDate!.isBefore(soonDate)) {

          // Проверяем, не было ли уже уведомления
          if (!_wasNotificationShown(product.id)) {
            // Планируем уведомление за 3 дня до окончания срока
            final notificationTime = product.expirationDate!.subtract(const Duration(days: 3));

            // Планируем уведомление
            _scheduleNotification(
              id: product.id,
              title: 'Срок годности',
              body: 'Продукт "${product.name}" испортится через 3 дня!',
              scheduledTime: notificationTime,
            );

            // Отмечаем, что уведомление запланировано
            _markNotificationAsShown(product.id);
          }
        }
      }
    }
  }

  Future<void> _scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final notificationService = NotificationService();

    // Проверяем, что время уведомления в будущем
    if (scheduledTime.isAfter(DateTime.now())) {
      await notificationService.scheduleExpiryNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
      );
    }
  }

  // Хранилище для отслеживания показанных уведомлений
  final Set<String> _shownNotifications = <String>{};

// Проверяет, было ли уже показано уведомление для продукта
  bool _wasNotificationShown(String productId) {
    return _shownNotifications.contains(productId);
  }

// Отмечает уведомление как показанное
  void _markNotificationAsShown(String productId) {
    _shownNotifications.add(productId);
    // Сохраняем в SharedPreferences для персистентности
    _saveShownNotifications();
  }

// Сохранение в SharedPreferences
  Future<void> _saveShownNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('shown_notifications', _shownNotifications.toList());
  }

// Загрузка из SharedPreferences
  Future<void> _loadShownNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('shown_notifications');
    if (saved != null) {
      _shownNotifications.addAll(saved);
    }
  }
  
  // Метод для получения названия категории по иконке
  String _getCategoryNameByIcon(String iconPath) {
    if (iconPath.contains('dairy')) return 'Молочные';
    if (iconPath.contains('meat')) return 'Мясо';
    if (iconPath.contains('vegetables')) return 'Овощи';
    if (iconPath.contains('fruits')) return 'Фрукты';
    if (iconPath.contains('bread')) return 'Хлеб';
    if (iconPath.contains('beverages')) return 'Напитки';
    if (iconPath.contains('snacks')) return 'Снеки';
    if (iconPath.contains('canned')) return 'Консервы';
    if (iconPath.contains('frozen')) return 'Заморозка';
    if (iconPath.contains('grains')) return 'Крупы';
    if (iconPath.contains('fish')) return 'Рыба';
    if (iconPath.contains('eggs')) return 'Яйца';
    if (iconPath.contains('nuts')) return 'Орехи';
    if (iconPath.contains('baby_food')) return 'Дет. питание';
    if (iconPath.contains('household')) return 'Бытовая химия';
    return 'Прочее';
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

  // void _testNotification() {
  //   print('=== ЗАПУСК ТЕСТОВОГО УВЕДОМЛЕНИЯ ===');
  //
  //   // final notificationService = NotificationService();
  //
  //   // Планируем уведомление через 5 секунд
  //   final testTime = DateTime.now().add(Duration(seconds: 5));
  //
  //   print('Время уведомления: $testTime');
  //
  //   notificationService.scheduleExpiryNotification(
  //     id: 'test_notification',
  //     title: 'Тестовое уведомление',
  //     body: 'Это тестовое напоминание от MEALSAFE. Работает!',
  //     scheduledTime: testTime,
  //   ).then((_) {
  //     print('Уведомление успешно запланировано');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Тестовое уведомление запланировано на 5 секунд'),
  //           duration: Duration(seconds: 2),
  //         )
  //     );
  //   }).catchError((error) {
  //     print('Ошибка при планировании уведомления: $error');
  //   });
  //
  //   print('Метод scheduleExpiryNotification вызван');
  // }

  void _testNotification() async {
    try {
      print('=== ЗАПУСК ТЕСТОВОГО УВЕДОМЛЕНИЯ ===');

      const String testTaskId = 'test_notification_task';
      const String _testTaskName = 'test_notification'; // Добавь здесь


      // Регистрируем однократную задачу
      await Workmanager().registerOneOffTask(
        testTaskId,
        _testTaskName, // Используем правильное имя задачи
        initialDelay: Duration(seconds: 10),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );

      print('Тестовая задача запланирована на 10 секунд');

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Тестовое уведомление запланировано через 10 секунд'),
            duration: Duration(seconds: 3),
          )
      );
    } catch (e) {
      print('Ошибка при планировании тестового уведомления: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          )
      );
    }
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
        child: Text(
          'MEALSAFE',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2A9D8F),
            letterSpacing: 1.2,
          ),
        ),
      ),
      actions: [

        // Кнопка тестового уведомления
        IconButton(
          icon: Icon(Icons.bug_report, color: Colors.black),
          tooltip: 'Тест уведомления',
          onPressed: _testNotification,
        ),

        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Color(0xFF2A9D8F)),
          onPressed: () {
            // Открываем экран с историей уведомлений
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationsHistoryScreen()),
            );
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
          
          // Основные статистические карточки
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
                  // Первый ряд - Холодильник и Кладовая
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItemWithSvg(
                          title: 'Холодильник',
                          count: _fridgeCount,
                          iconPath: AppIcons.fridge,
                          color: Color(0xFF2A9D8F),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildStatItemWithSvg(
                          title: 'Кладовая',
                          count: _pantryCount,
                          iconPath: AppIcons.pantry,
                          color: Color(0xFFF4A261),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  
                  // Второй ряд - Всего продуктов и Истекает скоро
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          title: 'Всего продуктов',
                          count: _totalCount,
                          icon: Icons.inventory_2_outlined,
                          color: Color(0xFF4F8FFF),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildStatItem(
                          title: 'Истекает скоро',
                          count: _expiringSoonCount,
                          icon: Icons.schedule,
                          color: Color(0xFFFF9800),
                          isWarning: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  
                  // Третий ряд - Просрочено (по центру)
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(), // Пустой контейнер для центрирования
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildStatItem(
                          title: 'Просрочено',
                          count: _expiredCount,
                          icon: Icons.warning_amber_rounded,
                          color: Color(0xFFE76F51),
                          isWarning: true,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(), // Пустой контейнер для центрирования
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          // Карточка с популярной категорией и топ категориями
          if (_topCategory.isNotEmpty) ...[
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Популярные категории',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.titleMedium?.color,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildTopCategoryItem(),
                    SizedBox(height: 12),
                    _buildCategoryList(),
                  ],
                ),
              ),
            ),
          ],
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
    final bool isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          SizedBox(height: 16),
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isWarning ? color : theme.textTheme.titleLarge?.color,
              height: 1.0,
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItemWithSvg({
    required String title,
    required int count,
    required String iconPath,
    required Color color,
    bool isWarning = false,
  }) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppIcon(
               iconPath,
               width: 28,
               height: 28,
               color: color,
             ),
          ),
          SizedBox(height: 16),
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isWarning ? color : theme.textTheme.titleLarge?.color,
              height: 1.0,
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopCategoryItem() {
    final theme = Theme.of(context);
    final topCount = _categoryCounts[_topCategory] ?? 0;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF8E54E9).withOpacity(0.1), Color(0xFF4776E6).withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF8E54E9).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF8E54E9).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.trending_up,
              color: Color(0xFF8E54E9),
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Топ категория: $_topCategory',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                Text(
                  '$topCount продуктов',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$topCount',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8E54E9),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryList() {
    final theme = Theme.of(context);
    
    // Сортируем категории по количеству (исключая топ категорию)
    final sortedCategories = _categoryCounts.entries
        .where((entry) => entry.key != _topCategory && entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Показываем только топ 3 категории (исключая главную)
    final topCategories = sortedCategories.take(3).toList();
    
    if (topCategories.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Column(
      children: topCategories.map((entry) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFF4F8FFF).withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                ),
              ),
              Text(
                '${entry.value}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F8FFF),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
                            // _buildFabOption(
                            //   icon: Icons.notifications_active,
                            //   label: 'Тест уведомления',
                            //   color: Color(0xFFE76F51),
                            //   onTap: () {
                            //     _toggleFab();
                            //     _testNotification();
                            //   },
                            // ),
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