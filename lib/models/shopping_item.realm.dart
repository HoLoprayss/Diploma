// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_item.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class ShoppingItem extends _ShoppingItem
    with RealmEntity, RealmObjectBase, RealmObject {
  ShoppingItem(
    String id,
    String name,
    String quantity,
    bool isBought,
  ) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'quantity', quantity);
    RealmObjectBase.set(this, 'isBought', isBought);
  }

  ShoppingItem._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  String get quantity =>
      RealmObjectBase.get<String>(this, 'quantity') as String;
  @override
  set quantity(String value) => RealmObjectBase.set(this, 'quantity', value);

  @override
  bool get isBought => RealmObjectBase.get<bool>(this, 'isBought') as bool;
  @override
  set isBought(bool value) => RealmObjectBase.set(this, 'isBought', value);

  @override
  Stream<RealmObjectChanges<ShoppingItem>> get changes =>
      RealmObjectBase.getChanges<ShoppingItem>(this);

  @override
  Stream<RealmObjectChanges<ShoppingItem>> changesFor(
          [List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<ShoppingItem>(this, keyPaths);

  @override
  ShoppingItem freeze() => RealmObjectBase.freezeObject<ShoppingItem>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'name': name.toEJson(),
      'quantity': quantity.toEJson(),
      'isBought': isBought.toEJson(),
    };
  }

  static EJsonValue _toEJson(ShoppingItem value) => value.toEJson();
  static ShoppingItem _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'name': EJsonValue name,
        'quantity': EJsonValue quantity,
        'isBought': EJsonValue isBought,
      } =>
        ShoppingItem(
          fromEJson(id),
          fromEJson(name),
          fromEJson(quantity),
          fromEJson(isBought),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(ShoppingItem._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
        ObjectType.realmObject, ShoppingItem, 'ShoppingItem', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('name', RealmPropertyType.string),
      SchemaProperty('quantity', RealmPropertyType.string),
      SchemaProperty('isBought', RealmPropertyType.bool),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
