// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class Recipe extends _Recipe with RealmEntity, RealmObjectBase, RealmObject {
  Recipe(
    String id,
    String title,
    String description,
    DateTime createdAt, {
    Iterable<String> ingredients = const [],
    Iterable<String> steps = const [],
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'title', title);
    RealmObjectBase.set(this, 'description', description);
    RealmObjectBase.set<RealmList<String>>(
        this, 'ingredients', RealmList<String>(ingredients));
    RealmObjectBase.set<RealmList<String>>(
        this, 'steps', RealmList<String>(steps));
    RealmObjectBase.set(this, 'createdAt', createdAt);
  }

  Recipe._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get title => RealmObjectBase.get<String>(this, 'title') as String;
  @override
  set title(String value) => RealmObjectBase.set(this, 'title', value);

  @override
  String get description =>
      RealmObjectBase.get<String>(this, 'description') as String;
  @override
  set description(String value) =>
      RealmObjectBase.set(this, 'description', value);

  @override
  RealmList<String> get ingredients =>
      RealmObjectBase.get<String>(this, 'ingredients') as RealmList<String>;
  @override
  set ingredients(covariant RealmList<String> value) =>
      throw RealmUnsupportedSetError();

  @override
  RealmList<String> get steps =>
      RealmObjectBase.get<String>(this, 'steps') as RealmList<String>;
  @override
  set steps(covariant RealmList<String> value) =>
      throw RealmUnsupportedSetError();

  @override
  DateTime get createdAt =>
      RealmObjectBase.get<DateTime>(this, 'createdAt') as DateTime;
  @override
  set createdAt(DateTime value) =>
      RealmObjectBase.set(this, 'createdAt', value);

  @override
  Stream<RealmObjectChanges<Recipe>> get changes =>
      RealmObjectBase.getChanges<Recipe>(this);

  @override
  Stream<RealmObjectChanges<Recipe>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<Recipe>(this, keyPaths);

  @override
  Recipe freeze() => RealmObjectBase.freezeObject<Recipe>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'title': title.toEJson(),
      'description': description.toEJson(),
      'ingredients': ingredients.toEJson(),
      'steps': steps.toEJson(),
      'createdAt': createdAt.toEJson(),
    };
  }

  static EJsonValue _toEJson(Recipe value) => value.toEJson();
  static Recipe _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'title': EJsonValue title,
        'description': EJsonValue description,
        'createdAt': EJsonValue createdAt,
      } =>
        Recipe(
          fromEJson(id),
          fromEJson(title),
          fromEJson(description),
          fromEJson(createdAt),
          ingredients: fromEJson(ejson['ingredients']),
          steps: fromEJson(ejson['steps']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(Recipe._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, Recipe, 'Recipe', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('title', RealmPropertyType.string),
      SchemaProperty('description', RealmPropertyType.string),
      SchemaProperty('ingredients', RealmPropertyType.string,
          collectionType: RealmCollectionType.list),
      SchemaProperty('steps', RealmPropertyType.string,
          collectionType: RealmCollectionType.list),
      SchemaProperty('createdAt', RealmPropertyType.timestamp),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
