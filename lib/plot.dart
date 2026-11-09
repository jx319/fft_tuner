import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

class Plot extends StatelessWidget {
  const Plot({super.key, required this.spots, this.unitX = "", this.interval});
  final List<FlSpot> spots;
  final String unitX;
  final double? interval;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.5,
      child: Container(
        decoration: BoxDecoration(),
        clipBehavior: Clip.hardEdge,
        child: LayoutBuilder(
          builder: (context, constraints) => Padding(
            padding: EdgeInsetsGeometry.only(left: 15, right: 15),
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    color: Theme.of(context).colorScheme.primary,
                    belowBarData: BarAreaData(show: false),
                    dotData: const FlDotData(show: false),
                  ),
                ],
                // minX: 0.0,
                // minY: -1.0,
                // maxX: spots.length * 1.0,
                // maxY: 1.0,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval,
                      reservedSize: 25,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    width: 1.5,
                  ),
                ),
                gridData: FlGridData(
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    strokeWidth: 1,
                    dashArray: [10, 5],
                  ),
                  getDrawingVerticalLine: (_) => FlLine(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    strokeWidth: 1,
                    dashArray: [10, 5],
                  ),
                ),

                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots
                        .map(
                          (spot) => LineTooltipItem(
                            "${spot.x.toStringAsPrecision(5)} $unitX",
                            TextStyle(),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
