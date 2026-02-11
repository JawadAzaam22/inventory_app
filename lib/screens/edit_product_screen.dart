import 'dart:io'; // لاستخدام File

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:inventory_app/bloc/inventory_cubit.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final InventoryCubit productController = Get.find<InventoryCubit>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  String? _selectedCategory;
  String? _currentImagePath; // لتخزين مسار الصورة الحالي

  @override
  void initState() {
    super.initState();
    nameController.text = widget.product['name'];
    priceController.text = widget.product['priceInDollars'].toString();
    quantityController.text = widget.product['quantity'].toString();
    _selectedCategory = widget.product['category'];
    _currentImagePath = widget.product['imagePath']; // تحميل مسار الصورة الحالي
  }

  Future<void> updateProduct() async {
    if (_formKey.currentState!.validate()) {
      final updatedProduct = {
        'name': nameController.text,
        'priceInDollars': double.tryParse(priceController.text) ?? 0.0,
        'quantity': int.tryParse(quantityController.text) ?? 0,
        'category': _selectedCategory ?? 'أخرى',
        'imagePath': _currentImagePath, // الحفاظ على مسار الصورة الحالي
      };

      await productController.updateProduct(widget.product['id'], updatedProduct);
      Get.back();
      Get.snackbar('نجاح', 'تم تحديث المنتج بنجاح!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    }
  }

  Future<void> deleteProduct() async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا المنتج؟ سيتم حذف جميع المبيعات المرتبطة به.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    ) ?? false;

    if (confirmDelete) {
      await productController.deleteProduct(widget.product['id']);
      Get.back();
      Get.snackbar('نجاح', 'تم حذف المنتج بنجاح!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    }
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final inventoryState = context.watch<InventoryCubit>().state;
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل المنتج'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Theme.of(context).colorScheme.error,
            onPressed: deleteProduct,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المنتج',
                      prefixIcon: Icon(Icons.label),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يجب إدخال الاسم';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'السعر بالدولار',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يجب إدخال السعر';
                      }
                      if (double.tryParse(value) == null) {
                        return 'الرجاء إدخال رقم صحيح للسعر';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'الكمية',
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يجب إدخال الكمية';
                      }
                      if (int.tryParse(value) == null) {
                        return 'الرجاء إدخال رقم صحيح للكمية';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'التصنيف',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: (inventoryState.categories.isEmpty
                            ? ['كهربائيات', 'قزاز', 'أخرى']
                            : inventoryState.categories)
                        .map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء اختيار تصنيف';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _currentImagePath != null &&
                      _currentImagePath!.isNotEmpty &&
                      File(_currentImagePath!).existsSync()
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_currentImagePath!),
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  )
                      : const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('لا توجد صورة للمنتج'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: updateProduct,
                    child: const Text('تحديث المنتج'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}