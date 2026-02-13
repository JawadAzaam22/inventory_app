import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:inventory_app/bloc/inventory_cubit.dart';
import 'package:inventory_app/main.dart';
import 'package:inventory_app/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:inventory_app/screens/add_offer_screen.dart';
import 'package:inventory_app/screens/add_product_screen.dart';
import 'package:inventory_app/screens/backup_restore_screen.dart';
import 'package:inventory_app/screens/edit_product_screen.dart';
import 'package:inventory_app/screens/exchange_rate_screen.dart';
import 'package:inventory_app/screens/reports_screen.dart';
import 'package:inventory_app/screens/sales_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  int _selectedIndex = 0;
  String _selectedCategory = 'الكل';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: BlocBuilder<InventoryCubit, InventoryState>(builder: (context, state) {
        return Column(
          children: [
            if (state.isLoading)
              const LinearProgressIndicator(),
            if (state.errorMessage != null)
              Container(
                color: Colors.red[700],
                padding: const EdgeInsets.all(8),
                width: double.infinity,
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('منتجات: ${state.products.length}'),
                  Text('عروض: ${state.offers.length}'),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Offstage(
                    offstage: _selectedIndex != 0,
                    child: TickerMode(
                      enabled: _selectedIndex == 0,
                      child: _buildProductsPage(),
                    ),
                  ),
                  Offstage(
                    offstage: _selectedIndex != 1,
                    child: TickerMode(
                      enabled: _selectedIndex == 1,
                      child: _buildOffersPage(),
                    ),
                  ),
                  Offstage(
                    offstage: _selectedIndex != 2,
                    child: TickerMode(
                      enabled: _selectedIndex == 2,
                      child: _buildSettingsPage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
      floatingActionButton: _selectedIndex == 0
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'addProduct',
                  child: const Icon(Icons.add_box),
                  onPressed: () => Get.to(() => const AddProductScreen()),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'addOffer',
                  child: const Icon(Icons.local_offer),
                  onPressed: () => Get.to(() => const AddOfferScreen()),
                ),
              ],
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'المنتجات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'العروض',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    switch (_selectedIndex) {
      case 0:
        return AppBar(
          title: const Text('إدارة المخزون'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(120),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'ابحث عن منتج...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      context.read<InventoryCubit>().searchProducts(value);
                    },
                  ),
                ),
                _buildCategoryChips(),
              ],
            ),
          ),
        );
      case 1:
        return AppBar(
          title: const Text('العروض'),
        );
      case 2:
        return AppBar(
          title: const Text('الإعدادات'),
        );
      default:
        return AppBar(
          title: const Text('إدارة المخزون'),
        );
    }
  }

  Widget _buildCategoryChips() {
    return BlocBuilder<InventoryCubit, InventoryState>(
        builder: (context, state) {
      final cats = <String>['الكل', ...state.categories];
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            for (final cat in cats)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: _selectedCategory == cat,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ActionChip(
                avatar: const Icon(Icons.add),
                label: const Text('إضافة تصنيف'),
                onPressed: () {
                  final TextEditingController catController =
                      TextEditingController();
                  Get.defaultDialog(
                    title: 'إضافة تصنيف جديد',
                    content: Column(
                      children: [
                        TextField(
                          controller: catController,
                          decoration:
                              const InputDecoration(labelText: 'اسم التصنيف'),
                        ),
                      ],
                    ),
                    textConfirm: 'حفظ',
                    textCancel: 'إلغاء',
                    confirmTextColor: Colors.white,
                    onConfirm: () {
                      final name = catController.text.trim();
                      if (name.isNotEmpty) {
                        context.read<InventoryCubit>().addCategory(name);
                        setState(() {
                          _selectedCategory = name;
                        });
                      }
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProductsPage() {
    return BlocBuilder<InventoryCubit, InventoryState>(
        builder: (context, state) {
      final all = state.products;
      final filtered = all.where((product) {
        if (_selectedCategory == 'الكل') return true;
        final cat = (product['category'] ?? '').toString();
        return cat == _selectedCategory;
      }).toList();

      if (filtered.isEmpty && _searchController.text.isEmpty) {
        return const Center(
            child: Text('لا توجد منتجات حالياً. أضف منتجاً جديداً.'));
      }
      if (filtered.isEmpty && _searchController.text.isNotEmpty) {
        return const Center(child: Text('لا توجد منتجات مطابقة للبحث.'));
      }

      return GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.5,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final product = filtered[index];
          return _buildProductCard(product);
        },
      );
    });
  }

  Widget _buildOffersPage() {
    return BlocBuilder<InventoryCubit, InventoryState>(
        builder: (context, state) {
      if (state.offers.isEmpty) {
        return const Center(
            child: Text('لا توجد عروض حالياً. أضف عرضاً جديداً.'));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: state.offers.length,
        itemBuilder: (context, index) {
          final offer = state.offers[index];
          return _buildOfferCard(offer);
        },
      );
    });
  }

  Widget _buildSettingsPage() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('المظهر والثيم'),
            subtitle: const Text('اضغط لاختيار الثيم (نظام/فاتح/داكن)'),
            onTap: () {
              Get.defaultDialog(
                title: 'اختر المظهر',
                content: Column(
                  children: [
                    ListTile(
                      title: const Text('يتبع النظام'),
                      onTap: () {
                        MyApp.of(context)?.setThemeMode(ThemeMode.system);
                        Get.back();
                      },
                    ),
                    ListTile(
                      title: const Text('فاتح'),
                      onTap: () {
                        MyApp.of(context)?.setThemeMode(ThemeMode.light);
                        Get.back();
                      },
                    ),
                    ListTile(
                      title: const Text('داكن'),
                      onTap: () {
                        MyApp.of(context)?.setThemeMode(ThemeMode.dark);
                        Get.back();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.insert_chart_outlined),
            title: const Text('التقارير'),
            onTap: () => Get.to(() => const ReportsScreen()),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('تحديد سعر الصرف'),
            onTap: () => Get.to(() => ExchangeRateScreen()),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('النسخ الاحتياطي والاستعادة'),
            onTap: () => Get.to(() => const BackupRestoreScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: product['imagePath'] != null &&
                    product['imagePath'].isNotEmpty
                ? Image.file(
                    File(product['imagePath']),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported, size: 50),
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Icon(Icons.image, size: 50),
                  ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'],
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                        'السعر: \$${product['priceInDollars'].toStringAsFixed(2)}'),
                    Text('المخزون: ${product['quantity']} وحدة'),
                    Text('التصنيف: ${product['category'] ?? 'غير محدد'}'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () =>
                      Get.to(() => EditProductScreen(product: product)),
                ),
                IconButton(
                  icon: const Icon(Icons.shopify, color: Colors.red),
                  onPressed: () => Get.to(SalesScreen(product: product)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => _deleteProduct(product['id']),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildOfferCard(Map<String, dynamic> offer) {
    final String name = (offer['name'] ?? 'بدون اسم').toString();
    final String description = (offer['description'] ?? 'لا يوجد وصف').toString();
    final double price = (offer['priceInLira'] is num)
        ? (offer['priceInLira'] as num).toDouble()
        : double.tryParse(offer['priceInLira']?.toString() ?? '') ?? 0.0;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          offer['imagePath'] != null && offer['imagePath'].toString().isNotEmpty
              ? SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.file(
                    File(offer['imagePath']),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported, size: 80),
                    ),
                  ),
                )
              : Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: const Icon(Icons.image, size: 80),
                ),
          
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'السعر: ${price.toStringAsFixed(2)} ل.س',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700]),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteOffer(offer['id']),
                    tooltip: 'حذف العرض',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  

  void _deleteProduct(int productId) {
    Get.defaultDialog(
      title: "حذف المنتج",
      middleText:
          "هل أنت متأكد من حذف هذا المنتج؟ سيتم حذف جميع المبيعات المرتبطة به.",
      textConfirm: "نعم",
      textCancel: "إلغاء",
      confirmTextColor: Colors.white,
      onConfirm: () {
        context.read<InventoryCubit>().deleteProduct(productId);
        Get.back();
        Get.snackbar(
          'نجاح',
          'تم حذف المنتج بنجاح!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    );
  }

  void _deleteOffer(int offerId) {
    Get.defaultDialog(
      title: "حذف العرض",
      middleText: "هل أنت متأكد من حذف هذا العرض؟",
      textConfirm: "نعم",
      textCancel: "إلغاء",
      confirmTextColor: Colors.white,
      onConfirm: () {
        context.read<InventoryCubit>().deleteOffer(offerId);
        Get.back();
        Get.snackbar(
          'نجاح',
          'تم حذف العرض بنجاح!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    );
  }
}