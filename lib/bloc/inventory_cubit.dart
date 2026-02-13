import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:inventory_app/database/db_helper.dart';
import 'package:inventory_app/features/inventory/presentation/bloc/inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final DatabaseHelper _dbHelper;

  InventoryCubit(this._dbHelper) : super(const InventoryState());

  Future<void> loadAll() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final db = await _dbHelper.database;
      final allProducts = await db.query('products');
      final sales = await db.query('sales');
      final exchangeRates = await db.query('exchange_rates');
      final offers = await db.query('offers');

  debugPrint('loadAll: products=${allProducts.length}, sales=${sales.length}, exchangeRates=${exchangeRates.length}, offers=${offers.length}');

      double currentRate = 0.0;
      if (exchangeRates.isNotEmpty) {
        final lastRate = exchangeRates.last['rate'];
        if (lastRate is num) {
          currentRate = lastRate.toDouble();
        } else {
          currentRate = double.tryParse(lastRate?.toString() ?? '') ?? 0.0;
        }
      }

      final categoriesSet = <String>{};
      for (final p in allProducts) {
        final cat = (p['category'] ?? 'أخرى').toString();
        if (cat.isNotEmpty) categoriesSet.add(cat);
      }

      final filteredProducts = _filterProductsInternal(
        allProducts,
        state.searchQuery,
      );

      emit(state.copyWith(
        allProducts: allProducts,
        products: filteredProducts,
        sales: sales,
        exchangeRates: exchangeRates,
        offers: offers,
  cartItems: state.cartItems,
        categories: categoriesSet.toList()..sort(),
        currentRate: currentRate,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'فشل تحميل البيانات: $e',
      ));
    }
  }

  
  Future<void> addProduct(Map<String, dynamic> product) async {
    final db = await _dbHelper.database;
    await db.insert('products', product);
    await loadAll();
  }

  Future<void> updateProduct(int id, Map<String, dynamic> updatedProduct) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      updatedProduct,
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadAll();
  }

  Future<void> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    await db.delete('sales', where: 'productId = ?', whereArgs: [id]);
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
    await loadAll();
  }

  
  Future<String?> addSale(Map<String, dynamic> sale) async {
    final db = await _dbHelper.database;
    final allProducts = state.allProducts;
    final productIndex =
        allProducts.indexWhere((p) => p['id'] == sale['productId']);
    if (productIndex == -1) {
      return 'المنتج غير موجود.';
    }
    final product = allProducts[productIndex];
    final newQuantity =
        (product['quantity'] as int) - (sale['quantitySold'] as int);
    if (newQuantity < 0) {
      return 'الكمية المدخلة أكبر من المخزون المتاح.';
    }

    await db.update(
      'products',
      {'quantity': newQuantity},
      where: 'id = ?',
      whereArgs: [sale['productId']],
    );

    await db.insert('sales', sale);
    await loadAll();
    return null;
  }

  
  Future<void> addExchangeRate(double rate) async {
    final db = await _dbHelper.database;
    await db.insert('exchange_rates', {
      'rate': rate,
      'date': DateTime.now().toIso8601String(),
    });
    await loadAll();
  }

  Map<String, double> calculateProfitLoss() {
    double maxRate = _getMaxExchangeRate();
    double minRate = _getMinExchangeRate();

    double totalActual = 0.0;
    double totalBestCase = 0.0;
    double totalWorstCase = 0.0;

  for (var sale in state.sales) {
    final totalDollars = (sale['totalDollars'] is num)
      ? (sale['totalDollars'] as num).toDouble()
      : double.tryParse(sale['totalDollars']?.toString() ?? '') ?? 0.0;
    final exchangeRate = (sale['exchangeRate'] is num)
      ? (sale['exchangeRate'] as num).toDouble()
      : double.tryParse(sale['exchangeRate']?.toString() ?? '') ?? 0.0;

    totalActual += totalDollars * exchangeRate;
    totalBestCase += totalDollars * maxRate;
    totalWorstCase += totalDollars * minRate;
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
    return state.exchangeRates.isNotEmpty
        ? state.exchangeRates
            .map((e) {
              final r = e['rate'];
              if (r is num) return r.toDouble();
              return double.tryParse(r?.toString() ?? '') ?? 0.0;
            })
            .reduce((a, b) => a > b ? a : b)
        : 0.0;
  }

  double _getMinExchangeRate() {
    return state.exchangeRates.isNotEmpty
        ? state.exchangeRates
            .map((e) {
              final r = e['rate'];
              if (r is num) return r.toDouble();
              return double.tryParse(r?.toString() ?? '') ?? 0.0;
            })
            .reduce((a, b) => a < b ? a : b)
        : 0.0;
  }

  
  Future<int> addOffer(Map<String, dynamic> offer) async {
    final db = await _dbHelper.database;
    final id = await db.insert('offers', offer);
    await loadAll();
  debugPrint('Offer added with id: $id');
    return id;
  }

  Future<void> deleteOffer(int id) async {
    final db = await _dbHelper.database;
    await db.delete('offers', where: 'id = ?', whereArgs: [id]);
    await loadAll();
  }

  Future<void> setOfferItems(
      int offerId, Map<int, int> productQuantities) async {
    final db = await _dbHelper.database;
    await db
        .delete('offer_items', where: 'offerId = ?', whereArgs: [offerId]);
    for (final entry in productQuantities.entries) {
      await db.insert('offer_items', {
        'offerId': offerId,
        'productId': entry.key,
        'quantityPerOffer': entry.value,
      });
    }
  await loadAll();
  }

  
  void addToCart(Map<String, dynamic> product, int quantity) {
    if (quantity <= 0) return;
    final productId = product['id'] as int;
    final all = List<Map<String, dynamic>>.from(state.cartItems);
    final index = all.indexWhere((item) => item['productId'] == productId);
    if (index != -1) {
      final updated = Map<String, dynamic>.from(all[index]);
      updated['quantity'] = (updated['quantity'] as int) + quantity;
      all[index] = updated;
    } else {
      all.add({
        'productId': productId,
        'name': product['name'],
        'priceInDollars': product['priceInDollars'],
        'quantity': quantity,
      });
    }
    emit(state.copyWith(cartItems: all));
  }

  void updateCartQuantity(int productId, int quantity) {
    final all = List<Map<String, dynamic>>.from(state.cartItems);
    final index = all.indexWhere((item) => item['productId'] == productId);
    if (index == -1) return;
    if (quantity <= 0) {
      all.removeAt(index);
    } else {
      final updated = Map<String, dynamic>.from(all[index]);
      updated['quantity'] = quantity;
      all[index] = updated;
    }
    emit(state.copyWith(cartItems: all));
  }

  void removeFromCart(int productId) {
    final all = List<Map<String, dynamic>>.from(state.cartItems);
    all.removeWhere((item) => item['productId'] == productId);
    emit(state.copyWith(cartItems: all));
  }

  void clearCart() {
    emit(state.copyWith(cartItems: []));
  }

  Future<String?> checkoutCart() async {
    if (state.cartItems.isEmpty) return 'السلة فارغة.';
    try {
      final db = await _dbHelper.database;
    
      for (final item in state.cartItems) {
        final productId = item['productId'] as int;
        final quantity = item['quantity'] as int;
        final productIndex = state.allProducts.indexWhere((p) => p['id'] == productId);
        if (productIndex == -1) return 'أحد المنتجات في السلة غير موجود بعد الآن.';
        final product = state.allProducts[productIndex];
        if (quantity > (product['quantity'] as int)) {
          return 'الكمية المطلوبة من المنتج "${product['name']}" أكبر من المخزون المتاح.';
        }
      }

      for (final item in state.cartItems) {
        final productId = item['productId'] as int;
        final quantity = item['quantity'] as int;
        final productIndex = state.allProducts.indexWhere((p) => p['id'] == productId);
        final product = state.allProducts[productIndex];
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
          'exchangeRate': state.currentRate,
          'date': DateTime.now().toIso8601String(),
        });
      }

      clearCart();
      await loadAll();
      return null;
    } catch (e) {
      return 'فشل أثناء إتمام عملية البيع: $e';
    }
  }

  Future<String?> sellOffer(
      int offerId, int offerQuantity, String? note) async {
    if (offerQuantity <= 0) {
      return 'الرجاء إدخال كمية صحيحة للعرض.';
    }

    final db = await _dbHelper.database;
    final allProducts = state.allProducts;

    final items = await db
        .query('offer_items', where: 'offerId = ?', whereArgs: [offerId]);
    if (items.isEmpty) {
      return 'لم يتم ربط أي منتجات بهذا العرض.';
    }

    
    for (final item in items) {
      final productId = item['productId'] as int;
      final perOffer = item['quantityPerOffer'] as int;
      final totalQuantity = perOffer * offerQuantity;

      final productIndex =
          allProducts.indexWhere((p) => p['id'] == productId);
      if (productIndex == -1) {
        return 'أحد المنتجات المرتبطة بالعرض غير موجود بعد الآن.';
      }
      final product = allProducts[productIndex];
      if (totalQuantity > (product['quantity'] as int)) {
        return 'الكمية المطلوبة من المنتج "${product['name']}" أكبر من المخزون المتاح.';
      }
    }

    
    for (final item in items) {
      final productId = item['productId'] as int;
      final perOffer = item['quantityPerOffer'] as int;
      final totalQuantity = perOffer * offerQuantity;

      final productIndex =
          allProducts.indexWhere((p) => p['id'] == productId);
      final product = allProducts[productIndex];

      final newQuantity = (product['quantity'] as int) - totalQuantity;
      await db.update(
        'products',
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [productId],
      );

      await db.insert('sales', {
        'productId': productId,
        'quantitySold': totalQuantity,
        'totalDollars':
            (product['priceInDollars'] as num) * totalQuantity,
        'exchangeRate': state.currentRate,
        'date': DateTime.now().toIso8601String(),
        'note': note,
      });
    }

    await loadAll();
    return null;
  }

  
  void searchProducts(String query) {
    final filtered = _filterProductsInternal(state.allProducts, query);
    emit(state.copyWith(products: filtered, searchQuery: query));
  }

  List<Map<String, dynamic>> _filterProductsInternal(
    List<Map<String, dynamic>> all,
    String query,
  ) {
    if (query.isEmpty) {
      return List<Map<String, dynamic>>.from(all);
    }
    return all.where((product) {
      return product['name']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase());
    }).toList();
  }

  
  void addCategory(String category) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;
    if (!state.categories.contains(trimmed)) {
      final updated = [...state.categories, trimmed]..sort();
      emit(state.copyWith(categories: updated));
    }
  }
}