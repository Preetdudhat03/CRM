import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../providers/deal_provider.dart';
import '../../../../models/deal_model.dart';
import '../../../../widgets/animations/fade_in_slide.dart';

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
          const SizedBox(height: 32),
          SizedBox(
            height: 220,
            child: dealsAsync.when(
              data: (deals) {
                // Generate last 6 months list
                final now = DateTime.now();
                List<DateTime> last6Months = [];
                for (int i = 5; i >= 0; i--) {
                  last6Months.add(DateTime(now.year, now.month - i, 1));
                }

                // Group closed won deals by month
                Map<String, double> monthlyRevenue = {};
                for (var month in last6Months) {
                  final key = DateFormat('MMM').format(month);
                  monthlyRevenue[key] = 0.0;
                }

                for (var deal in deals) {
                  if (deal.stage == DealStage.closedWon) {
                    // check if inside the last 6 months window
                    if (deal.updatedAt.isAfter(DateTime(now.year, now.month - 5, 1))) {
                        final key = DateFormat('MMM').format(deal.updatedAt);
                        if (monthlyRevenue.containsKey(key)) {
                           monthlyRevenue[key] = monthlyRevenue[key]! + deal.value;
                        }
                    }
                  }
                }

                List<FlSpot> spots = [];
                double maxRevenue = 0;
                int index = 0;
                
                monthlyRevenue.forEach((key, value) {
                  spots.add(FlSpot(index.toDouble(), value));
                  if (value > maxRevenue) maxRevenue = value;
                  index++;
                });

                // Adding 10% vertical padding so chart doesn't clip
                maxRevenue = maxRevenue > 0 ? maxRevenue * 1.2 : 1000;

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
                          reservedSize: 55,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const Text('');
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
                    minY: 0,
                    maxY: maxRevenue,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.green.withOpacity(0.1),
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

  String compactNumber(double num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}k';
    return num.toStringAsFixed(0);
  }
}
