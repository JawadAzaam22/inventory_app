import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventory_app/bloc/inventory_cubit.dart';
import 'package:path_provider/path_provider.dart'; // لاستخدام getApplicationDocumentsDirectory
import 'package:path/path.dart' as p; // لاستخدام path.join و path.extension

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  File? _image;
  String? _selectedCategory;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDocDir.path, 'app_images')); // مجلد الصور
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
      final String newPath = p.join(imagesDir.path, fileName);

      final File newImage = await File(pickedFile.path).copy(newPath);

      setState(() {
        _image = newImage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = context.watch<InventoryCubit>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منتج جديد')),
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
                    controller: _nameController,
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
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'السعر بالدولار',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
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
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'الكمية',
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    keyboardType: TextInputType.number,
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
                  _image == null
                      ? OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('اختر صورة المنتج'),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_image!, height: 180, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        context.read<InventoryCubit>().addProduct({
                          'name': _nameController.text,
                          'priceInDollars': double.parse(_priceController.text),
                          'quantity': int.parse(_quantityController.text),
                          'imagePath': _image?.path ?? '',
                          'category': _selectedCategory ?? 'أخرى',
                        });
                        Get.back();
                        Get.snackbar('نجاح', 'تم إضافة المنتج بنجاح!',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green,
                            colorText: Colors.white);
                      }
                    },
                    child: const Text('حفظ المنتج'),
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