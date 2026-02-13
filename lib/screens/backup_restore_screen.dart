import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:inventory_app/bloc/inventory_cubit.dart';
import 'package:inventory_app/database/db_helper.dart';
import 'package:inventory_app/screens/home_screen.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isLoading = false;

  Future<String> _getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return p.join(databasesPath, 'inventory.db');
  }

  Future<String> _getAppImagesDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDocDir.path, 'app_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir.path;
  }

  Future<void> _closeDatabase() async {
    await DatabaseHelper().closeDb();
  }

  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbPath = await _getDatabasePath();
      final imagesPath = await _getAppImagesDirectory();

      final tempDir = await getTemporaryDirectory();
      final String tempZipFilePath = p.join(tempDir.path, 'inventory_backup_${DateTime.now().millisecondsSinceEpoch}.zip');

      final encoder = ZipFileEncoder();
      encoder.create(tempZipFilePath);

      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        encoder.addFile(dbFile, 'inventory.db');
      } else {
        debugPrint('Warning: database file not found during export.');
      }

      final imagesDirectory = Directory(imagesPath);
      if (await imagesDirectory.exists()) {
        encoder.addDirectory(imagesDirectory, includeDirName: true);
      } else {
        debugPrint('Warning: images directory not found during export.');
      }

      encoder.close();

      final fileName = p.basename(tempZipFilePath);
      final zipBytes = await File(tempZipFilePath).readAsBytes();

      try {
        await Permission.storage.request();
        
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final targetPath = p.join(downloadDir.path, fileName);
          await File(tempZipFilePath).copy(targetPath);
          
          try {
            await File(tempZipFilePath).delete();
          } catch (_) {}

          Get.snackbar(
            'نجاح',
            'تم حفظ النسخة في: Download/$fileName',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 7),
          );
          return;
        }
      } catch (e) {
        debugPrint('Direct Download save failed: $e');
      }

      try {
        final result = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: zipBytes,
          ext: 'zip',
          mimeType: MimeType.zip,
        );
        
        try {
          await File(tempZipFilePath).delete();
        } catch (_) {}

        Get.snackbar(
          'نجاح',
          'تم حفظ النسخة: $result',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 7),
        );
      } catch (e) {
        debugPrint('FileSaver save failed: $e');
        
        try {
          await File(tempZipFilePath).delete();
        } catch (_) {}
        
        Get.snackbar(
          'خطأ',
          'فشل حفظ النسخة: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 7),
        );
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تصدير البيانات: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      debugPrint('Error exporting data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  
  Future<void> _importData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null && result.files.single.path != null) {
        final String selectedZipPath = result.files.single.path!;
        final dbPath = await _getDatabasePath();
        final imagesPath = await _getAppImagesDirectory();

        await _closeDatabase();

        final currentImagesDir = Directory(imagesPath);
        if (await currentImagesDir.exists()) {
          await currentImagesDir.delete(recursive: true);
        }
        await currentImagesDir.create(recursive: true);

        final bytes = File(selectedZipPath).readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);

        for (final file in archive) {
          final filename = file.name;
          if (filename == 'inventory.db') {
            final output = File(dbPath);
            await output.writeAsBytes(file.content as List<int>);
          } else if (filename.startsWith('app_images/')) {
            final imageOutputPath = p.join(imagesPath, p.relative(filename, from: 'app_images'));
            final output = File(imageOutputPath);
            await output.parent.create(recursive: true);
            await output.writeAsBytes(file.content as List<int>);
          }
        }

        await DatabaseHelper().database;
        if (!mounted) return;
        await context.read<InventoryCubit>().loadAll();

        if (!mounted) return;
        Get.snackbar(
          'نجاح',
          'تم استيراد البيانات بنجاح! سيتم تحديث التطبيق.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );

        if (!mounted) return;
        Get.offAll(() => const Directionality(
              textDirection: TextDirection.rtl,
              child: HomeScreen(),
            ));
      } else {
        Get.snackbar('معلومات', 'لم يتم اختيار ملف.', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل استيراد البيانات: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      debugPrint('Error importing data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي والاستعادة')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _exportData,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('تصدير البيانات (نسخ احتياطي)'),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _importData,
                            icon: const Icon(Icons.download),
                            label: const Text('استيراد البيانات (استعادة)'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ملاحظات هامة:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. تصدير البيانات سيفتح نافذة لحفظ الملف أو سيتم حفظه في مجلد التنزيلات مباشرةً.',
                            textAlign: TextAlign.right,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '2. استيراد البيانات سيقوم بحذف جميع البيانات الحالية في التطبيق واستبدالها ببيانات الملف المستورد.',
                            textAlign: TextAlign.right,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '3. تأكد من نقل ملف "zip" بالكامل (بما في ذلك الصور) إلى الجهاز الآخر يدوياً.',
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      'جاري معالجة البيانات...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}