import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:inventory_app/bloc/inventory_cubit.dart';
import 'package:inventory_app/features/inventory/presentation/bloc/inventory_state.dart';

class ExchangeRateScreen extends StatelessWidget {
  final TextEditingController _rateController = TextEditingController();

  ExchangeRateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تحديد سعر الصرف')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _rateController,
              decoration: const InputDecoration(
                labelText: 'سعر الدولار بالليرة السورية',
                suffixText: 'ل.س',
                prefixIcon: Icon(Icons.currency_exchange),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_rateController.text.isNotEmpty) {
                  final rate = double.tryParse(_rateController.text);
                  if (rate != null && rate > 0) {
                    context.read<InventoryCubit>().addExchangeRate(rate);
                    Get.back();
                    Get.snackbar('نجاح', 'تم حفظ سعر الصرف بنجاح!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green,
                        colorText: Colors.white);
                  } else {
                    Get.snackbar('خطأ', 'الرجاء إدخال سعر صرف صحيح وموجب.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white);
                  }
                } else {
                  Get.snackbar('خطأ', 'الرجاء إدخال سعر الصرف.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white);
                }
              },
              child: const Text('حفظ السعر'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<InventoryCubit, InventoryState>(
                  builder: (context, state) {
                return ListView.builder(
                  itemCount: state.exchangeRates.length,
                  itemBuilder: (context, index) {
                    final reversedIndex =
                        state.exchangeRates.length - 1 - index;
                    final rate = state.exchangeRates[reversedIndex];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.trending_up),
                        title:
                            Text('${rate['rate'].toStringAsFixed(2)} ل.س'),
                        subtitle: Text(
                            DateTime.parse(rate['date']).toString().split(' ')[0]),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}