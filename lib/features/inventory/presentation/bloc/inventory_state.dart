import 'package:equatable/equatable.dart';

class InventoryState extends Equatable {
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> allProducts;
  final List<Map<String, dynamic>> sales;
  final List<Map<String, dynamic>> exchangeRates;
  final List<Map<String, dynamic>> offers;
  final List<String> categories;
  final double currentRate;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const InventoryState({
    this.products = const [],
    this.allProducts = const [],
    this.sales = const [],
    this.exchangeRates = const [],
    this.offers = const [],
    this.categories = const [],
    this.currentRate = 0.0,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  InventoryState copyWith({
    List<Map<String, dynamic>>? products,
    List<Map<String, dynamic>>? allProducts,
    List<Map<String, dynamic>>? sales,
    List<Map<String, dynamic>>? exchangeRates,
    List<Map<String, dynamic>>? offers,
    List<String>? categories,
    double? currentRate,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return InventoryState(
      products: products ?? this.products,
      allProducts: allProducts ?? this.allProducts,
      sales: sales ?? this.sales,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      offers: offers ?? this.offers,
      categories: categories ?? this.categories,
      currentRate: currentRate ?? this.currentRate,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        products,
        allProducts,
        sales,
        exchangeRates,
        offers,
        categories,
        currentRate,
        searchQuery,
        isLoading,
        errorMessage,
      ];
}

