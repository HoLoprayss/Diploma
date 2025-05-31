import 'package:realm/realm.dart';
import '../models/shopping_item.dart';
import 'package:uuid/uuid.dart' as uuid_lib;

class ShoppingService {
  late Configuration config;
  late Realm realm;

  ShoppingService() {
    config = Configuration.local([ShoppingItem.schema]);
    realm = Realm(config);
  }

  void addItem({String? name, String? quantity, bool isBought = false, ShoppingItem? item}) {
    realm.write(() {
      if (item != null) {
        realm.add(item);
      } else if (name != null && quantity != null) {
        final newItem = ShoppingItem(
          uuid_lib.Uuid().v4(),
          name,
          quantity,
          isBought,
        );
        realm.add(newItem);
      }
    });
  }

  RealmResults<ShoppingItem> getAllItems() {
    return realm.all<ShoppingItem>();
  }

  void updateItem(ShoppingItem item, {String? name, String? quantity, bool? isBought}) {
    realm.write(() {
      if (name != null) item.name = name;
      if (quantity != null) item.quantity = quantity;
      if (isBought != null) item.isBought = isBought;
    });
  }

  void deleteItem(ShoppingItem item) {
    realm.write(() {
      realm.delete(item);
    });
  }

  void close() {
    realm.close();
  }
} 