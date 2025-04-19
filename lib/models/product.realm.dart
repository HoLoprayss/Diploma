// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class Product extends _Product with RealmEntity, RealmObjectBase, RealmObject {
  Product(
    String id,
    String name,
    String quantity,
    String category, {
    DateTime? expirationDate,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'quantity', quantity);
    RealmObjectBase.set(this, 'expirationDate', expirationDate);
    RealmObjectBase.set(this, 'category', category);
  }

  Product._();

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
  DateTime? get expirationDate =>
      RealmObjectBase.get<DateTime>(this, 'expirationDate') as DateTime?;
  @override
  set expirationDate(DateTime? value) =>
      RealmObjectBase.set(this, 'expirationDate', value);

  @override
  String get category =>
      RealmObjectBase.get<String>(this, 'category') as String;
  @override
  set category(String value) => RealmObjectBase.set(this, 'category', value);

  @override
  Stream<RealmObjectChanges<Product>> get changes =>
      RealmObjectBase.getChanges<Product>(this);

  @override
  Stream<RealmObjectChanges<Product>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<Product>(this, keyPaths);

  @override
  Product freeze() => RealmObjectBase.freezeObject<Product>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'name': name.toEJson(),
      'quantity': quantity.toEJson(),
      'expirationDate': expirationDate.toEJson(),
      'category': category.toEJson(),
    };
  }

  static EJsonValue _toEJson(Product value) => value.toEJson();
  static Product _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'name': EJsonValue name,
        'quantity': EJsonValue quantity,
        'category': EJsonValue category,
      } =>
        Product(
          fromEJson(id),
          fromEJson(name),
          fromEJson(quantity),
          fromEJson(category),
          expirationDate: fromEJson(ejson['expirationDate']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(Product._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, Product, 'Product', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('name', RealmPropertyType.string),
      SchemaProperty('quantity', RealmPropertyType.string),
      SchemaProperty('expirationDate', RealmPropertyType.timestamp,
          optional: true),
      SchemaProperty('category', RealmPropertyType.string),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
