import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:inventory_app/bloc/inventory_cubit.dart';

class SalesScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const SalesScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController _quantityController = TextEditingController();
  int _quantity = 0;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<InventoryCubit>();
    final rate = cubit.state.currentRate;

    final totalDollars =
        (_quantity * (widget.product['priceInDollars'] as num)).toDouble();
    final totalLira = (totalDollars * rate).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text('بيع ${widget.product['name']}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.currency_exchange),
                title: const Text('سعر الصرف الحالي'),
                subtitle: Text('${rate.toStringAsFixed(2)} ل.س/دولار'),
              ),
            ),

            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildProductInfo('السعر بالدولار',
                        '\$${widget.product['priceInDollars'].toStringAsFixed(2)}'),
                    _buildProductInfo(
                        'المخزون', '${widget.product['quantity']} وحدة'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الكمية المباعة',
                prefixIcon: Icon(Icons.shopping_cart_checkout),
              ),
              onChanged: (value) {
                setState(() {
                  _quantity = int.tryParse(value) ?? 0;
                });
              },
            ),

            const SizedBox(height: 16),
            Column(
              children: [
                _buildAmountCard('الإجمالي بالدولار', totalDollars),
                _buildAmountCard('الإجمالي بالليرة', totalLira),
              ],
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _saveSale(context.read<InventoryCubit>()),
              child: const Text('تأكيد البيع'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAmountCard(String title, double amount) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(NumberFormat.currency(
          symbol: title.contains('ليرة') ? 'ل.س ' : '\$',
          decimalDigits: 2,
        ).format(amount)),
      ),
    );
  }

  Future<void> _saveSale(InventoryCubit cubit) async {
    if (_quantityController.text.isEmpty) {
      Get.snackbar(
        'خطأ',
        'يرجى إدخال الكمية المباعة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      Get.snackbar(
        'خطأ',
        'يرجى إدخال كمية صحيحة وموجبة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }


    if (quantity > widget.product['quantity']) {
      Get.snackbar(
        'خطأ',
        'الكمية المدخلة أكبر من المخزون المتاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final error = await cubit.addSale({
      'productId': widget.product['id'],
      'quantitySold': quantity,
      'totalDollars': widget.product['priceInDollars'] * quantity,
      'exchangeRate': cubit.state.currentRate,
      'date': DateTime.now().toIso8601String(),
    });

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
        'تم تسجيل عملية البيع بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }
}