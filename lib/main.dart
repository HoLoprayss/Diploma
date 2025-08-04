import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'MainScreen.dart';
import 'SplashScreen.dart';
import 'theme/theme_provider.dart';
// import 'services/notification_service.dart';
import 'services/realm_service.dart';
import 'models/product.dart';
import 'services/notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('=== ЗАПУСК ПРИЛОЖЕНИЯ ===');

  // // Инициализируем сервис уведомлений
  // await NotificationService().init();
  // print('NotificationService инициализирован');
  //
  // // Загружаем и запланировать уведомления для существующих продуктов
  // await _scheduleAllExpiryNotifications();
  // print('Запланированы уведомления для существующих продуктов');

  // Инициализируем уведомления
  initLocalNotifications();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

// // Функция для планирования уведомлений для всех продуктов
// Future<void> _scheduleAllExpiryNotifications() async {
//   final realmService = RealmService();
//   final allProducts = realmService.getAllProducts();
//
//   for (var product in allProducts) {
//     if (product.expirationDate != null) {
//       _scheduleExpiryNotificationForProduct(product);
//     }
//   }
//
//   realmService.close();
// }

// void _scheduleExpiryNotificationForProduct(Product product) {
//   final now = DateTime.now();
//   final threeDaysBeforeExpiry = product.expirationDate!.subtract(const Duration(days: 3));
//
//   // Проверяем, что дата уведомления в будущем
//   if (threeDaysBeforeExpiry.isAfter(now)) {
//     NotificationService().scheduleExpiryNotification(
//       id: product.id,
//       title: 'Срок годности подходит к концу',
//       body: 'Продукт "${product.name}" испортится через 3 дня!',
//       scheduledTime: threeDaysBeforeExpiry,
//     );
//   }
// }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'MEALSAFE',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.getTheme(),
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => SplashScreen(),
            '/main': (context) => MainScreen(),
          },
        );
      },
    );
  }
}