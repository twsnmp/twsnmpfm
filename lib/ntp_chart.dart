import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class NTPChart extends StatelessWidget {
  final List<charts.Series<TimeSeriesNTPOffset, DateTime>> seriesList;

  const NTPChart(this.seriesList, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool dark = Theme.of(context).brightness == Brightness.dark;
    var axisY = charts.NumericAxisSpec(
        renderSpec: charts.GridlineRendererSpec(
            labelStyle: charts.TextStyleSpec(fontSize: 10, color: dark ? charts.MaterialPalette.white : charts.MaterialPalette.black),
            lineStyle: charts.LineStyleSpec(thickness: 0, color: dark ? charts.MaterialPalette.white : charts.MaterialPalette.black)));
    var axisX = charts.DateTimeAxisSpec(
        renderSpec: charts.GridlineRendererSpec(
            labelStyle: charts.TextStyleSpec(fontSize: 10, color: dark ? charts.MaterialPalette.white : charts.MaterialPalette.black),
            lineStyle: charts.LineStyleSpec(thickness: 0, color: dark ? charts.MaterialPalette.white : charts.MaterialPalette.black)));
    return charts.TimeSeriesChart(
      primaryMeasureAxis: axisY,
      domainAxis: axisX,
      seriesList,
      defaultRenderer: charts.BarRendererConfig<DateTime>(),
      defaultInteractions: false,
      behaviors: [charts.SelectNearest(), charts.DomainHighlighter()],
    );
  }
}

class TimeSeriesNTPOffset {
  final DateTime time;
  final double diff;

  TimeSeriesNTPOffset(this.time, this.diff);
}
