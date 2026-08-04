import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Enterprise Side Panel — Right column (30%) of the admin dashboard.
/// Contiene el gráfico de tendencia: asistencias por día (últimos 7 días).
/// Los datos vienen del ViewModel ([AdminDashboardState.weeklyAttendanceChart])
/// — la agregación vive en UNA sola fuente, no se recalcula aquí.
class EnterpriseSidePanel extends StatelessWidget {
  final List<int> weeklyData;

  const EnterpriseSidePanel({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: _MiniTrendCard(weeklyData: weeklyData),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MINI TREND CHART (Last 7 days, compact)
// ═══════════════════════════════════════════════════════════════════════
class _MiniTrendCard extends StatelessWidget {
  final List<int> weeklyData;
  const _MiniTrendCard({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final data = weeklyData;
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cSurface,
        border: Border.all(color: context.cBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Asistencias por Día',
                style: TextStyle(
                  color: context.cTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Últimos 7 días',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Summary
          Text(
            'Total: ${data.reduce((a, b) => a + b)} entradas',
            style: TextStyle(color: context.cTextTertiary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      maxVal > 0 ? (maxVal / 3).ceilToDouble() : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: context.cBorder.withValues(alpha: 0.3),
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const dayLabels = [
                          'Lun',
                          'Mar',
                          'Mié',
                          'Jue',
                          'Vie',
                          'Sáb',
                          'Dom'
                        ];
                        final daysAgo = 6 - value.toInt();
                        final date = today.subtract(Duration(days: daysAgo));
                        final dayIndex = (date.weekday - 1) % 7;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            dayLabels[dayIndex],
                            style: TextStyle(
                                color: context.cTextTertiary, fontSize: 10),
                          ),
                        );
                      },
                      interval: 1,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxVal > 0 ? maxVal.toDouble() * 1.2 : 5,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toInt()} entradas',
                          const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: data
                        .asMap()
                        .entries
                        .map(
                            (e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                        .toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primary,
                        strokeWidth: 2,
                        strokeColor: context.cSurface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.primary.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
