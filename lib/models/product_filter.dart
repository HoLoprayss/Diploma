import 'package:json_annotation/json_annotation.dart';

part 'product_filter.g.dart';

/// Модель для хранения настроек фильтрации продуктов
@JsonSerializable()
class ProductFilter {
  /// Фильтр по сроку годности
  final ExpirationFilter? expirationFilter;
  
  /// Фильтр по количеству продукта
  final QuantityFilter? quantityFilter;
  
  /// Фильтр по названию продукта
  final String? nameFilter;
  
  /// Название сохраненного фильтра
  final String? filterName;
  
  /// Время создания фильтра
  final DateTime createdAt;

  ProductFilter({
    this.expirationFilter,
    this.quantityFilter,
    this.nameFilter,
    this.filterName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Создает копию фильтра с новыми параметрами
  ProductFilter copyWith({
    ExpirationFilter? expirationFilter,
    QuantityFilter? quantityFilter,
    String? nameFilter,
    String? filterName,
  }) {
    return ProductFilter(
      expirationFilter: expirationFilter ?? this.expirationFilter,
      quantityFilter: quantityFilter ?? this.quantityFilter,
      nameFilter: nameFilter ?? this.nameFilter,
      filterName: filterName ?? this.filterName,
      createdAt: this.createdAt,
    );
  }

  /// Проверяет, активен ли фильтр
  bool get isActive {
    return expirationFilter != null || 
           quantityFilter != null || 
           (nameFilter != null && nameFilter!.isNotEmpty);
  }

  /// Сбрасывает все фильтры
  ProductFilter clear() {
    return ProductFilter();
  }

  factory ProductFilter.fromJson(Map<String, dynamic> json) => 
      _$ProductFilterFromJson(json);
  
  Map<String, dynamic> toJson() => _$ProductFilterToJson(this);
}

/// Фильтр по сроку годности
@JsonSerializable()
class ExpirationFilter {
  /// Тип фильтра по сроку годности
  final ExpirationFilterType type;
  
  /// Количество дней (для пользовательского диапазона)
  final int? days;

  ExpirationFilter({
    required this.type,
    this.days,
  });

  factory ExpirationFilter.fromJson(Map<String, dynamic> json) => 
      _$ExpirationFilterFromJson(json);
  
  Map<String, dynamic> toJson() => _$ExpirationFilterToJson(this);
}

/// Типы фильтров по сроку годности
enum ExpirationFilterType {
  /// Просроченные продукты
  expired,
  
  /// Истекающие сегодня
  expiresToday,
  
  /// Истекающие в течение недели
  expiresThisWeek,
  
  /// Истекающие в течение месяца
  expiresThisMonth,
  
  /// Без срока годности
  noExpiration,
  
  /// Пользовательский диапазон дней
  customDays,
}

/// Фильтр по количеству продукта
@JsonSerializable()
class QuantityFilter {
  /// Тип сравнения
  final QuantityComparisonType comparisonType;
  
  /// Значение для сравнения
  final double value;
  
  /// Единица измерения
  final String unit;

  QuantityFilter({
    required this.comparisonType,
    required this.value,
    required this.unit,
  });

  factory QuantityFilter.fromJson(Map<String, dynamic> json) => 
      _$QuantityFilterFromJson(json);
  
  Map<String, dynamic> toJson() => _$QuantityFilterToJson(this);
}

/// Типы сравнения количества
enum QuantityComparisonType {
  /// Больше чем
  greaterThan,
  
  /// Меньше чем
  lessThan,
  
  /// Равно
  equals,
  
  /// Больше или равно
  greaterThanOrEqual,
  
  /// Меньше или равно
  lessThanOrEqual,
} 