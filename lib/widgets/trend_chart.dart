import 'package:flutter/material.dart';
import '../models/analysis_stats.dart';
import 'package:fl_chart/fl_chart.dart';

class TrendChart extends StatelessWidget {
  final List<TrendData> trendData;

  const TrendChart({
    super.key,
    required this.trendData,
  });

  @override
  Widget build(BuildContext context) {
    if (trendData.isEmpty) {
      return const Center(
        child: Text('暂无数据'),
      );
    }

    return Column(
      children: [
        _buildRedBallChart(),
        const SizedBox(height: 16),
        _buildBlueBallChart(),
      ],
    );
  }

  Widget _buildRedBallChart() {
    return AspectRatio(
      aspectRatio: 2,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                reservedSize: 30,
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= trendData.length) {
                    return const Text('');
                  }
                  return Text(
                    trendData[index].qh.toString().substring(4),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: _getRedBallLines(),
          minX: 0,
          maxX: trendData.length.toDouble() - 1,
          minY: 0,
          maxY: 35,
        ),
      ),
    );
  }

  Widget _buildBlueBallChart() {
    return AspectRatio(
      aspectRatio: 4,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                reservedSize: 30,
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= trendData.length) {
                    return const Text('');
                  }
                  return Text(
                    trendData[index].qh.toString().substring(4),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(trendData.length, (index) {
                return FlSpot(
                  index.toDouble(),
                  trendData[index].blueBall.toDouble(),
                );
              }),
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
            ),
          ],
          minX: 0,
          maxX: trendData.length.toDouble() - 1,
          minY: 0,
          maxY: 17,
        ),
      ),
    );
  }

  List<LineChartBarData> _getRedBallLines() {
    List<LineChartBarData> lines = [];

    // 为每个红球创建一条线
    for (int i = 0; i < 6; i++) {
      lines.add(
        LineChartBarData(
          spots: List.generate(trendData.length, (index) {
            return FlSpot(
              index.toDouble(),
              trendData[index].redBalls[i].toDouble(),
            );
          }),
          isCurved: true,
          color: Colors.red.withOpacity(0.5),
          barWidth: 1,
          isStrokeCapRound: true,
          dotData: FlDotData(show: true),
        ),
      );
    }

    return lines;
  }
}
