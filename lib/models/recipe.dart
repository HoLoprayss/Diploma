import 'package:realm/realm.dart';

part 'recipe.realm.dart';

@RealmModel()
abstract class _Recipe {
  @PrimaryKey()
  late String id;
  late String title;
  late String description;
  late List<String> ingredients;
  late List<String> steps;
  late DateTime createdAt;
} 