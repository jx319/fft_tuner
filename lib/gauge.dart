import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';
import 'package:gauge_indicator/gauge_indicator.dart';

class Gauge extends StatelessWidget {
  const Gauge({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.tolerance,
  });

  final double value;
  final double min;
  final double max;
  final double tolerance;

  @override
  Widget build(BuildContext context) {
    double centre = (min + max) / 2;
    return SizedBox(
      width: 300,
      height: 200,
      child: AnimatedRadialGauge(
        axis: GaugeAxis(
          min: min,
          max: max,
          zones: [
            GaugeZone(
              from: min,
              to: centre - tolerance,
              color: Colors.orange.harmonizeWith(
                Theme.of(context).colorScheme.secondaryContainer,
              ),
            ),
            GaugeZone(
              from: centre - tolerance,
              to: centre + tolerance,
              color: Colors.green.harmonizeWith(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            GaugeZone(
              from: centre + tolerance,
              to: max,
              color: Colors.red.harmonizeWith(
                Theme.of(context).colorScheme.secondaryContainer,
              ),
            ),
          ],
          progressBar: null,
          pointer: GaugePointer.needle(
            color: Theme.of(context).colorScheme.primary,
            width: 12,
            height: 150,
          ),
        ),
        duration: Duration(milliseconds: 200),
        value: value,
      ),
    );
  }
}
