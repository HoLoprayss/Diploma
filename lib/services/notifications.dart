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
const Duration _frequency = Duration(minutes: 15);

void initLocalNotifications() async {
  if (Platform.isWindows) {
    return;
  }

  // Инициализируем WorkManager
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Оставь true для отладки
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

      // Инициализация часовых поясов
      tz.initializeTimeZones();

      // Настройка уведомлений
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Инициализация уведомлений
      await notifPlugin.initialize(settings);
      print('Уведомления инициализированы');

      // Обработка разных типов задач
      if (task == _testTaskName) {
        print('Запуск тестового уведомления');
        await _showTestNotification(notifPlugin);
      } else {
        print('Запуск периодической проверки');
        await _showTestNotification(notifPlugin); // Для теста
        // await _checkExpiringProducts(notifPlugin);
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