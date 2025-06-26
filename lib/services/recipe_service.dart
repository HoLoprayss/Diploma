import 'package:realm/realm.dart';
import '../models/recipe.dart';
import 'package:uuid/uuid.dart' as uuid_lib;

class RecipeService {
  late Configuration config;
  late Realm realm;

  RecipeService() {
    config = Configuration.local(
      [Recipe.schema],
      schemaVersion: 2,
      migrationCallback: (migration, oldSchemaVersion) {
        // Если просто добавили поле, миграция может быть пустой
        // Realm сам добавит новое поле с null/дефолтным значением для старых объектов
      },
    );
    realm = Realm(config);
  }

  void addRecipe({required String title, required String description, required List<String> ingredients, required List<String> steps, String? imagePath}) {
    final recipe = Recipe(
      uuid_lib.Uuid().v4(),
      title,
      description,
      DateTime.now(),
      ingredients: ingredients,
      steps: steps,
      imagePath: imagePath,
    );
    realm.write(() {
      realm.add(recipe);
    });
  }

  RealmResults<Recipe> getAllRecipes() {
    return realm.all<Recipe>();
  }

  void updateRecipe(Recipe recipe, {String? title, String? description, List<String>? ingredients, List<String>? steps, String? imagePath}) {
    realm.write(() {
      if (title != null) recipe.title = title;
      if (description != null) recipe.description = description;
      if (ingredients != null) {
        recipe.ingredients.clear();
        recipe.ingredients.addAll(ingredients);
      }
      if (steps != null) {
        recipe.steps.clear();
        recipe.steps.addAll(steps);
      }
      if (imagePath != null) recipe.imagePath = imagePath;
    });
  }

  void deleteRecipe(Recipe recipe) {
    realm.write(() {
      realm.delete(recipe);
    });
  }

  void close() {
    realm.close();
  }
} 