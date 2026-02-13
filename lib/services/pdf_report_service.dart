import 'package:flutter/services.dart';
import 'package:inventory_app/bloc/inventory_cubit.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfReportService {
  static Future<pw.Document> generateReport(InventoryCubit cubit) async {
    final pdf = pw.Document();
    final arabicFont = pw.Font.ttf(await rootBundle.load(
        "assets/fonts/Noto_Sans_Arabic/static/NotoSansArabic-Regular.ttf"));

    final profitAnalysis = cubit.calculateProfitLoss();
    final state = cubit.state;

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: arabicFont),
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Header(level: 0, text: 'تقرير المبيعات والربح'),
            pw.Divider(),
            pw.TableHelper.fromTextArray(
              headers: ['المنتج', 'الكمية', 'القيمة بالدولار', 'القيمة بالليرة'],
              data: state.sales.map((sale) {
                final product = state.allProducts.firstWhere(
                  (p) => p['id'] == sale['productId'],
                  orElse: () => {'name': 'غير معروف'},
                );
                final totalDollars =
                    (sale['totalDollars'] as num?)?.toDouble() ?? 0.0;
                final totalLira =
                    totalDollars * (sale['exchangeRate'] as num? ?? 1).toDouble();
                return [
                  product['name'] ?? 'غير معروف',
                  sale['quantitySold']?.toString() ?? '0',
                  '${totalDollars.toStringAsFixed(2)} \$',
                  '${totalLira.toStringAsFixed(2)} ل.س',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Header(text: 'تحليل الربح والخسارة', level: 1),
      pw.Text(
        'إجمالي الربح الفعلي: ${profitAnalysis['actual']?.toStringAsFixed(2) ?? 'غير متوفر'} ليرة'),
      pw.Text(
        'أفضل سيناريو ربح: ${profitAnalysis['best_case']?.toStringAsFixed(2) ?? 'غير متوفر'} ليرة'),
      pw.Text(
        'الفرق المحتمل: ${profitAnalysis['best_difference']?.toStringAsFixed(2) ?? 'غير متوفر'} ليرة'),
          ];
        },
      ),
    );

    return pdf;
  }
}