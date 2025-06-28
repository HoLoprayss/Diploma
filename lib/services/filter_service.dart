import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_filter.dart';
import '../models/product.dart';

/// Сервис для управления фильтрами продуктов
class FilterService {
  static const String _savedFiltersKey = 'saved_product_filters';
  static const String _currentFilterKey = 'current_product_filter';
  static const String _defaultFilterKey = 'default_product_filter';
  
  /// Применяет фильтр к списку продуктов
  static List<Product> applyFilter(List<Product> products, ProductFilter filter) {
    List<Product> filteredProducts = List.from(products);
    
    // Применяем фильтр по названию
    if (filter.nameFilter != null && filter.nameFilter!.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        return product.name.toLowerCase().contains(filter.nameFilter!.toLowerCase());
      }).toList();
    }
    
    // Применяем фильтр по сроку годности
    if (filter.expirationFilter != null) {
      filteredProducts = filteredProducts.where((product) {
        return _matchesExpirationFilter(product, filter.expirationFilter!);
      }).toList();
    }
    
    // Применяем фильтр по количеству
    if (filter.quantityFilter != null) {
      filteredProducts = filteredProducts.where((product) {
        return _matchesQuantityFilter(product, filter.quantityFilter!);
      }).toList();
    }
    
    return filteredProducts;
  }
  
  /// Проверяет соответствие продукта фильтру по сроку годности
  static bool _matchesExpirationFilter(Product product, ExpirationFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (filter.type) {
      case ExpirationFilterType.expired:
        return product.expirationDate != null && 
               product.expirationDate!.isBefore(today);
               
      case ExpirationFilterType.expiresToday:
        if (product.expirationDate == null) return false;
        final expirationDate = DateTime(
          product.expirationDate!.year,
          product.expirationDate!.month,
          product.expirationDate!.day,
        );
        return expirationDate.isAtSameMomentAs(today);
        
      case ExpirationFilterType.expiresThisWeek:
        if (product.expirationDate == null) return false;
        final weekFromNow = today.add(Duration(days: 7));
        return product.expirationDate!.isBefore(weekFromNow) && 
               !product.expirationDate!.isBefore(today);
               
      case ExpirationFilterType.expiresThisMonth:
        if (product.expirationDate == null) return false;
        final monthFromNow = DateTime(now.year, now.month + 1, now.day);
        return product.expirationDate!.isBefore(monthFromNow) && 
               !product.expirationDate!.isBefore(today);
               
      case ExpirationFilterType.noExpiration:
        return product.expirationDate == null;
        
      case ExpirationFilterType.customDays:
        if (product.expirationDate == null || filter.days == null) return false;
        final daysFromNow = today.add(Duration(days: filter.days!));
        return product.expirationDate!.isBefore(daysFromNow) && 
               !product.expirationDate!.isBefore(today);
    }
  }
  
  /// Проверяет соответствие продукта фильтру по количеству
  static bool _matchesQuantityFilter(Product product, QuantityFilter filter) {
    try {
      final productQuantity = _parseQuantity(product.quantity);
      if (productQuantity == null) return false;
      
      final filterValue = filter.value;
      
      switch (filter.comparisonType) {
        case QuantityComparisonType.greaterThan:
          return productQuantity > filterValue;
        case QuantityComparisonType.lessThan:
          return productQuantity < filterValue;
        case QuantityComparisonType.equals:
          return productQuantity == filterValue;
        case QuantityComparisonType.greaterThanOrEqual:
          return productQuantity >= filterValue;
        case QuantityComparisonType.lessThanOrEqual:
          return productQuantity <= filterValue;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Парсит количество из строки (например, "2 кг" -> 2.0)
  static double? _parseQuantity(String quantity) {
    if (quantity.isEmpty) return null;
    
    // Удаляем пробелы и приводим к нижнему регистру
    final cleanQuantity = quantity.trim().toLowerCase();
    
    // Ищем число в начале строки
    final numberMatch = RegExp(r'^(\d+(?:\.\d+)?)').firstMatch(cleanQuantity);
    if (numberMatch == null) return null;
    
    final number = double.tryParse(numberMatch.group(1)!);
    if (number == null) return null;
    
    // Проверяем единицы измерения
    final unit = cleanQuantity.substring(numberMatch.end).trim();
    
    // Поддерживаемые единицы измерения
    final supportedUnits = ['кг', 'г', 'л', 'мл', 'шт', 'шт.', 'pieces', 'kg', 'g', 'l', 'ml'];
    
    if (unit.isEmpty || supportedUnits.contains(unit)) {
      return number;
    }
    
    return null;
  }
  
  /// Сохраняет фильтр между сессиями
  static Future<void> saveFilter(ProductFilter filter, {bool isDefault = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isDefault ? _defaultFilterKey : _currentFilterKey;
    
    await prefs.setString(key, jsonEncode(filter.toJson()));
  }
  
  /// Загружает сохраненный фильтр
  static Future<ProductFilter?> loadFilter({bool isDefault = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isDefault ? _defaultFilterKey : _currentFilterKey;
    
    final filterJson = prefs.getString(key);
    if (filterJson == null) return null;
    
    try {
      final filterMap = jsonDecode(filterJson) as Map<String, dynamic>;
      return ProductFilter.fromJson(filterMap);
    } catch (e) {
      print('Error loading filter: $e');
      return null;
    }
  }
  
  /// Сохраняет пользовательский фильтр с именем
  static Future<void> saveCustomFilter(ProductFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Загружаем существующие фильтры
    final savedFiltersJson = prefs.getString(_savedFiltersKey);
    Map<String, ProductFilter> savedFilters = {};
    
    if (savedFiltersJson != null) {
      try {
        final filtersMap = jsonDecode(savedFiltersJson) as Map<String, dynamic>;
        savedFilters = filtersMap.map((key, value) => 
          MapEntry(key, ProductFilter.fromJson(value as Map<String, dynamic>))
        );
      } catch (e) {
        print('Error loading saved filters: $e');
      }
    }
    
    // Добавляем новый фильтр
    if (filter.filterName != null) {
      savedFilters[filter.filterName!] = filter;
    }
    
    // Сохраняем обратно
    await prefs.setString(_savedFiltersKey, jsonEncode(
      savedFilters.map((key, value) => MapEntry(key, value.toJson()))
    ));
  }
  
  /// Загружает все сохраненные пользовательские фильтры
  static Future<Map<String, ProductFilter>> loadSavedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFiltersJson = prefs.getString(_savedFiltersKey);
    
    if (savedFiltersJson == null) return {};
    
    try {
      final filtersMap = jsonDecode(savedFiltersJson) as Map<String, dynamic>;
      return filtersMap.map((key, value) => 
        MapEntry(key, ProductFilter.fromJson(value as Map<String, dynamic>))
      );
    } catch (e) {
      print('Error loading saved filters: $e');
      return {};
    }
  }
  
  /// Удаляет сохраненный фильтр
  static Future<void> deleteSavedFilter(String filterName) async {
    final prefs = await SharedPreferences.getInstance();
    
    final savedFilters = await loadSavedFilters();
    savedFilters.remove(filterName);
    
    await prefs.setString(_savedFiltersKey, jsonEncode(
      savedFilters.map((key, value) => MapEntry(key, value.toJson()))
    ));
  }
  
  /// Очищает все сохраненные фильтры
  static Future<void> clearAllFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedFiltersKey);
    await prefs.remove(_currentFilterKey);
    await prefs.remove(_defaultFilterKey);
  }
  
  /// Получает список поддерживаемых единиц измерения
  static List<String> getSupportedUnits() {
    return ['кг', 'г', 'л', 'мл', 'шт', 'шт.', 'pieces', 'kg', 'g', 'l', 'ml'];
  }
  
  /// Получает отображаемое название для типа фильтра по сроку годности
  static String getExpirationFilterDisplayName(ExpirationFilterType type) {
    switch (type) {
      case ExpirationFilterType.expired:
        return 'Просроченные';
      case ExpirationFilterType.expiresToday:
        return 'Истекают сегодня';
      case ExpirationFilterType.expiresThisWeek:
        return 'Истекают в течение недели';
      case ExpirationFilterType.expiresThisMonth:
        return 'Истекают в течение месяца';
      case ExpirationFilterType.noExpiration:
        return 'Без срока годности';
      case ExpirationFilterType.customDays:
        return 'Пользовательский диапазон';
    }
  }
  
  /// Получает отображаемое название для типа сравнения количества
  static String getQuantityComparisonDisplayName(QuantityComparisonType type) {
    switch (type) {
      case QuantityComparisonType.greaterThan:
        return 'Больше чем';
      case QuantityComparisonType.lessThan:
        return 'Меньше чем';
      case QuantityComparisonType.equals:
        return 'Равно';
      case QuantityComparisonType.greaterThanOrEqual:
        return 'Больше или равно';
      case QuantityComparisonType.lessThanOrEqual:
        return 'Меньше или равно';
    }
  }
} 