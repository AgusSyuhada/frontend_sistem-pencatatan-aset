import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_routes.dart';
import '../../../data/models/response/asset_cycle/period_model.dart';
import '../../common/app_dialogs.dart';
import 'asset_cycle_period_list_viewmodel.dart';

class AssetCycleListScreen extends StatefulWidget {
  const AssetCycleListScreen({super.key});

  @override
  State<AssetCycleListScreen> createState() => _AssetCycleListScreenState();
}

class _AssetCycleListScreenState extends State<AssetCycleListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AssetCyclePeriodListViewModel>();
      vm.resetState();
      vm.fetchPeriods();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Daftar Periode Siklus",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      floatingActionButton: Consumer<AssetCyclePeriodListViewModel>(
        builder: (context, vm, child) {
          if (!vm.isAdmin) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.createPeriod,
              );

              if (result == true && context.mounted) {
                context.read<AssetCyclePeriodListViewModel>().fetchPeriods(
                  forceRefresh: true,
                );
              }
            },
            child: const Icon(Icons.add),
          );
        },
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Cari Tahun, 'Januari', atau Siklus...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  context
                                      .read<AssetCyclePeriodListViewModel>()
                                      .search("");
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                      onChanged: (val) => context
                          .read<AssetCyclePeriodListViewModel>()
                          .search(val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Consumer<AssetCyclePeriodListViewModel>(
                    builder: (context, vm, _) {
                      bool isFilterActive =
                          vm.selectedYears.isNotEmpty ||
                          vm.selectedCycles.isNotEmpty;
                      return SizedBox(
                        height: 48,
                        width: 48,
                        child: InkWell(
                          onTap: () => _showFilterDialog(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isFilterActive
                                  ? Colors.orange.shade50
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isFilterActive
                                    ? Colors.orange.shade200
                                    : Colors.blue.shade100,
                              ),
                            ),
                            child: Icon(
                              Icons.filter_list,
                              color: isFilterActive
                                  ? Colors.orange.shade700
                                  : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: Consumer<AssetCyclePeriodListViewModel>(
                  builder: (context, vm, child) {
                    if (vm.state == AssetCyclePeriodListState.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (vm.state == AssetCyclePeriodListState.error) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(vm.errorMessage ?? "Terjadi Kesalahan"),
                            TextButton(
                              onPressed: () =>
                                  vm.fetchPeriods(forceRefresh: true),
                              child: const Text("Coba Lagi"),
                            ),
                          ],
                        ),
                      );
                    }
                    if (vm.periods.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_toggle_off,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Data tidak ditemukan.",
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await vm.fetchPeriods(forceRefresh: true);
                      },
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: vm.periods.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final period = vm.periods[index];
                          final code = vm.getPeriodCode(
                            period.year,
                            period.cycle,
                          );
                          return _buildPeriodCard(context, vm, period, code);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodCard(
    BuildContext context,
    AssetCyclePeriodListViewModel vm,
    PeriodModel period,
    String code,
  ) {
    final progress = period.totalAssets > 0
        ? period.cycledAssets / period.totalAssets
        : 0.0;
    final percentage = (progress * 100).toStringAsFixed(1);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.cycleCheck, arguments: period);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade100),
              ),
              alignment: Alignment.center,
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Periode ${period.cycle} Tahun ${period.year}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => _showActions(context, vm, period),
                      ),
                    ],
                  ),
                  Text(
                    vm.getMonthRange(period.cycle),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress >= 1.0 ? Colors.green : Colors.blue,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$percentage%",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${period.cycledAssets} dari ${period.totalAssets} Aset Selesai",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(
    BuildContext context,
    AssetCyclePeriodListViewModel vm,
    PeriodModel period,
  ) {
    List<DialogActionItem> actions = [
      DialogActionItem(
        label: "Lihat Statistik",
        icon: Icons.bar_chart,
        color: Colors.blue,
        id: 'stats',
      ),
    ];

    if (vm.isAdmin) {
      actions.add(
        DialogActionItem(
          label: "Edit Daftar Aset",
          icon: Icons.edit_note,
          color: Colors.orange,
          id: 'edit',
        ),
      );
      actions.add(
        DialogActionItem(
          label: "Hapus Periode",
          icon: Icons.delete,
          color: Colors.red,
          id: 'delete',
        ),
      );
    }

    showSelectionActionDialog(
      context: context,
      title: "Aksi: Periode ${period.cycle}/${period.year}",
      actions: actions,
      onSelected: (actionId) async {
        if (actionId == 'stats') {
          Navigator.pushNamed(context, AppRoutes.cycleStats, arguments: period);
        } else if (actionId == 'edit') {
          final result = await Navigator.pushNamed(
            context,
            AppRoutes.createPeriod,
            arguments: period,
          );
          if (result == true && context.mounted) {
            vm.fetchPeriods(forceRefresh: true);
          }
        } else if (actionId == 'delete') {
          _confirmDelete(context, vm, period);
        }
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    AssetCyclePeriodListViewModel vm,
    PeriodModel period,
  ) {
    showConfirmationDialog(
      context,
      "Hapus Periode?",
      "Yakin hapus Periode ${period.cycle}/${period.year}? Data aset akan hilang dari siklus ini.",
      () async {
        showLoadingDialog(context);
        final success = await vm.deletePeriod(period.year, period.cycle);
        if (context.mounted) {
          Navigator.pop(context);

          if (success) {
            showSuccessDialog(context, "Periode berhasil dihapus", () {});
          } else {
            showErrorDialog(context, vm.errorMessage ?? "Gagal menghapus.");
          }
        }
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    final vm = context.read<AssetCyclePeriodListViewModel>();
    Set<int> tempYears = Set.from(vm.selectedYears);
    Set<int> tempCycles = Set.from(vm.selectedCycles);

    showGenericFilterDialog(
      context: context,
      title: "Filter Periode",
      onReset: () => vm.resetFilters(),
      onApply: () => vm.applyFilters(years: tempYears, cycles: tempCycles),
      content: StatefulBuilder(
        builder: (context, setStateContent) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Tahun",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: vm.uniqueYears.map((year) {
                  final isSelected = tempYears.contains(year);
                  return FilterChip(
                    label: Text("$year"),
                    selected: isSelected,
                    onSelected: (val) => setStateContent(
                      () => val ? tempYears.add(year) : tempYears.remove(year),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                "Siklus",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: vm.uniqueCycleLabels.map((label) {
                  final cycleNum = vm.getCycleFromLabel(label);
                  final isSelected = tempCycles.contains(cycleNum);
                  return FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (val) => setStateContent(
                      () => val
                          ? tempCycles.add(cycleNum)
                          : tempCycles.remove(cycleNum),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
