import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

// WorkManager input data
const String _uniqueName = 'expiry_check_task';
const String _taskName = 'check_expiry_products';
const String _testTaskName = 'test_notification';

// Notifications plugin input data
const String _channelId = 'expiry_notifications';
const String _channelName = 'Напоминания о сроках годности';
const String _channelDescription = 'Уведомления о продуктах, срок годности которых приближается';

// Проверяем каждые 15 минут
const Duration _frequency = Duration(seconds: 30);

void initLocalNotifications() async {
  if (Platform.isWindows) {
    return;
  }

  // Инициализируем WorkManager
  Workmanager().initialize(
    callbackDispatcher
  );

  // Регистрируем периодическую задачу
  await Workmanager().registerPeriodicTask(
    _uniqueName,
    _taskName,
    frequency: _frequency,
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
  );

  print('WorkManager инициализирован и периодическая задача зарегистрирована');
}


@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('=== WorkManager задача запущена: $task ===');

      final FlutterLocalNotificationsPlugin notifPlugin = FlutterLocalNotificationsPlugin();
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await notifPlugin.initialize(settings);
      print('Уведомления инициализированы');

      if (task == _testTaskName) {
        print('Запуск тестового уведомления');
        await _showTestNotification(notifPlugin);
      } else if (task == _taskName) {
        print('Запуск проверки сроков годности');
        await _checkExpiringProducts(notifPlugin);
      }

      print('Задача $task выполнена успешно');
      return Future.value(true);
    } catch (e, stackTrace) {
      print('Ошибка в callbackDispatcher: $e');
      print(stackTrace);
      return Future.value(false);
    }
  });
}

Future<void> _checkExpiringProducts(FlutterLocalNotificationsPlugin notifPlugin) async {
  try {
    print('=== НАЧАЛО ПРОВЕРКИ СРОКОВ ГОДНОСТИ ===');

    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList('expiry_notifications') ?? [];

    print('Найдено уведомлений: ${notifications.length}');

    final now = DateTime.now();
    print('Текущее время: $now');

    final notificationsToKeep = <String>[];

    for (int i = 0; i < notifications.length; i++) {
      final notificationData = notifications[i];
      print('Проверка уведомления #$i: $notificationData');

      final parts = notificationData.split('|');
      if (parts.length != 3) {
        print('Некорректный формат данных, пропускаем');
        notificationsToKeep.add(notificationData);
        continue;
      }

      final productId = parts[0];
      final productName = parts[1];
      final expiryDate = DateTime.parse(parts[2]);
      print('Продукт: $productName, ID: $productId, Срок годности: $expiryDate');

      // Рассчитываем дату для уведомления (за 3 дня до окончания срока)
      final notificationDate = expiryDate.subtract(const Duration(days: 3));
      print('Дата уведомления: $notificationDate');

      // Проверяем, что пришло время показать уведомление
      if (notificationDate.isBefore(now)) {
        print('ВРЕМЯ УВЕДОМЛЕНИЯ НАСТУПИЛО!');
        await _showExpiryNotification(
            notifPlugin,
            productId,
            productName,
            expiryDate
        );
        // Не добавляем в список для сохранения
      } else {
        print('Время уведомления еще не наступило');
        notificationsToKeep.add(notificationData);
      }
    }

    print('Сохраняем ${notificationsToKeep.length} уведомлений');
    await prefs.setStringList('expiry_notifications', notificationsToKeep);
    print('=== КОНЕЦ ПРОВЕРКИ СРОКОВ ГОДНОСТИ ===');

  } catch (e, stackTrace) {
    print('Ошибка при проверке сроков годности: $e');
    print(stackTrace);
  }
}

// Метод для тестового уведомления
Future<void> _showTestNotification(FlutterLocalNotificationsPlugin notifPlugin) async {
  try {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Тестовые уведомления',
      channelDescription: 'Уведомления для тестирования системы',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await notifPlugin.show(
      999,
      'Тестовое уведомление MEALSAFE',
      'Это тестовое напоминание работает! Поздравляем!',
      notificationDetails,
      payload: 'test_notification',
    );

    print('Тестовое уведомление показано');
  } catch (e, stackTrace) {
    print('Ошибка при показе тестового уведомления: $e');
    print(stackTrace);
  }
}

Future<void> _showExpiryNotification(
    FlutterLocalNotificationsPlugin notifPlugin,
    String productId,
    String productName,
    DateTime expiryDate
    ) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDescription,
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await notifPlugin.show(
    productId.hashCode,
    'Срок годности',
    'Продукт "$productName" скоро испортится!',
    notificationDetails,
    payload: productId,
  );
}