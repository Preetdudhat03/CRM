import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../providers/deal_provider.dart';
import '../../../../models/deal_model.dart';

class RevenueTrendChart extends ConsumerWidget {
  const RevenueTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(dealsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Trend (Last 6 Months)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(Colors.green, 'Won'),
              const SizedBox(width: 16),
              _legendDot(Colors.red, 'Lost'),
              const SizedBox(width: 16),
              _legendDot(Colors.blue, 'Net'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: dealsAsync.when(
              data: (deals) {
                final now = DateTime.now();
                List<DateTime> last6Months = [];
                for (int i = 5; i >= 0; i--) {
                  last6Months.add(DateTime(now.year, now.month - i, 1));
                }

                // Group deals by month — Won and Lost separately
                Map<String, double> monthlyWon = {};
                Map<String, double> monthlyLost = {};
                for (var month in last6Months) {
                  final key = DateFormat('MMM').format(month);
                  monthlyWon[key] = 0.0;
                  monthlyLost[key] = 0.0;
                }

                final cutoff = DateTime(now.year, now.month - 5, 1);
                for (var deal in deals) {
                  final dealDate = deal.updatedAt;
                  if (dealDate.isBefore(cutoff)) continue;

                  final key = DateFormat('MMM').format(dealDate);
                  if (deal.stage == DealStage.closedWon) {
                    if (monthlyWon.containsKey(key)) {
                      monthlyWon[key] = monthlyWon[key]! + deal.value;
                    }
                  } else if (deal.stage == DealStage.closedLost) {
                    if (monthlyLost.containsKey(key)) {
                      monthlyLost[key] = monthlyLost[key]! + deal.value;
                    }
                  }
                }

                // Build spots
                List<FlSpot> wonSpots = [];
                List<FlSpot> lostSpots = [];
                List<FlSpot> netSpots = [];
                double maxVal = 0;
                double minVal = 0;
                int index = 0;

                final keys = monthlyWon.keys.toList();
                for (var key in keys) {
                  final won = monthlyWon[key]!;
                  final lost = monthlyLost[key]!;
                  final net = won - lost;
                  wonSpots.add(FlSpot(index.toDouble(), won));
                  lostSpots.add(FlSpot(index.toDouble(), lost));
                  netSpots.add(FlSpot(index.toDouble(), net));
                  if (won > maxVal) maxVal = won;
                  if (lost > maxVal) maxVal = lost;
                  if (net > maxVal) maxVal = net;
                  if (net < minVal) minVal = net;
                  index++;
                }

                maxVal = maxVal > 0 ? maxVal * 1.25 : 1000.0;
                minVal = minVal < 0 ? minVal * 1.25 : 0;

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < 0 || value.toInt() >= last6Months.length) {
                              return const Text('');
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MMM').format(last6Months[value.toInt()]),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 75,
                          interval: maxVal > 0 ? (maxVal - minVal) / 4 : 250,
                          getTitlesWidget: (value, meta) {
                            if (value >= maxVal * 0.95) return const Text('');
                            return Text(
                              '\$${compactNumber(value)}',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.left,
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 5,
                    minY: minVal,
                    maxY: maxVal,
                    lineBarsData: [
                      // Won line (green)
                      LineChartBarData(
                        spots: wonSpots,
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.green.withOpacity(0.08),
                        ),
                      ),
                      // Lost line (red)
                      LineChartBarData(
                        spots: lostSpots,
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.red.withOpacity(0.08),
                        ),
                      ),
                      // Net revenue line (blue, main)
                      LineChartBarData(
                        spots: netSpots,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.05),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, __) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String compactNumber(double num) {
    if (num.abs() >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num.abs() >= 1000) return '${(num / 1000).toStringAsFixed(1)}k';
    return num.toStringAsFixed(0);
  }
}
