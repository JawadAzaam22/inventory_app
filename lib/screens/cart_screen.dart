import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:inventory_app/bloc/inventory_cubit.dart';

class CartScreen extends StatelessWidget {
  CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سلة المشتريات'),
      ),
      body: BlocBuilder<InventoryCubit, InventoryState>(
          builder: (context, state) {
        if (state.cartItems.isEmpty) {
          return const Center(child: Text('السلة فارغة حالياً.'));
        }

        double totalDollars = 0;
        for (final item in state.cartItems) {
          totalDollars +=
              (item['priceInDollars'] as num) * (item['quantity'] as int);
        }
        final totalLira = totalDollars * state.currentRate;

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: state.cartItems.length,
                itemBuilder: (context, index) {
                  final item = state.cartItems[index];
                  final price = item['priceInDollars'] as num;
                  final quantity = item['quantity'] as int;
                  final total = price * quantity;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.shopping_bag),
                      title: Text(item['name']),
                      subtitle: Text(
                          'السعر: \$${price.toStringAsFixed(2)} • الكمية: $quantity'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('\$${total.toStringAsFixed(2)}'),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  context
                                      .read<InventoryCubit>()
                                      .updateCartQuantity(
                                          item['productId'], quantity - 1);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  context
                                      .read<InventoryCubit>()
                                      .updateCartQuantity(
                                          item['productId'], quantity + 1);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      onLongPress: () => context
                          .read<InventoryCubit>()
                          .removeFromCart(item['productId']),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'الإجمالي بالدولار: \$${totalDollars.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الإجمالي بالليرة: ${totalLira.toStringAsFixed(2)} ل.س',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final error =
                          await context.read<InventoryCubit>().checkoutCart();
                      if (error != null) {
                        Get.snackbar(
                          'خطأ',
                          error,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      } else {
                        Get.back();
                        Get.snackbar(
                          'نجاح',
                          'تم تسجيل عملية البيع لكل منتجات السلة بنجاح.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      }
                    },
                    child: const Text('تأكيد البيع لكل السلة'),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

