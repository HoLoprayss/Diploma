import 'package:realm/realm.dart';
import '../models/product.dart';
import 'package:uuid/uuid.dart' as uuid_lib;

class RealmService {
  late Configuration config;
  late Realm realm;

  RealmService() {
    config = Configuration.local([Product.schema]);
    realm = Realm(config);
  }

  // Добавление продукта
  void addProduct({String? name, String? quantity, DateTime? expirationDate, String? category, Product? product}) {
    realm.write(() {
      if (product != null) {
        realm.add(product);
      } else if (name != null && quantity != null && category != null) {
        // Создаем новый продукт из параметров
        final newProduct = Product(
          uuid_lib.Uuid().v4(),
          name,
          quantity,
          category,
          expirationDate: expirationDate,
        );
        realm.add(newProduct);
      }
    });
  }

  // Получение всех продуктов
  RealmResults<Product> getAllProducts() {
    return realm.all<Product>();
  }

  // Получение продуктов по категории
  RealmResults<Product> getProductsByCategory(String category) {
    return realm.all<Product>().query('category == \$0', [category]);
  }

  void updateProduct(Product product, {String? name, String? quantity, DateTime? expirationDate, String? category}) {
    realm.write(() {
      if (name != null) product.name = name;
      if (quantity != null) product.quantity = quantity;
      if (expirationDate != null) product.expirationDate = expirationDate;
      if (category != null) product.category = category;
    });
  }

  // Удаление продукта
  void deleteProduct(Product product) {
    realm.write(() {
      realm.delete(product);
    });
  }

  // Закрытие базы данных
  void close() {
    realm.close();
  }
}