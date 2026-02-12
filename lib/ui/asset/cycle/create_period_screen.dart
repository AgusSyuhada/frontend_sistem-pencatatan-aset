import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/response/asset_master/asset_list_item.dart';
import '../../../data/models/response/asset_cycle/period_model.dart';
import '../../common/app_dialogs.dart';
import '../../common/generic_data_table.dart';
import 'create_period_viewmodel.dart';
import '../../common/custom_dropdown_field.dart';

class CreatePeriodScreen extends StatefulWidget {
  const CreatePeriodScreen({super.key});

  @override
  State<CreatePeriodScreen> createState() => _CreatePeriodScreenState();
}

class _CreatePeriodScreenState extends State<CreatePeriodScreen> {
  final ScrollController _assetScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _cycleController = TextEditingController();

  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _assetScrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final vm = context.read<CreatePeriodViewModel>();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (args is PeriodModel) {
          vm.init(year: args.year, cycle: args.cycle).then((_) {
            if (mounted) {
              setState(() {
                _yearController.text = args.year.toString();
                _cycleController.text =
                    "Siklus ${args.cycle} (${_getMonthRange(args.cycle)})";
              });
            }
          });
        } else {
          vm.init();
        }
      });
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _assetScrollController.dispose();
    _searchController.dispose();
    _yearController.dispose();
    _cycleController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_assetScrollController.hasClients) {
      final maxScroll = _assetScrollController.position.maxScrollExtent;
      final currentScroll = _assetScrollController.position.pixels;

      if (currentScroll >= (maxScroll - 300)) {
        context.read<CreatePeriodViewModel>().loadMoreAssets();
      }
    }
  }

  String _getMonthRange(int cycle) {
    switch (cycle) {
      case 1:
        return "Januari - April";
      case 2:
        return "Mei - Agustus";
      case 3:
        return "September -  Desember";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CreatePeriodViewModel>(
      builder: (context, vm, child) {
        final title = vm.isEditMode ? "Edit Siklus" : "Buat Siklus Baru";

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            _handleExit(context, vm);
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleExit(context, vm),
              ),
            ),
            body:
                vm.state == CreatePeriodState.loading &&
                    vm.currentStep == CreatePeriodStep.formInput
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _buildStepIndicator(vm.currentStep),
                      Expanded(child: _buildBody(context, vm)),
                    ],
                  ),
            bottomNavigationBar: _buildBottomBar(context, vm),
          ),
        );
      },
    );
  }

  void _handleExit(BuildContext context, CreatePeriodViewModel vm) {
    if (vm.state == CreatePeriodState.submitting) return;

    if (vm.currentStep == CreatePeriodStep.formInput && !vm.hasChanges) {
      Navigator.pop(context);
      return;
    }

    showConfirmationDialog(
      context,
      "Batalkan ${vm.isEditMode ? 'Perubahan' : 'Pembuatan'}",
      "Apakah Anda yakin ingin keluar? Semua inputan belum tersimpan akan hilang.",
      () {
        Navigator.of(context).pop();

        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  Widget _buildStepIndicator(CreatePeriodStep currentStep) {
    int currentIdx = currentStep.index;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepItem(1, "Periode", currentIdx >= 0),
          _buildStepLine(currentIdx >= 1),
          _buildStepItem(2, "Pilih Aset", currentIdx >= 1),
          _buildStepLine(currentIdx >= 2),
          _buildStepItem(3, "Preview", currentIdx >= 2),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.blue : Colors.grey.shade200,
          ),
          child: Center(
            child: Text(
              "$step",
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.blue : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? Colors.blue : Colors.grey.shade300,
        margin: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CreatePeriodViewModel vm) {
    switch (vm.currentStep) {
      case CreatePeriodStep.formInput:
        return _buildStep1Form(vm);
      case CreatePeriodStep.selectAssets:
        return _buildStep2SelectAssets(vm);
      case CreatePeriodStep.review:
        return _buildStep3Review(vm);
    }
  }

  Widget _buildStep1Form(CreatePeriodViewModel vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: vm.isEditMode
                  ? Colors.orange.shade50
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: vm.isEditMode
                    ? Colors.orange.shade100
                    : Colors.blue.shade100,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  vm.isEditMode ? Icons.edit_calendar : Icons.info_outline,
                  color: vm.isEditMode ? Colors.orange : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    vm.isEditMode
                        ? "Mode Edit: Tahun & Siklus tidak dapat diubah. Silakan klik 'Lanjut' untuk mengelola daftar aset."
                        : "Tentukan Tahun dan Siklus Audit untuk memulai.",
                    style: TextStyle(
                      color: vm.isEditMode
                          ? Colors.orange.shade800
                          : Colors.blue.shade800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          CustomSearchableDropdown<int>(
            label: "Tahun",
            hint: "Pilih Tahun",
            controller: _yearController,
            readOnly: vm.isEditMode,
            futureRequest: (query) async {
              if (vm.isEditMode) return [];
              return vm.yearList
                  .where((y) => y.toString().contains(query))
                  .toList();
            },
            displayItem: (item) => "$item",
            onSelected: (item) => vm.setYear(item),
          ),

          const SizedBox(height: 12),

          CustomSearchableDropdown<int>(
            label: "Siklus",
            hint: "Pilih Siklus",
            controller: _cycleController,
            readOnly: vm.isEditMode,
            futureRequest: (query) async {
              if (vm.isEditMode) return [];
              const cycles = [1, 2, 3];
              return cycles
                  .where(
                    (c) =>
                        "Siklus $c".toLowerCase().contains(query.toLowerCase()),
                  )
                  .toList();
            },
            displayItem: (item) => "Siklus $item (${_getMonthRange(item)})",
            onSelected: (item) => vm.setCycle(item),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2SelectAssets(CreatePeriodViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Cari No Aset / Nama...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        vm.searchAssets("");
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (val) => vm.searchAssets(val),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Terpilih: ${vm.selectedAssetNumbers.length} Aset",
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (vm.selectedAssetNumbers.isNotEmpty)
                InkWell(
                  onTap: () => vm.resetSelection(),
                  child: const Text(
                    "Reset Pilihan",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: GenericDataTable<AssetListItem>(
                        scrollController: _assetScrollController,
                        isLoading: vm.state == CreatePeriodState.loading,
                        data: vm.availableAssets,
                        minWidth: 800,
                        headers: [
                          DataHeader(
                            text: "Pilih",
                            width: 60,
                            textAlign: TextAlign.center,
                          ),
                          DataHeader(text: "No Aset", width: 120),
                          DataHeader(text: "Nama Aset", flex: 2),
                          DataHeader(text: "Lokasi", flex: 1),
                          DataHeader(text: "Kondisi", width: 100),
                        ],
                        rowBuilder: (context, index, asset) {
                          final isSelected = vm.selectedAssetNumbers.contains(
                            asset.assetNumber,
                          );
                          return Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: Checkbox(
                                  value: isSelected,
                                  onChanged: (val) =>
                                      vm.toggleAssetSelection(asset),
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
                              ),
                              DataCellWidget(
                                text: asset.conditionName ?? "-",
                                width: 100,
                              ),
                            ],
                          );
                        },
                        onRefresh: () async => vm.fetchAssets(isRefresh: true),
                      ),
                    ),
                    if (vm.isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Review(CreatePeriodViewModel vm) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                _buildSummaryRow("Tahun", "${vm.selectedYear}"),
                const Divider(height: 24, thickness: 1),
                _buildSummaryRow(
                  "Siklus",
                  "Siklus ${vm.selectedCycle} (${_getMonthRange(vm.selectedCycle!)})",
                ),
                const Divider(height: 24, thickness: 1),
                _buildSummaryRow(
                  "Total Aset Terpilih",
                  "${vm.selectedAssetNumbers.length} Item",
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Konfirmasi Daftar Aset:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          SizedBox(
            height: 400,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GenericDataTable<AssetListItem>(
                isLoading: false,
                data: vm.previewSelectedAssets,
                minWidth: 800,
                headers: [
                  DataHeader(
                    text: "No",
                    width: 50,
                    textAlign: TextAlign.center,
                  ),
                  DataHeader(text: "No Aset", width: 120),
                  DataHeader(text: "Nama Aset", flex: 2),
                  DataHeader(text: "Lokasi", flex: 1),
                  DataHeader(text: "Kondisi", width: 100),
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
                      DataCellWidget(text: asset.locationName ?? "-", flex: 1),
                      DataCellWidget(
                        text: asset.conditionName ?? "-",
                        width: 100,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, CreatePeriodViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          if (vm.currentStep != CreatePeriodStep.formInput)
            Expanded(
              child: OutlinedButton(
                onPressed: vm.state == CreatePeriodState.submitting
                    ? null
                    : () => vm.prevStep(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Kembali"),
              ),
            ),
          if (vm.currentStep != CreatePeriodStep.formInput)
            const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: vm.state == CreatePeriodState.submitting
                  ? null
                  : () => _handleNextAction(context, vm),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: vm.state == CreatePeriodState.submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      vm.currentStep == CreatePeriodStep.review
                          ? (vm.isEditMode
                                ? "Update Periode"
                                : "Simpan Periode")
                          : "Lanjut",
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNextAction(
    BuildContext context,
    CreatePeriodViewModel vm,
  ) async {
    if (vm.currentStep == CreatePeriodStep.formInput) {
      if (vm.selectedYear == null || vm.selectedCycle == null) {
        showErrorDialog(
          context,
          "Harap pilih Tahun dan Siklus terlebih dahulu.",
        );
        return;
      }
    } else if (vm.currentStep == CreatePeriodStep.selectAssets &&
        vm.selectedAssetNumbers.isEmpty) {
      showErrorDialog(context, "Harap pilih minimal satu aset.");
      return;
    }

    if (vm.currentStep == CreatePeriodStep.review) {
      if (vm.isEditMode && !vm.hasChanges) {
        showErrorDialog(
          context,
          "Tidak ada perubahan data aset terdeteksi. Silakan tambah atau kurangi daftar aset untuk melakukan update.",
        );
        return;
      }

      showLoadingDialog(context);
      final success = await vm.submitPeriod();

      if (!context.mounted) return;
      Navigator.pop(context);

      if (success) {
        showSuccessDialog(
          context,
          vm.isEditMode
              ? "Periode berhasil diperbarui!"
              : "Periode berhasil dibuat!",
          () {
            Navigator.pop(context, true);
          },
        );
      } else {
        showErrorDialog(context, vm.errorMessage ?? "Gagal menyimpan.");
      }
    } else {
      vm.nextStep();
    }
  }
}
