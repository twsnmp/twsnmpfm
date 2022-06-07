import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class HorizontalBarLabelChart extends StatelessWidget {
  final List<charts.Series<BarData, String>> seriesList;

  const HorizontalBarLabelChart(this.seriesList, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return charts.BarChart(
      seriesList,
      vertical: false,
      barRendererDecorator: charts.BarLabelDecorator<String>(),
      domainAxis: const charts.OrdinalAxisSpec(renderSpec: charts.NoneRenderSpec()),
    );
  }
}

class BarData {
  final String name;
  final double value;

  BarData(this.name, this.value);
}
