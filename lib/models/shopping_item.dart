import 'package:realm/realm.dart';

part 'shopping_item.realm.dart';

@RealmModel()
abstract class _ShoppingItem {
  @PrimaryKey()
  late String id; // Уникальный идентификатор
  late String name; // Название товара
  late String quantity; // Количество (например, "2 шт")
  late bool isBought; // Куплен ли товар
} 