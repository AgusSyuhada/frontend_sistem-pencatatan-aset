import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_routes.dart';
import '../../../data/models/response/asset_cycle/period_model.dart';
import '../../../data/models/response/asset_cycle/asset_cycle_simple_data_model.dart';
import '../../common/generic_data_table.dart';
import '../../common/app_dialogs.dart';
import 'asset_cycle_by_period_viewmodel.dart';
import 'asset_cycle_detail_screen.dart';

class AssetCycleByPeriodScreen extends StatefulWidget {
  final PeriodModel period;

  const AssetCycleByPeriodScreen({super.key, required this.period});

  @override
  State<AssetCycleByPeriodScreen> createState() =>
      _AssetCycleByPeriodScreenState();
}

class _AssetCycleByPeriodScreenState extends State<AssetCycleByPeriodScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool get _isPeriodActive {
    final now = DateTime.now();
    int currentYear = now.year;
    int currentCycle;
    int month = now.month;

    if (month >= 1 && month <= 4) {
      currentCycle = 1;
    } else if (month >= 5 && month <= 8) {
      currentCycle = 2;
    } else {
      currentCycle = 3;
    }

    return widget.period.year == currentYear &&
        widget.period.cycle == currentCycle;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AssetCycleByPeriodViewModel>();
      vm.resetState();
      vm.init(widget.period.year, widget.period.cycle);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToDetail(String assetNumber, {bool startEditing = false}) {
    Navigator.pushNamed(
      context,
      AppRoutes.assetCycleDetail,
      arguments: AssetCycleDetailArguments(
        year: widget.period.year,
        cycle: widget.period.cycle,
        assetNumber: assetNumber,
        startEditing: startEditing,
      ),
    ).then((shouldRefresh) {
      if (!mounted) return;
      if (shouldRefresh == true) {
        context.read<AssetCycleByPeriodViewModel>().fetchAssets();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Daftar Aset Siklus",
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Cari No. Aset, Nama, Lokasi...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  context
                                      .read<AssetCycleByPeriodViewModel>()
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
                          .read<AssetCycleByPeriodViewModel>()
                          .search(val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Consumer<AssetCycleByPeriodViewModel>(
                    builder: (context, vm, _) {
                      bool isFilterActive =
                          vm.selectedConditions.isNotEmpty ||
                          vm.selectedLocations.isNotEmpty ||
                          vm.selectedStatus != "Semua";
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
                child: Consumer<AssetCycleByPeriodViewModel>(
                  builder: (context, vm, child) {
                    if (vm.state == AssetCycleByPeriodState.error) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(vm.errorMessage ?? "Gagal memuat data"),
                            TextButton(
                              onPressed: () => vm.fetchAssets(),
                              child: const Text("Coba Lagi"),
                            ),
                          ],
                        ),
                      );
                    }

                    return GenericDataTable<AssetCycleSimpleDataModel>(
                      isLoading: vm.state == AssetCycleByPeriodState.loading,
                      data: vm.assets,
                      minWidth: isMobile ? 900 : 1200,
                      onRefresh: () async => await vm.fetchAssets(),

                      onRowTap: (asset) => _navigateToDetail(asset.assetNumber),
                      headers: [
                        DataHeader(
                          text: "No",
                          width: 50,
                          textAlign: TextAlign.center,
                        ),

                        DataHeader(
                          text: "Status",
                          width: 80,
                          textAlign: TextAlign.center,
                          onSort: () => vm.sort('status'),
                          isAscending: vm.sortColumn == 'status'
                              ? vm.isAscending
                              : null,
                        ),

                        DataHeader(
                          text: "No. Aset",
                          width: 120,
                          onSort: () => vm.sort('assetNumber'),
                          isAscending: vm.sortColumn == 'assetNumber'
                              ? vm.isAscending
                              : null,
                        ),
                        DataHeader(
                          text: "Nama Aset",
                          flex: 2,
                          onSort: () => vm.sort('assetName'),
                          isAscending: vm.sortColumn == 'assetName'
                              ? vm.isAscending
                              : null,
                        ),
                        DataHeader(
                          text: "Lokasi",
                          flex: 1,
                          onSort: () => vm.sort('location'),
                          isAscending: vm.sortColumn == 'location'
                              ? vm.isAscending
                              : null,
                        ),
                        DataHeader(
                          text: "Kondisi",
                          width: 150,
                          onSort: () => vm.sort('condition'),
                          isAscending: vm.sortColumn == 'condition'
                              ? vm.isAscending
                              : null,
                        ),
                        DataHeader(
                          text: "Aksi",
                          width: 60,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      rowBuilder: (context, index, asset) {
                        return Row(
                          children: [
                            DataCellWidget(
                              text: "${index + 1}",
                              width: 50,
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(
                              width: 80,
                              child: Center(
                                child: asset.isCycled
                                    ? const Tooltip(
                                        message: "Sudah di-cycle",
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 22,
                                        ),
                                      )
                                    : const Tooltip(
                                        message: "Belum di-cycle",
                                        child: Icon(
                                          Icons.radio_button_unchecked,
                                          color: Colors.grey,
                                          size: 22,
                                        ),
                                      ),
                              ),
                            ),

                            DataCellWidget(
                              text: asset.assetNumber,
                              width: 120,
                              fontWeight: FontWeight.bold,
                            ),
                            DataCellWidget(text: asset.assetName, flex: 2),
                            DataCellWidget(
                              text: asset.locationName ?? "-",
                              flex: 1,
                              color: Colors.grey.shade700,
                            ),
                            DataCellWidget(
                              text: asset.conditionName ?? "-",
                              width: 150,
                              color: _getConditionColor(asset.conditionName),
                            ),
                            SizedBox(
                              width: 60,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () =>
                                      _showActions(context, asset, vm.isAdmin),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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

  Color _getConditionColor(String? condition) {
    if (condition == null) return Colors.black87;
    final lower = condition.toLowerCase();
    if (lower.contains("baik")) return Colors.green;
    if (lower.contains("rusak")) return Colors.red;
    return Colors.orange;
  }

  void _showFilterDialog(BuildContext context) {
    final vm = context.read<AssetCycleByPeriodViewModel>();
    Set<String> tempCond = Set.from(vm.selectedConditions);
    Set<String> tempLoc = Set.from(vm.selectedLocations);
    String tempStatus = vm.selectedStatus;

    showGenericFilterDialog(
      context: context,
      title: "Filter Aset Siklus",
      onReset: () => vm.resetFilters(),
      onApply: () => vm.applyFilters(
        conditions: tempCond,
        locations: tempLoc,
        status: tempStatus,
      ),
      content: StatefulBuilder(
        builder: (context, setStateContent) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Status Pengerjaan",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: vm.statusOptions.map((status) {
                    final isSelected = tempStatus == status;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () =>
                              setStateContent(() => tempStatus = status),
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue.shade300
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.blue.shade900
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                const Text(
                  "Kondisi Fisik",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _buildGridFilter(
                  items: vm.uniqueConditions,
                  selectedItems: tempCond,
                  onToggle: (item, isSelected) => setStateContent(
                    () =>
                        isSelected ? tempCond.add(item) : tempCond.remove(item),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "Lokasi",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _buildGridFilter(
                  items: vm.uniqueLocations,
                  selectedItems: tempLoc,
                  onToggle: (item, isSelected) => setStateContent(
                    () => isSelected ? tempLoc.add(item) : tempLoc.remove(item),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridFilter({
    required List<String> items,
    required Set<String> selectedItems,
    required Function(String, bool) onToggle,
  }) {
    if (items.isEmpty) {
      return const Text(
        "- Data Kosong -",
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedItems.contains(item);
        return InkWell(
          onTap: () => onToggle(item, !isSelected),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
              ),
            ),
            child: Text(
              item,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.blue.shade900 : Colors.black87,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  void _showActions(
    BuildContext context,
    AssetCycleSimpleDataModel asset,
    bool isAdmin,
  ) {
    FocusScope.of(context).unfocus();

    List<DialogActionItem> actions = [
      DialogActionItem(
        label: "Lihat Detail",
        icon: Icons.assignment,
        color: Colors.blue,
        id: 'view_detail',
      ),
    ];

    if (_isPeriodActive) {
      actions.add(
        DialogActionItem(
          label: "Edit Data",
          icon: Icons.edit,
          color: Colors.orange,
          id: 'edit_data',
        ),
      );
    }

    if (isAdmin) {
      actions.add(
        DialogActionItem(
          label: "Hapus dari Siklus",
          icon: Icons.delete_outline,
          color: Colors.red,
          id: 'delete_from_cycle',
        ),
      );
    }

    showSelectionActionDialog(
      context: context,
      title: "Aset: ${asset.assetName}",
      actions: actions,
      onSelected: (actionId) {
        if (actionId == 'view_detail') {
          _navigateToDetail(asset.assetNumber, startEditing: false);
        } else if (actionId == 'edit_data') {
          _navigateToDetail(asset.assetNumber, startEditing: true);
        } else if (actionId == 'delete_from_cycle') {
          showConfirmationDialog(
            context,
            "Hapus dari Siklus?",
            "Anda yakin ingin menghapus aset ${asset.assetNumber} dari periode siklus ini? Data akan hilang dari laporan siklus ini, tetapi Master Data aman.",
            () async {
              showLoadingDialog(context);
              final msg = await context
                  .read<AssetCycleByPeriodViewModel>()
                  .deleteAsset(asset.assetNumber);
              if (context.mounted) {
                Navigator.pop(context);
                if (msg != null) {
                  showSuccessDialog(context, msg, () {});
                } else {
                  showErrorDialog(context, "Gagal menghapus aset.");
                }
              }
            },
          );
        }
      },
    );
  }
}
