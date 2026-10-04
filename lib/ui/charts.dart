import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/condenser_provider.dart';
import 'theme.dart';

class TelemetryCharts extends StatelessWidget {
  const TelemetryCharts({super.key, required this.c});
  final CondenserProvider c;

  bool _hasTemp(List<TelemetryPoint> points) =>
      points.any((p) => p.airTemp != null || p.dewPoint != null || p.coldPlate != null);

  bool _hasHumidity(List<TelemetryPoint> points) => points.any((p) => p.humidity != null);

  @override
  Widget build(BuildContext context) {
    final points = c.history;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Diễn biến nhiệt độ', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Theo dõi không khí, điểm sương và bề mặt lạnh theo thời gian',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NgungTuTheme.soft.withValues(alpha: 0.6),
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 12),
        _ChartCard(
          child: !_hasTemp(points)
              ? const _EmptyChart(text: 'Đang ghi nhận nhiệt độ...')
              : _TempChart(points: points),
        ),
        const SizedBox(height: 20),
        Text('Diễn biến độ ẩm', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _ChartCard(
          child: !_hasHumidity(points)
              ? const _EmptyChart(text: 'Đang ghi nhận độ ẩm...')
              : _HumidityChart(points: points),
        ),
        const SizedBox(height: 12),
        const _Legend(),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: NgungTuTheme.panel.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(color: NgungTuTheme.soft.withValues(alpha: 0.55)),
      ),
    );
  }
}

class _TempChart extends StatelessWidget {
  const _TempChart({required this.points});
  final List<TelemetryPoint> points;

  List<FlSpot> _spots(double? Function(TelemetryPoint p) pick) {
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final v = pick(points[i]);
      if (v != null) spots.add(FlSpot(i.toDouble(), v));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final air = _spots((p) => p.airTemp);
    final dew = _spots((p) => p.dewPoint);
    final cold = _spots((p) => p.coldPlate);
    final set = _spots((p) => p.setpoint);

    final allY = [...air, ...dew, ...cold, ...set].map((e) => e.y).toList();
    final minY = (allY.isEmpty ? 0.0 : allY.reduce((a, b) => a < b ? a : b)) - 2.0;
    final maxY = (allY.isEmpty ? 40.0 : allY.reduce((a, b) => a > b ? a : b)) + 2.0;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: TextStyle(color: NgungTuTheme.soft.withValues(alpha: 0.5), fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => NgungTuTheme.panel,
          ),
        ),
        lineBarsData: [
          _line(air, NgungTuTheme.copper),
          _line(dew, NgungTuTheme.aqua),
          _line(cold, NgungTuTheme.ice),
          _line(set, const Color(0xFFF4A261), dashed: true),
        ],
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color, {bool dashed = false}) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: dashed ? 2 : 2.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      dashArray: dashed ? [6, 4] : null,
      belowBarData: BarAreaData(
        show: !dashed,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }
}

class _HumidityChart extends StatelessWidget {
  const _HumidityChart({required this.points});
  final List<TelemetryPoint> points;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final h = points[i].humidity;
      if (h != null) spots.add(FlSpot(i.toDouble(), h));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 20,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}%',
                style: TextStyle(color: NgungTuTheme.soft.withValues(alpha: 0.5), fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF7BDFF2),
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF7BDFF2).withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(t, style: TextStyle(color: NgungTuTheme.soft.withValues(alpha: 0.7), fontSize: 11)),
          ],
        );

    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        item(NgungTuTheme.copper, 'Không khí'),
        item(NgungTuTheme.aqua, 'Điểm sương'),
        item(NgungTuTheme.ice, 'Bề mặt lạnh'),
        item(const Color(0xFFF4A261), 'Mức cần đạt'),
        item(const Color(0xFF7BDFF2), 'Độ ẩm'),
      ],
    );
  }
}
