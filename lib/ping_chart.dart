import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class PingChart extends StatelessWidget {
  final List<charts.Series<TimeSeriesPingRTT, DateTime>> seriesList;

  const PingChart(this.seriesList, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return charts.TimeSeriesChart(
      seriesList,
      defaultRenderer: charts.BarRendererConfig<DateTime>(),
      defaultInteractions: false,
      behaviors: [charts.SelectNearest(), charts.DomainHighlighter()],
    );
  }
}

class TimeSeriesPingRTT {
  final DateTime time;
  final double rtt;

  TimeSeriesPingRTT(this.time, this.rtt);
}
