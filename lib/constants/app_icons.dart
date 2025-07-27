/// Константы для путей к иконкам приложения
class AppIcons {
  // Основные иконки
  static const String fridge = 'assets/icons/fridge.svg';
  static const String pantry = 'assets/icons/pantry.svg';
  static const String shopping = 'assets/icons/shopping.svg';
  static const String recipes = 'assets/icons/recipes.svg';
  
  // Категории продуктов
  static const String dairy = 'assets/icons/dairy.svg';
  static const String milk = 'assets/icons/milk.svg';
  static const String meat = 'assets/icons/meat.svg';
  static const String vegetables = 'assets/icons/vegetables.svg';
  static const String fruits = 'assets/icons/fruits.svg';
  static const String bread = 'assets/icons/bread.svg';
  static const String beverages = 'assets/icons/beverages.svg';
  static const String snacks = 'assets/icons/snacks.svg';
  static const String canned = 'assets/icons/canned.svg';
  static const String frozen = 'assets/icons/frozen.svg';
  static const String grains = 'assets/icons/grains.svg';
  static const String fish = 'assets/icons/fish.svg';
  static const String eggs = 'assets/icons/eggs.svg';
  static const String household = 'assets/icons/household.svg';
  static const String babyFood = 'assets/icons/baby_food.svg';
  static const String nuts = 'assets/icons/nuts.svg';
  
  /// Получить иконку по категории продукта
  static String getIconByCategory(String productName) {
    final name = productName.toLowerCase();
    
    // Молоко и молочные напитки
    if (_containsAny(name, ['молоко', 'кефир', 'сливки', 'ряженка', 'йогурт питьевой'])) {
      return milk;
    }
    
    // Сыр и другие молочные продукты
    if (_containsAny(name, ['сыр', 'творог', 'сметана', 'йогурт', 'масло сливочное'])) {
      return dairy;
    }
    
    // Мясо и птица
    if (_containsAny(name, ['мясо', 'говядина', 'свинина', 'курица', 'индейка', 'колбаса', 'сосиски', 'ветчина', 'фарш', 'котлета'])) {
      return meat;
    }
    
    // Овощи
    if (_containsAny(name, ['картофель', 'морковь', 'лук', 'капуста', 'огурцы', 'помидоры', 'свекла', 'перец', 'баклажан', 'кабачок', 'чеснок', 'зелень'])) {
      return vegetables;
    }
    
    // Фрукты и ягоды
    if (_containsAny(name, ['яблоко', 'груша', 'банан', 'апельсин', 'мандарин', 'лимон', 'персик', 'слива', 'виноград', 'клубника', 'малина'])) {
      return fruits;
    }
    
    // Хлеб и выпечка
    if (_containsAny(name, ['хлеб', 'батон', 'булка', 'багет', 'печенье', 'кекс', 'пирог', 'круассан'])) {
      return bread;
    }
    
    // Напитки
    if (_containsAny(name, ['вода', 'сок', 'чай', 'кофе', 'молоко', 'квас', 'лимонад', 'напиток'])) {
      return beverages;
    }
    
    // Снеки и сладости
    if (_containsAny(name, ['шоколад', 'конфеты', 'чипсы', 'печенье', 'вафли', 'зефир', 'мармелад', 'орешки', 'попкорн'])) {
      return snacks;
    }
    
    // Консервы
    if (_containsAny(name, ['консервы', 'тушенка', 'шпроты', 'кукуруза консерв', 'горошек консерв'])) {
      return canned;
    }
    
    // Замороженные продукты
    if (_containsAny(name, ['замороженные', 'пельмени', 'вареники', 'блинчики', 'наггетсы', 'заморозка'])) {
      return frozen;
    }
    
    // Крупы и злаки
    if (_containsAny(name, ['рис', 'гречка', 'овсянка', 'пшено', 'перловка', 'манка', 'крупа', 'макароны', 'спагетти', 'лапша'])) {
      return grains;
    }
    
    // Рыба и морепродукты
    if (_containsAny(name, ['рыба', 'лосось', 'семга', 'треска', 'скумбрия', 'креветки', 'крабы', 'мидии', 'кальмары', 'икра'])) {
      return fish;
    }
    
    // Яйца
    if (_containsAny(name, ['яйца', 'яйцо', 'перепелиные яйца'])) {
      return eggs;
    }
    
    // Бытовая химия
    if (_containsAny(name, ['моющее', 'порошок', 'мыло', 'шампунь', 'гель', 'чистящее', 'отбеливатель', 'кондиционер'])) {
      return household;
    }
    
    // Детское питание
    if (_containsAny(name, ['детское', 'пюре', 'каша детская', 'смесь', 'прикорм', 'baby'])) {
      return babyFood;
    }
    
    // Орехи и семечки
    if (_containsAny(name, ['орехи', 'грецкий', 'миндаль', 'фундук', 'кешью', 'арахис', 'семечки', 'кедровые', 'тыквенные'])) {
      return nuts;
    }
    
    // По умолчанию возвращаем иконку еды
    return dairy; // или можно создать общую иконку продуктов
  }
  
  /// Проверяет, содержит ли строка любое из ключевых слов
  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// Получить иконку по типу хранения
  static String getStorageIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fridge':
      case 'холодильник':
        return fridge;
      case 'pantry':
      case 'кладовая':
        return pantry;
      default:
        return fridge;
    }
  }
}