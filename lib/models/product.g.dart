// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Product _$ProductFromJson(Map<String, dynamic> json) => _Product()
  ..id = json['id'] as String
  ..name = json['name'] as String
  ..quantity = json['quantity'] as String
  ..expirationDate = json['expirationDate'] == null
      ? null
      : DateTime.parse(json['expirationDate'] as String)
  ..category = json['category'] as String;

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'quantity': instance.quantity,
      'expirationDate': instance.expirationDate?.toIso8601String(),
      'category': instance.category,
    };
