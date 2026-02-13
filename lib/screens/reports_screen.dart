import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_app/bloc/inventory_cubit.dart';
import 'package:inventory_app/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:inventory_app/services/pdf_report_service.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<InventoryCubit>();
    final profitAnalysis = cubit.calculateProfitLoss();
    final state = cubit.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'تصدير إلى PDF',
            onPressed: () async {
              final pdf = await PdfReportService.generateReport(cubit);
              await Printing.layoutPdf(onLayout: (format) => pdf.save());
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildAnalysisCard('الربح الفعلي', profitAnalysis['actual'] ?? 0.0),
            _buildAnalysisCard('أفضل سيناريو', profitAnalysis['best_case'] ?? 0.0),
            _buildAnalysisCard('الفرق المحتمل', profitAnalysis['best_difference'] ?? 0.0),
            const SizedBox(height: 20),
            _buildExchangeRateChart(state),
            const SizedBox(height: 20),
            _buildSalesChart(state),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(String title, double value) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.analytics_outlined),
        title: Text(title),
        trailing: Text('${value.toStringAsFixed(2)} ل.س'),
      ),
    );
  }

  Widget _buildExchangeRateChart(InventoryState state) {
    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        title: ChartTitle(text: 'تطور سعر الصرف'),
        primaryXAxis: CategoryAxis(
          title: AxisTitle(text: 'التاريخ'),
        ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: 'السعر بالليرة'),
        ),
        series: <LineSeries<Map<String, dynamic>, String>>[
          LineSeries<Map<String, dynamic>, String>(
            dataSource: state.exchangeRates,
            xValueMapper: (rate, _) =>
            DateTime.parse(rate['date']).toString().split(' ')[0],
            yValueMapper: (rate, _) => rate['rate'],
            name: 'سعر الدولار',
          )
        ],
      ),
    );
  }

  Widget _buildSalesChart(InventoryState state) {
    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        title: ChartTitle(text: 'المبيعات حسب المنتج'),
        primaryXAxis: CategoryAxis(
          title: AxisTitle(text: 'المنتج'),
        ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: 'الكمية المباعة'),
        ),
        series: <BarSeries<Map<String, dynamic>, String>>[
          BarSeries<Map<String, dynamic>, String>(
            dataSource: state.sales,
            xValueMapper: (sale, _) {
              final product = state.products.firstWhere(
                    (p) => p['id'] == sale['productId'],
                    orElse: () => {'name': 'غير معروف'},
              );
              return product['name'] ?? 'غير معروف';
            },
            yValueMapper: (sale, _) => sale['quantitySold'],
            name: 'المبيعات',
          )
        ],
      ),
    );
  }
}