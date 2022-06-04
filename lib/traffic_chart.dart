import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class TrafficChart extends StatelessWidget {
  final List<charts.Series<TimeSeriesTraffic, DateTime>> seriesList;

  const TrafficChart(this.seriesList, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return charts.TimeSeriesChart(
      seriesList,
      dateTimeFactory: const charts.LocalDateTimeFactory(),
      behaviors: [charts.SeriesLegend()],
    );
  }
}

class TimeSeriesTraffic {
  final DateTime time;
  final double tx;
  final double rx;
  final double error;
  TimeSeriesTraffic(this.time, this.tx, this.rx, this.error);
}
