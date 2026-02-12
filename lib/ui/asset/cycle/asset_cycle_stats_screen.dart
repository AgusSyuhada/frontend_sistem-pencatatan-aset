import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../data/models/response/asset_cycle/period_model.dart';
import '../../../data/models/response/asset_cycle/stat_item.dart';
import '../../common/app_dialogs.dart';
import 'asset_cycle_stats_viewmodel.dart';

class AssetCycleStatsScreen extends StatefulWidget {
  final PeriodModel period;

  const AssetCycleStatsScreen({super.key, required this.period});

  @override
  State<AssetCycleStatsScreen> createState() => _AssetCycleStatsScreenState();
}

class _AssetCycleStatsScreenState extends State<AssetCycleStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AssetCycleStatsViewModel>();
      vm.fetchUser();
      vm.fetchStats(widget.period.year, widget.period.cycle);
    });
  }

  String _formatCurrency(num? value) {
    if (value == null) return 'Rp 0';
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  void _onDownloadPressed(
    BuildContext context,
    AssetCycleStatsViewModel vm,
  ) async {
    showLoadingDialog(context);

    final String? savedPath = await vm.downloadReport(
      widget.period.year,
      widget.period.cycle,
    );

    if (context.mounted) {
      Navigator.pop(context);

      if (savedPath != null) {
        showFileDownloadSuccessDialog(
          context: context,
          filePath: savedPath,
          onOpenFile: () {
            vm.openDownloadedFile(savedPath);
          },
        );
      } else {
        showErrorDialog(
          context,
          vm.errorMessage ?? "Gagal memproses unduhan laporan.",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Statistik Siklus",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Periode ${widget.period.cycle} / ${widget.period.year}",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Consumer<AssetCycleStatsViewModel>(
        builder: (context, vm, child) {
          if (vm.state == AssetCycleStatsState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.state == AssetCycleStatsState.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(vm.errorMessage ?? "Gagal memuat data statistik"),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => vm.fetchStats(
                        widget.period.year,
                        widget.period.cycle,
                      ),
                      child: const Text("Coba Lagi"),
                    ),
                  ],
                ),
              ),
            );
          }

          final stats = vm.stats;
          if (stats == null) return const SizedBox.shrink();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummarySection(stats, isDesktop),
                      const SizedBox(height: 24),

                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildSectionWrapper(
                                "Progres Penyelesaian",
                                _buildCompletionChart(stats, 220),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSectionWrapper(
                                "Distribusi Kondisi",
                                _buildPieChart(
                                  stats.distributions.condition,
                                  220,
                                ),
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _buildSectionWrapper(
                          "Progres Penyelesaian",
                          _buildCompletionChart(stats, 180),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionWrapper(
                          "Distribusi Kondisi",
                          _buildPieChart(stats.distributions.condition, 260),
                        ),
                      ],

                      const SizedBox(height: 24),

                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildSectionWrapper(
                                "Distribusi per Area",
                                _buildBarChart(stats.distributions.area, 300),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSectionWrapper(
                                "Tren Inventaris (Harian)",
                                _buildTimelineChart(stats.timeline, 300),
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _buildSectionWrapper(
                          "Distribusi per Area",
                          _buildBarChart(stats.distributions.area, 240),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionWrapper(
                          "Tren Inventaris (Harian)",
                          _buildTimelineChart(stats.timeline, 220),
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              if (vm.isAdmin)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _onDownloadPressed(context, vm),
                      icon: const Icon(Icons.download_rounded, size: 20),

                      label: const Text("Download Laporan (.xlsx)"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionWrapper(String title, Widget chart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        chart,
      ],
    );
  }

  Widget _buildSummarySection(dynamic stats, bool isDesktop) {
    final summary = stats.summary;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      childAspectRatio: isDesktop ? 3.5 : 2.6,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _summaryCard("Total Aset", "${summary.totalAssets}", Colors.blue),
        _summaryCard("Selesai", "${summary.cycledAssets}", Colors.green),
        _summaryCard("Tersisa", "${summary.pendingAssets}", Colors.orange),
        _summaryCard(
          "Nilai Aset",
          _formatCurrency(summary.totalAssetValue),
          Colors.purple,
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionChart(dynamic stats, double height) {
    double progress = stats.summary.completionPercentage;
    return Container(
      height: height,
      decoration: _cardDecoration(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: height * 0.3,
              sections: [
                PieChartSectionData(
                  color: Colors.green,
                  value: progress,
                  title: '',
                  radius: 12,
                ),
                PieChartSectionData(
                  color: Colors.grey.shade200,
                  value: 100 - progress,
                  title: '',
                  radius: 12,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${progress.toStringAsFixed(1)}%",
                style: TextStyle(
                  fontSize: height * 0.12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Tercapai",
                style: TextStyle(fontSize: height * 0.06, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<StatItem> items, double height) {
    if (items.isEmpty) return const Center(child: Text("Tidak ada data"));
    final List<Color> colors = [
      Colors.blue,
      Colors.orange,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.cyan,
    ];
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: height * 0.15,
                sections: items.asMap().entries.map((e) {
                  return PieChartSectionData(
                    color: colors[e.key % colors.length],
                    value: e.value.count.toDouble(),
                    title: '${e.value.percentage?.toStringAsFixed(0)}%',
                    radius: height * 0.18,
                    titleStyle: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                    titlePositionPercentageOffset: 1.4,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: items.asMap().entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: colors[e.key % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${e.value.name} (${e.value.count})",
                    style: const TextStyle(fontSize: 8, color: Colors.black45),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<StatItem> items, double height) {
    if (items.isEmpty) return const SizedBox.shrink();
    final topItems = items.length > 5 ? items.sublist(0, 5) : items;
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(10, 40, 10, 10),
      decoration: _cardDecoration(),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              topItems
                  .map((e) => e.count)
                  .reduce((a, b) => a > b ? a : b)
                  .toDouble() *
              1.3,
          barGroups: topItems
              .asMap()
              .entries
              .map(
                (e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.count.toDouble(),
                      color: Colors.blueAccent.withValues(alpha: 0.8),
                      width: 28,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= topItems.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      width: 55,
                      child: Text(
                        topItems[index].name,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Text(
                "Jumlah Aset",
                style: TextStyle(fontSize: 8, color: Colors.grey),
              ),
              axisNameSize: 12,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 7, color: Colors.grey),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildTimelineChart(List<StatItem> timeline, double height) {
    if (timeline.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text("Data tren belum tersedia")),
      );
    }
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(10, 45, 20, 15),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text(
                      "Tanggal Inventaris",
                      style: TextStyle(fontSize: 8, color: Colors.grey),
                    ),
                    axisNameSize: 12,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index % 2 != 0 || index >= timeline.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            timeline[index].name.split('-').last,
                            style: const TextStyle(
                              fontSize: 7,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 7,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade100),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: timeline
                        .asMap()
                        .entries
                        .map(
                          (e) => FlSpot(
                            e.key.toDouble(),
                            e.value.count.toDouble(),
                          ),
                        )
                        .toList(),
                    isCurved: true,
                    color: Colors.blue.withValues(alpha: 0.7),
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 1.5,
                            color: Colors.blue,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withValues(alpha: 0.05),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 10, color: Colors.blue),
              SizedBox(width: 4),
              Text(
                "Garis: Total Aset Tercycled per Hari",
                style: TextStyle(fontSize: 8, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    );
  }
}
