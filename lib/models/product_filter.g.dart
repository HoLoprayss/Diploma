// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductFilter _$ProductFilterFromJson(Map<String, dynamic> json) =>
    ProductFilter(
      expirationFilter: json['expirationFilter'] == null
          ? null
          : ExpirationFilter.fromJson(
              json['expirationFilter'] as Map<String, dynamic>,
            ),
      quantityFilter: json['quantityFilter'] == null
          ? null
          : QuantityFilter.fromJson(
              json['quantityFilter'] as Map<String, dynamic>,
            ),
      nameFilter: json['nameFilter'] as String?,
      filterName: json['filterName'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ProductFilterToJson(ProductFilter instance) =>
    <String, dynamic>{
      'expirationFilter': instance.expirationFilter,
      'quantityFilter': instance.quantityFilter,
      'nameFilter': instance.nameFilter,
      'filterName': instance.filterName,
      'createdAt': instance.createdAt.toIso8601String(),
    };

ExpirationFilter _$ExpirationFilterFromJson(Map<String, dynamic> json) =>
    ExpirationFilter(
      type: $enumDecode(_$ExpirationFilterTypeEnumMap, json['type']),
      days: (json['days'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ExpirationFilterToJson(ExpirationFilter instance) =>
    <String, dynamic>{
      'type': _$ExpirationFilterTypeEnumMap[instance.type]!,
      'days': instance.days,
    };

const _$ExpirationFilterTypeEnumMap = {
  ExpirationFilterType.expired: 'expired',
  ExpirationFilterType.expiresToday: 'expiresToday',
  ExpirationFilterType.expiresThisWeek: 'expiresThisWeek',
  ExpirationFilterType.expiresThisMonth: 'expiresThisMonth',
  ExpirationFilterType.noExpiration: 'noExpiration',
  ExpirationFilterType.customDays: 'customDays',
};

QuantityFilter _$QuantityFilterFromJson(Map<String, dynamic> json) =>
    QuantityFilter(
      comparisonType: $enumDecode(
        _$QuantityComparisonTypeEnumMap,
        json['comparisonType'],
      ),
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
    );

Map<String, dynamic> _$QuantityFilterToJson(
  QuantityFilter instance,
) => <String, dynamic>{
  'comparisonType': _$QuantityComparisonTypeEnumMap[instance.comparisonType]!,
  'value': instance.value,
  'unit': instance.unit,
};

const _$QuantityComparisonTypeEnumMap = {
  QuantityComparisonType.greaterThan: 'greaterThan',
  QuantityComparisonType.lessThan: 'lessThan',
  QuantityComparisonType.equals: 'equals',
  QuantityComparisonType.greaterThanOrEqual: 'greaterThanOrEqual',
  QuantityComparisonType.lessThanOrEqual: 'lessThanOrEqual',
};
