import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class TimeLineChart extends StatelessWidget {
  final List<charts.Series<TimeLineSeries, DateTime>> seriesList;

  const TimeLineChart(this.seriesList, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return charts.TimeSeriesChart(
      seriesList,
      dateTimeFactory: const charts.LocalDateTimeFactory(),
      behaviors: [charts.SeriesLegend()],
    );
  }
}

class TimeLineSeries {
  final DateTime time;
  final List<double> value;
  TimeLineSeries(this.time, this.value);
}
