import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_routes.dart';
import '../../../data/models/response/asset_master/asset_list_item.dart';
import '../../common/app_dialogs.dart';
import '../../common/generic_data_table.dart';
import 'asset_master_list_viewmodel.dart';

class AssetMasterListScreen extends StatefulWidget {
  const AssetMasterListScreen({super.key});

  @override
  State<AssetMasterListScreen> createState() => _AssetMasterListScreenState();
}

class _AssetMasterListScreenState extends State<AssetMasterListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late AssetMasterListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetMasterListViewModel>().init();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel = context.read<AssetMasterListViewModel>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _viewModel.resetState();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      if (currentScroll >= (maxScroll - 200)) {
        _viewModel.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Master Data Aset",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      floatingActionButton: Consumer<AssetMasterListViewModel>(
        builder: (context, vm, _) {
          if (!vm.isAdmin) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.assetForm,
              );
              if (result == true && mounted) {
                _viewModel.refreshManual();
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
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Cari No Aset, Nama, atau SN...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _viewModel.search("");
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
                      onChanged: (val) => _viewModel.search(val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Consumer<AssetMasterListViewModel>(
                    builder: (context, vm, _) {
                      bool isFilterActive =
                          vm.selectedConditionIds.isNotEmpty ||
                          vm.selectedLocationIds.isNotEmpty;

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

              Consumer<AssetMasterListViewModel>(
                builder: (ctx, vm, _) {
                  if (vm.selectedConditionIds.isNotEmpty ||
                      vm.selectedLocationIds.isNotEmpty) {
                    final condCount = vm.selectedConditionIds.length;
                    final locCount = vm.selectedLocationIds.length;
                    final infoParts = <String>[];

                    if (locCount > 0) infoParts.add("$locCount Lokasi");
                    if (condCount > 0) infoParts.add("$condCount Kondisi");

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Filter Aktif: ${infoParts.join(", ")}",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => vm.resetFilters(),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              Expanded(
                child: Consumer<AssetMasterListViewModel>(
                  builder: (context, vm, child) {
                    if (vm.state == AssetMasterListState.error &&
                        vm.assets.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 8),
                            Text(vm.errorMessage ?? "Gagal memuat data"),
                            TextButton(
                              onPressed: () => vm.refreshManual(),
                              child: const Text("Coba Lagi"),
                            ),
                          ],
                        ),
                      );
                    }

                    return Stack(
                      children: [
                        GenericDataTable<AssetListItem>(
                          scrollController: _scrollController,
                          isLoading: vm.state == AssetMasterListState.loading,
                          data: vm.assets,
                          minWidth: isMobile ? 800 : 1000,
                          onRefresh: () async {
                            await vm.refreshManual();
                          },
                          onRowTap: (asset) {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.assetDetail,
                              arguments: asset.assetNumber,
                            );
                          },
                          headers: [
                            DataHeader(
                              text: "No",
                              width: 50,
                              textAlign: TextAlign.center,
                            ),
                            DataHeader(
                              text: "No Aset",
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
                              width: 100,
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
                                DataCellWidget(
                                  text: asset.assetNumber,
                                  width: 120,
                                  fontWeight: FontWeight.bold,
                                ),
                                DataCellWidget(text: asset.assetName, flex: 2),
                                DataCellWidget(
                                  text: asset.locationName ?? "-",
                                  flex: 1,
                                ),
                                DataCellWidget(
                                  text: asset.conditionName ?? "-",
                                  width: 100,
                                  color: _getConditionColor(
                                    asset.conditionName,
                                  ),
                                  fontWeight: FontWeight.w500,
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
                                          _showActions(context, asset),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        if (vm.isLoadingMore)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.9),
                              padding: const EdgeInsets.all(8.0),
                              child: const Center(
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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
    if (condition == null) {
      return Colors.black87;
    }
    final lower = condition.toLowerCase();
    if (lower.contains("baik") || lower.contains("good")) {
      return Colors.green;
    }
    if (lower.contains("digunakan")) {
      return Colors.blue;
    }
    if (lower.contains("cadangan")) {
      return Colors.purple;
    }
    if (lower.contains("rusak ringan") ||
        lower.contains("rusak") && lower.contains("ringan")) {
      return Colors.orange;
    }
    if (lower.contains("rusak berat") ||
        lower.contains("rusak") && lower.contains("berat")) {
      return Colors.red;
    }
    if (lower.contains("penghapusan")) {
      return Colors.grey;
    }
    if (lower.contains("tidak ditemukan")) {
      return Colors.red;
    }
    {
      return Colors.orange;
    }
  }

  void _showFilterDialog(BuildContext context) {
    FocusScope.of(context).unfocus();
    final vm = _viewModel;
    Set<int> tempConditions = Set.from(vm.selectedConditionIds);
    Set<int> tempLocations = Set.from(vm.selectedLocationIds);

    showGenericFilterDialog(
      context: context,
      title: "Filter Aset",
      onReset: () => vm.resetFilters(),
      onApply: () => vm.applyFilters(
        conditionIds: tempConditions,
        locationIds: tempLocations,
      ),

      content: StatefulBuilder(
        builder: (context, setStateContent) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Kondisi",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              if (vm.lookupConditions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    "Memuat data kondisi...",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vm.lookupConditions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3,
                  ),
                  itemBuilder: (ctx, index) {
                    final cond = vm.lookupConditions[index];
                    final isSelected = tempConditions.contains(
                      cond.conditionId,
                    );
                    return _buildFilterToggleButton(
                      label: cond.conditionName,
                      isSelected: isSelected,
                      onTap: () {
                        setStateContent(() {
                          if (isSelected) {
                            tempConditions.remove(cond.conditionId);
                          } else {
                            tempConditions.add(cond.conditionId);
                          }
                        });
                      },
                    );
                  },
                ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              const Text(
                "Lokasi",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              if (vm.lookupLocations.isEmpty)
                const Text(
                  "Memuat data lokasi...",
                  style: TextStyle(fontStyle: FontStyle.italic),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vm.lookupLocations.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemBuilder: (ctx, index) {
                    final loc = vm.lookupLocations[index];
                    final label = "${loc.location}";
                    final isSelected = tempLocations.contains(loc.locationId);
                    return _buildFilterToggleButton(
                      label: label,
                      isSelected: isSelected,
                      onTap: () {
                        setStateContent(() {
                          if (isSelected) {
                            tempLocations.remove(loc.locationId);
                          } else {
                            tempLocations.add(loc.locationId);
                          }
                        });
                      },
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.blue.shade900
                      : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context, AssetListItem asset) {
    FocusScope.of(context).unfocus();
    final vm = _viewModel;

    final actions = [
      DialogActionItem(
        label: "Lihat Detail",
        icon: Icons.assignment,
        color: Colors.blue,
        id: 'view_detail',
      ),
      DialogActionItem(
        label: "Edit Aset",
        icon: Icons.edit,
        color: Colors.orange,
        id: 'edit_asset',
      ),
    ];

    if (vm.isAdmin) {
      actions.add(
        DialogActionItem(
          label: "Nonaktifkan (Hapus)",
          icon: Icons.delete_outline,
          color: Colors.red,
          id: 'deactivate_asset',
        ),
      );
    }

    showSelectionActionDialog(
      context: context,
      title: "Aset: ${asset.assetName}",
      actions: actions,
      onSelected: (actionId) {
        if (actionId == 'view_detail') {
          Navigator.pushNamed(
            context,
            AppRoutes.assetDetail,
            arguments: asset.assetNumber,
          );
        } else if (actionId == 'edit_asset') {
          Navigator.pushNamed(
            context,
            AppRoutes.assetForm,
            arguments: asset.assetNumber,
          );
        } else if (actionId == 'deactivate_asset') {
          _confirmDeactivation(context, asset);
        }
      },
    );
  }

  void _confirmDeactivation(BuildContext context, AssetListItem asset) {
    showConfirmationDialog(
      context,
      "Hapus Akses Aset?",
      "Anda akan menonaktifkan aset ${asset.assetName} (${asset.assetNumber}). \n"
          "Data aset ini akan hilang dari daftar aktif. Lanjutkan?",
      () async {
        showLoadingDialog(context);

        final message = await _viewModel.deactivateAsset(asset.assetNumber);

        if (context.mounted) {
          Navigator.pop(context);

          if (message != null) {
            showSuccessDialog(context, message, () {});
          } else {
            showErrorDialog(
              context,
              _viewModel.errorMessage ?? "Gagal menonaktifkan aset.",
            );
          }
        }
      },
    );
  }
}
