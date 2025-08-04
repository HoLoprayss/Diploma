import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:realm/realm.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mealsafe/models/product.dart';

// WorkManager input data
const String _uniqueName = 'expiry_check_task';
const String _taskName = 'check_expiry_products';

// Notifications plugin input data
const String _channelId = 'expiry_notifications';
const String _channelName = 'Напоминания о сроках годности';
const String _channelDescription = 'Уведомления о продуктах, срок годности которых приближается';

// Проверяем каждые 15 минут
const Duration _frequency = Duration(seconds: 30);

// Хранилище для отслеживания показанных уведомлений
final Set<String> _shownNotifications = <String>{};

void initLocalNotifications() async {
  if (Platform.isWindows) {
    return;
  }

  // Загружаем уже показанные уведомления из SharedPreferences
  await _loadShownNotifications();

  // Инициализируем WorkManager
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Поменяй на false в релизе
  );

  // Регистрируем периодическую задачу
  Workmanager().registerPeriodicTask(
    _uniqueName,
    _taskName,
    frequency: _frequency,
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
  );
}


@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {

    print('=== WorkManager задача запущена ===');
    Workmanager().printScheduledTasks();

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

    await notifPlugin.initialize(settings);

    // Проверяем продукты и показываем уведомления
    await _checkExpiringProducts(notifPlugin);

    // Сохраняем состояние показанных уведомлений
    await _saveShownNotifications();

    return Future.value(true);
  });
}

Future<void> _checkExpiringProducts(FlutterLocalNotificationsPlugin notifPlugin) async {
  try {
    // Открываем Realm базу данных
    final config = Configuration.local([Product.schema]);
    final realm = Realm(config);

    // Получаем все продукты
    final allProducts = realm.all<Product>();
    final now = DateTime.now();
    final threeDaysFromNow = now.add(const Duration(days: 3));

    // Проверяем продукты, которые истекают в ближайшие 3 дня
    for (final product in allProducts) {
      if (product.expirationDate != null) {
        // Проверяем, что срок истекает в ближайшие 3 дня
        if (product.expirationDate!.isAfter(now) &&
            product.expirationDate!.isBefore(threeDaysFromNow)) {

          // Проверяем, не было ли уже уведомления
          if (!_wasNotificationShown(product.id)) {
            await _showExpiryNotification(notifPlugin, product);
            _markNotificationAsShown(product.id);
          }
        }
      }
    }

    realm.close();
  } catch (e) {
    print('Ошибка при проверке сроков годности: $e');
  }
}

Future<void> _showExpiryNotification(FlutterLocalNotificationsPlugin notifPlugin, Product product) async {
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
    product.id.hashCode,
    'Срок годности',
    'Продукт "${product.name}" испортится через 3 дня!',
    notificationDetails,
    payload: product.id,
  );
}

bool _wasNotificationShown(String productId) {
  return _shownNotifications.contains(productId);
}

void _markNotificationAsShown(String productId) {
  _shownNotifications.add(productId);
}

// Сохранение в SharedPreferences для персистентности
Future<void> _saveShownNotifications() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setStringList('shown_notifications', _shownNotifications.toList());
}

Future<void> _loadShownNotifications() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList('shown_notifications');
  if (saved != null) {
    _shownNotifications.addAll(saved);
  }
}