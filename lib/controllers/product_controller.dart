import 'package:get/get.dart';
import 'package:inventory_app/database/db_helper.dart';

class ProductController extends GetxController {
  final RxList<Map<String, dynamic>> products = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _allProducts = <Map<String, dynamic>>[].obs;

  final RxList<Map<String, dynamic>> sales = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> exchangeRates = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> offers = <Map<String, dynamic>>[].obs;
  // قائمة التصنيفات المستخلصة من المنتجات + التي يضيفها المستخدم
  final RxList<String> categories = <String>[].obs;

  // سلة المشتريات: كل عنصر يحتوي productId, name, priceInDollars, quantity
  final RxList<Map<String, dynamic>> cartItems = <Map<String, dynamic>>[].obs;

  final RxDouble currentRate = 0.0.obs;
  final RxInt quantitySold = 0.obs;
  final RxString _searchQuery = ''.obs;

  @override
  void onInit() {
    fetchAllData();
    ever(_searchQuery, (_) => _filterProducts());
    super.onInit();
  }

  Future<void> fetchAllData() async {
    final db = await DatabaseHelper().database;
    _allProducts.value = await db.query('products');
    sales.value = await db.query('sales');
    exchangeRates.value = await db.query('exchange_rates');
    offers.value = await db.query('offers');

    // تحديث التصنيفات بناءً على المنتجات الموجودة
    final set = <String>{};
    for (final p in _allProducts) {
      final cat = (p['category'] ?? 'أخرى').toString();
      if (cat.isNotEmpty) set.add(cat);
    }
    categories.value = set.toList()..sort();

    if (exchangeRates.isNotEmpty) {
      currentRate.value = exchangeRates.last['rate'];
    } else {
      currentRate.value = 0.0;
    }

    _filterProducts();
  }

  Future<void> addProduct(Map<String, dynamic> product) async {
    final db = await DatabaseHelper().database;
    await db.insert('products', product);
    await fetchAllData();
  }

  Future<void> updateProduct(int id, Map<String, dynamic> updatedProduct) async {
    final db = await DatabaseHelper().database;
    await db.update(
      'products',
      updatedProduct,
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchAllData();
  }

  Future<void> deleteProduct(int id) async {
    final db = await DatabaseHelper().database;
    await db.delete('sales', where: 'productId = ?', whereArgs: [id]);
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
    await fetchAllData();
  }

  Future<void> addSale(Map<String, dynamic> sale) async {
    final db = await DatabaseHelper().database;

    final productIndex = _allProducts.indexWhere((p) => p['id'] == sale['productId']);
    if (productIndex != -1) {
      final product = _allProducts[productIndex];
      final newQuantity = (product['quantity'] as int) - (sale['quantitySold'] as int);
      await db.update(
        'products',
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [sale['productId']],
      );
    } else {
      print('خطأ: المنتج بمعرف ${sale['productId']} غير موجود.');
      return;
    }

    await db.insert('sales', sale);
    await fetchAllData();
  }

  Future<void> addExchangeRate(double rate) async {
    final db = await DatabaseHelper().database;
    await db.insert('exchange_rates', {
      'rate': rate,
      'date': DateTime.now().toIso8601String(),
    });
    await fetchAllData();
  }

  Map<String, double> calculateProfitLoss() {
    double maxRate = _getMaxExchangeRate();
    double minRate = _getMinExchangeRate();

    double totalActual = 0.0;
    double totalBestCase = 0.0;
    double totalWorstCase = 0.0;

    for (var sale in sales) {
      totalActual += (sale['totalDollars'] as double) * (sale['exchangeRate'] as double);
      totalBestCase += (sale['totalDollars'] as double) * maxRate;
      totalWorstCase += (sale['totalDollars'] as double) * minRate;
    }

    return {
      'actual': totalActual,
      'best_case': totalBestCase,
      'worst_case': totalWorstCase,
      'best_difference': totalBestCase - totalActual,
      'worst_difference': totalActual - totalWorstCase,
    };
  }

  double _getMaxExchangeRate() {
    return exchangeRates.isNotEmpty
        ? exchangeRates.map((e) => e['rate'] as double).reduce((a, b) => a > b ? a : b)
        : 0.0;
  }

  double _getMinExchangeRate() {
    return exchangeRates.isNotEmpty
        ? exchangeRates.map((e) => e['rate'] as double).reduce((a, b) => a < b ? a : b)
        : 0.0;
  }

  Future<void> addOffer(Map<String, dynamic> offer) async {
    final db = await DatabaseHelper().database;
    await db.insert('offers', offer);
    await fetchAllData();
  }

  Future<void> deleteOffer(int id) async {
    final db = await DatabaseHelper().database;
    await db.delete('offers', where: 'id = ?', whereArgs: [id]);
    await fetchAllData();
  }

  void searchProducts(String query) {
    _searchQuery.value = query;
  }

  void _filterProducts() {
    if (_searchQuery.isEmpty) {
      products.value = List.from(_allProducts);
    } else {
      products.value = _allProducts.where((product) {
        return product['name']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.value.toLowerCase());
      }).toList();
    }
  }

