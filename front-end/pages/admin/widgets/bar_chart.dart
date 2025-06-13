import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SimpleBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final double barWidth;
  final double height;

  const SimpleBarChart({
    Key? key,
    required this.data,
    this.barWidth = 38,
    this.height = 320,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("No hay datos"));
    }
    return SizedBox(
      height: height,
      child: Padding(
        // Este padding deja hueco para las etiquetas debajo de la barra
        padding: const EdgeInsets.only(bottom: 32, left: 16, right: 16, top: 16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (data.map((d) => (d['cantidad'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b) + 1).toDouble(),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 28),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44, // Espacio para el texto de la etiqueta
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final int index = value.toInt();
                    if (index < 0 || index >= data.length) return Container();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        data[index]['estado'].toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (int i = 0; i < data.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: (data[i]['cantidad'] as num?)?.toDouble() ?? 0,
                      width: barWidth,
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.green,
                    ),
                  ],
                  showingTooltipIndicators: [0],
                ),
            ],
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }
}
