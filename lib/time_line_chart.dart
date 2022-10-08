import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class TimeLineChart extends StatelessWidget {
  final List<charts.Series<TimeLineSeries, DateTime>> seriesList;

  const TimeLineChart(this.seriesList, {Key? key}) : super(key: key);

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
      dateTimeFactory: const charts.LocalDateTimeFactory(),
      behaviors: [
        charts.SeriesLegend(
          desiredMaxColumns: 3,
          cellPadding: const EdgeInsets.only(right: 4.0, bottom: 4.0),
          entryTextStyle: const charts.TextStyleSpec(fontSize: 11),
        )
      ],
    );
  }
}

class TimeLineSeries {
  final DateTime time;
  final List<double> value;
  TimeLineSeries(this.time, this.value);
}