  // --- التصنيفات ---
  void addCategory(String category) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;
    if (!categories.contains(trimmed)) {
      categories.add(trimmed);
      categories.sort();
    }
  }

  // --- السلة ---
  void addToCart(Map<String, dynamic> product, int quantity) {
    if (quantity <= 0) return;
    final productId = product['id'] as int;
    final index = cartItems.indexWhere((item) => item['productId'] == productId);
    if (index != -1) {
      final updated = Map<String, dynamic>.from(cartItems[index]);
      updated['quantity'] = (updated['quantity'] as int) + quantity;
      cartItems[index] = updated;
    } else {
      cartItems.add({
        'productId': productId,
        'name': product['name'],
        'priceInDollars': product['priceInDollars'],
        'quantity': quantity,
      });
    }
  }

  void updateCartQuantity(int productId, int quantity) {
    final index = cartItems.indexWhere((item) => item['productId'] == productId);
    if (index == -1) return;
    if (quantity <= 0) {
      cartItems.removeAt(index);
    } else {
      final updated = Map<String, dynamic>.from(cartItems[index]);
      updated['quantity'] = quantity;
      cartItems[index] = updated;
    }
  }

  void removeFromCart(int productId) {
    cartItems.removeWhere((item) => item['productId'] == productId);
  }

  void clearCart() {
    cartItems.clear();
  }

  Future<String?> checkoutCart() async {
    if (cartItems.isEmpty) return 'السلة فارغة.';

    final db = await DatabaseHelper().database;

    // التحقق من توفر الكميات أولًا
    for (final item in cartItems) {
      final productId = item['productId'] as int;
      final quantity = item['quantity'] as int;
      final productIndex = _allProducts.indexWhere((p) => p['id'] == productId);
      if (productIndex == -1) {
        return 'أحد المنتجات في السلة غير موجود بعد الآن.';
      }
      final product = _allProducts[productIndex];
      if (quantity > (product['quantity'] as int)) {
        return 'الكمية المطلوبة من المنتج "${product['name']}" أكبر من المخزون المتاح.';
      }
    }

    // تنفيذ عمليات البيع وتحديث المخزون
    for (final item in cartItems) {
      final productId = item['productId'] as int;
      final quantity = item['quantity'] as int;

      final productIndex = _allProducts.indexWhere((p) => p['id'] == productId);
      final product = _allProducts[productIndex];

      final newQuantity = (product['quantity'] as int) - quantity;
      await db.update(
        'products',
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [productId],
      );

      await db.insert('sales', {
        'productId': productId,
        'quantitySold': quantity,
        'totalDollars': (product['priceInDollars'] as num) * quantity,
        'exchangeRate': currentRate.value,
        'date': DateTime.now().toIso8601String(),
      });
    }

    clearCart();
    await fetchAllData();
    return null; // null تعني لا يوجد خطأ
  }
}