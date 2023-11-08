import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:statistics/statistics.dart';

class TimeLineChart extends StatelessWidget {
  final List<LineChartBarData> seriesList;

  const TimeLineChart(this.seriesList, {super.key});

  @override
  Widget build(BuildContext context) {
    double minX = DateTime.now().millisecondsSinceEpoch.toDouble();
    double maxX = 0;
    double maxY = 0;
    double minY = 0;
    if (seriesList.isNotEmpty && seriesList[0].spots.isNotEmpty) {
      for (var spot in seriesList[0].spots) {
        if (spot.x < minX) {
          minX = spot.x;
        }
        if (spot.x > maxX) {
          maxX = spot.x;
        }
      }
      for (var s in seriesList) {
        for (var spot in s.spots) {
          if (spot.y > maxY) {
            maxY = spot.y;
          }
          if (spot.y < minY) {
            minY = spot.y;
          }
        }
      }
    } else {
      return Container();
    }
    if (maxX <= minX) {
      maxX = minX + 1000;
    }
    if (maxY <= 1) {
      maxY = 1;
    } else if (maxY < 10) {
      maxY = 10.0;
    } else if (maxY < 100) {
      double i;
      for (i = 10; i < maxY; i += 10) {}
      maxY = i;
    } else if (maxY < 1000) {
      double i;
      for (i = 100; i < maxY; i += 100) {}
      maxY = i;
    } else {
      double i;
      for (i = 1000; i < maxY; i += 1000) {}
      maxY = i;
    }
    if (minY < 0) {
      minY = (minY.toInt() - 1).toDouble();
    } else {
      minY = 0;
    }
    return LineChart(LineChartData(
      lineBarsData: seriesList,
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
            sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(meta.formattedValue, style: const TextStyle(fontSize: 8));
                })),
        bottomTitles: AxisTitles(
          sideTitles: _bottomTitles(minX, maxX),
        ),
      ),
    ));
  }

  SideTitles _bottomTitles(double minX, double maxX) {
    final interval = (maxX - minX).toInt() * 1.0;
    return SideTitles(
      showTitles: true,
      interval: interval,
      getTitlesWidget: (value, meta) {
        final ts = DateTime.fromMillisecondsSinceEpoch(value.toInt());
        return Text(
          ts.formatTo("HH:mm:ss"),
          style: const TextStyle(fontSize: 8),
        );
      },
    );
  }
}

class TimeLineSeries {
  final double time;
  final List<double> value;
  TimeLineSeries(this.time, this.value);
}
