import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventory_app/bloc/inventory_cubit.dart';
import 'package:inventory_app/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AddOfferScreen extends StatefulWidget {
  const AddOfferScreen({super.key});

  @override
  State<AddOfferScreen> createState() => _AddOfferScreenState();
}

class _AddOfferScreenState extends State<AddOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  File? _image;
  final Map<int, int> _selectedProducts = {};

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDocDir.path, 'app_images'));
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
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة عرض جديد')),
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
                      labelText: 'اسم العرض',
                      prefixIcon: Icon(Icons.local_offer),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يجب إدخال اسم العرض';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'وصف العرض',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يجب إدخال وصف العرض';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'السعر بالليرة السورية',
                      prefixIcon: Icon(Icons.monetization_on),
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
                  const SizedBox(height: 16),
                  BlocBuilder<InventoryCubit, InventoryState>(
                      builder: (context, state) {
                    if (state.products.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'المنتجات ضمن العرض',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ...state.products.map((product) {
                          final productId = product['id'] as int;
                          final selected =
                              _selectedProducts.containsKey(productId);
                          final quantity =
                              _selectedProducts[productId] ?? 1;
                          return Card(
                            child: ListTile(
                              leading: Checkbox(
                                value: selected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedProducts[productId] = 1;
                                    } else {
                                      _selectedProducts
                                          .remove(productId);
                                    }
                                  });
                                },
                              ),
                              title: Text(product['name'] ?? ''),
                              subtitle: Text(
                                  'الكمية داخل العرض: $quantity وحدة'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: selected && quantity > 1
                                        ? () {
                                            setState(() {
                                              _selectedProducts[productId] =
                                                  quantity - 1;
                                            });
                                          }
                                        : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: selected
                                        ? () {
                                            setState(() {
                                              _selectedProducts[productId] =
                                                  quantity + 1;
                                            });
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),
                  _image == null
                      ? OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('اختر صورة العرض'),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_image!, height: 180, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final cubit = context.read<InventoryCubit>();
                        final offerId = await cubit.addOffer({
                          'name': _nameController.text,
                          'description': _descriptionController.text,
                          'priceInLira':
                              double.parse(_priceController.text),
                          'imagePath': _image?.path ?? '',
                          'dateAdded': DateTime.now().toIso8601String(),
                        });
                        if (_selectedProducts.isNotEmpty) {
                          await cubit.setOfferItems(
                              offerId, _selectedProducts);
                        }
                        Get.back();
                        Get.snackbar(
                          'نجاح',
                          'تم إضافة العرض بنجاح!',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      }
                    },
                    child: const Text('حفظ العرض'),
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