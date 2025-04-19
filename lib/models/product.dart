import 'package:realm/realm.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';
part 'product.realm.dart';

@RealmModel()
@JsonSerializable()
class _Product {
  @PrimaryKey()
  late String id; // Уникальный идентификатор
  late String name; // Название продукта
  late String quantity; // Количество (например, "2 кг")
  late DateTime? expirationDate; // Срок годности (опционально)
  late String category; // Категория ("Fridge" или "Pantry")

  // factory _Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  // Map<String, dynamic> toJson() => _$ProductToJson(this);
}
