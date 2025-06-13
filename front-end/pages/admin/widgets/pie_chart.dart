import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SimplePieChartWithLegend extends StatelessWidget {
  final Map<String, double> data;
  final List<Color> colors;
  final TextStyle? valueStyle;

  const SimplePieChartWithLegend({
    Key? key,
    required this.data,
    required this.colors,
    this.valueStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final total = data.values.fold(0.0, (a, b) => a + b);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcula el ancho máximo disponible, si es pequeño, la leyenda ocupará varias líneas
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 130,
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: List.generate(entries.length, (i) {
                    final entry = entries[i];
                    final value = entry.value;
                    final percent = (value / total * 100).toStringAsFixed(0);
                    return PieChartSectionData(
                      color: colors[i % colors.length],
                      value: value,
                      radius: 55,
                      title: '${percent}%',
                      titleStyle: valueStyle ??
                          const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                      titlePositionPercentageOffset: 0.6,
                    );
                  }),
                  sectionsSpace: 5,
                  centerSpaceRadius: 35,
                ),
              ),
            ),
            const SizedBox(width: 18),
            // 👇 Flexible envuelve la leyenda y evita overflow
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(entries.length, (i) {
                  final entry = entries[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Container(
                          width: 22,
                          height: 18,
                          decoration: BoxDecoration(
                            color: colors[i % colors.length],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Este Flexible es CLAVE:
                        Flexible(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontSize: 17),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${entry.value.toInt()})',
                          style: const TextStyle(
                              fontSize: 15, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}
