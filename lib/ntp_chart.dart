import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class NTPChart extends StatelessWidget {
  final List<charts.Series<TimeSeriesNTPOffset, DateTime>> seriesList;

  const NTPChart(this.seriesList, {Key? key}) : super(key: key);

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

class TimeSeriesNTPOffset {
  final DateTime time;
  final double diff;

  TimeSeriesNTPOffset(this.time, this.diff);
}
