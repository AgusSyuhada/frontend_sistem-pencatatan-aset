import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'asset_master_detail_viewmodel.dart';
import '../../../data/models/response/asset_master/asset_model.dart';
import '../../../data/models/response/user/user.dart';
import '../../../data/models/response/lookup/manufacturer_model.dart';
import '../../../data/models/response/lookup/team_model.dart';
import '../../../data/models/response/lookup/costcenter_model.dart';
import '../../../data/models/response/lookup/location_model.dart';
import '../../../data/models/response/lookup/condition_model.dart';
import '../widgets/asset_form_components.dart';
import '../../common/app_dialogs.dart';

class AssetMasterDetailScreen extends StatefulWidget {
  const AssetMasterDetailScreen({super.key});

  @override
  State<AssetMasterDetailScreen> createState() =>
      _AssetMasterDetailScreenState();
}

class _AssetMasterDetailScreenState extends State<AssetMasterDetailScreen> {
  String? assetNumber;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && assetNumber == null) {
      assetNumber = args;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<AssetMasterDetailViewModel>(
          context,
          listen: false,
        ).fetchAssetByNumber(assetNumber!);
      });
    }
  }

  TextEditingController _ctrl(String? text) =>
      TextEditingController(text: text ?? "");

  Widget _buildStaticField({required String value, String hint = "-"}) {
    return TextFormField(
      controller: _ctrl(value),
      readOnly: true,
      enableInteractiveSelection: false,
      canRequestFocus: false,
      mouseCursor: SystemMouseCursors.basic,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Future<void> _showNativeDatePicker(BuildContext context) async {
    final vm = context.read<AssetMasterDetailViewModel>();
    DateTime initialDate = DateTime.now();
    try {
      if (vm.editControllers['inventoryDate']!.text.isNotEmpty) {
        initialDate = DateFormat(
          "dd-MMM-yyyy",
          "en_US",
        ).parse(vm.editControllers['inventoryDate']!.text);
      }
    } catch (_) {}

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.calendar,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
              surface: Colors.white,
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      vm.setInventoryDate(picked);
    }
  }

  Map<String, Widget> _buildCustomFields(
    AssetModel asset,
    bool isEditing,
    AssetMasterDetailViewModel vm,
  ) {
    final Map<String, Widget> fields = {};
    TextStyle labelStyle = TextStyle(fontSize: 12, color: Colors.grey.shade600);

    TextEditingController getCtrl(String key, String? staticVal) {
      return isEditing ? vm.editControllers[key]! : _ctrl(staticVal);
    }

    fields['Manufaktur'] = AsyncSearchableDropdown<ManufacturerModel>(
      label: "Manufaktur",
      hint: isEditing
          ? (vm.isAdmin ? "Cari atau buat baru..." : "Cari...")
          : "",
      controller: getCtrl('manufacturer', asset.manufacturerName),

      readOnly: !isEditing || !vm.isAdmin,
      futureRequest: (q) => vm.searchManufacturers(q),
      displayItem: (item) => item.manufacturerName,
      onSelected: (item) => vm.selectedManufacturer = item,

      onCreateNew: vm.isAdmin ? (val) => vm.setManufacturerText(val) : null,
    );

    fields['Nama Tim'] = AsyncSearchableDropdown<TeamModel>(
      label: "Nama Tim",
      hint: isEditing
          ? (vm.isAdmin ? "Cari atau buat baru..." : "Cari...")
          : "",
      controller: getCtrl('team', asset.teamName),
      readOnly: !isEditing || !vm.isAdmin,
      futureRequest: (q) => vm.searchTeams(q),
      displayItem: (item) => item.teamName,
      onSelected: (item) => vm.selectedTeam = item,
      onCreateNew: vm.isAdmin ? (val) => vm.setTeamText(val) : null,
    );

    fields['Cost Center'] = AsyncSearchableDropdown<CostCenterModel>(
      label: "Cost Center",
      hint: isEditing ? (vm.isAdmin ? "Cari Cost Center..." : "Cari...") : "",
      controller: getCtrl('costCenter', asset.costCenter),
      readOnly: !isEditing || !vm.isAdmin,
      futureRequest: (q) => vm.searchCostCenters(q),
      displayItem: (item) => item.costCenterCode,
      onSelected: (item) => vm.selectedCostCenter = item,
      onCreateNew: vm.isAdmin ? (val) => vm.setCostCenterText(val) : null,
    );

    fields['Area'] = AsyncSearchableDropdown<String>(
      label: "Area",
      hint: isEditing ? "Masukkan Area" : "",
      controller: getCtrl('area', asset.area),
      readOnly: !isEditing,
      futureRequest: (q) => vm.searchAreas(q),
      displayItem: (item) => item,
      onSelected: (item) => vm.setAreaText(item),
      onCreateNew: (val) => vm.setAreaText(val),
    );

    fields['Kode Lokasi SAP'] = AsyncSearchableDropdown<String>(
      label: "Kode Lokasi SAP",
      hint: isEditing ? "Masukkan Kode SAP" : "",
      controller: getCtrl('sapLocationCode', asset.sapLocationCode),
      readOnly: !isEditing,
      futureRequest: (q) => vm.searchSapCodes(q),
      displayItem: (item) => item,
      onSelected: (item) => vm.setSapText(item),
      onCreateNew: (val) => vm.setSapText(val),
    );

    fields['Lokasi'] = AsyncSearchableDropdown<LocationModel>(
      label: "Lokasi",
      hint: isEditing ? "Cari Lokasi..." : "",
      controller: getCtrl('generalLocation', asset.locationName),
      readOnly: !isEditing,
      futureRequest: (q) => vm.searchGeneralLocations(q),
      displayItem: (item) => item.location ?? "",
      onSelected: (item) {
        vm.selectedLocation = item;
        vm.editControllers['generalLocation']!.text = item.location ?? "";
        if (item.area != null && item.area!.isNotEmpty) {
          vm.editControllers['area']!.text = item.area!;
        }
        if (item.sapLocationCode != null && item.sapLocationCode!.isNotEmpty) {
          vm.editControllers['sapLocationCode']!.text = item.sapLocationCode!;
        }
      },
      onCreateNew: (val) => vm.setLocationText(val),
    );

    fields['Kondisi'] = AsyncSearchableDropdown<ConditionModel>(
      label: "Kondisi",
      hint: isEditing ? "Pilih Kondisi" : "",
      controller: getCtrl('condition', asset.conditionName),
      readOnly: !isEditing,
      futureRequest: (q) => vm.searchConditions(q),
      displayItem: (item) => item.conditionName,
      onSelected: (item) => vm.selectedCondition = item,
    );

    fields['Koordinat GPS'] = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Koordinat GPS", style: labelStyle),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: isEditing
                  ? TextFormField(
                      controller: vm.editControllers['gpsCoordinate'],
                      readOnly: true,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Koordinat GPS",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    )
                  : _buildStaticField(value: asset.gpsCoordinate ?? ""),
            ),
            if (isEditing) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  await vm.getCurrentLocation();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
              ),
            ],
          ],
        ),
      ],
    );

    String formattedDate = asset.inventoryDate ?? "-";
    if (asset.inventoryDate != null && asset.inventoryDate!.isNotEmpty) {
      try {
        formattedDate = DateFormat(
          "dd-MMM-yyyy",
          "en_US",
        ).format(DateTime.parse(asset.inventoryDate!));
      } catch (_) {
        formattedDate = asset.inventoryDate!;
      }
    }

    final OutlineInputBorder localBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    fields['Tanggal Inventaris'] = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tanggal Inventaris", style: labelStyle),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: isEditing
                  ? TextFormField(
                      controller: vm.editControllers['inventoryDate'],

                      readOnly: true,
                      onTap: vm.isAdmin
                          ? () => _showNativeDatePicker(context)
                          : null,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Masukkan Tanggal Inventaris",
                        filled: true,

                        fillColor: vm.isAdmin
                            ? Colors.white
                            : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: localBorder,
                        enabledBorder: localBorder,
                        focusedBorder: localBorder.copyWith(
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                    )
                  : _buildStaticField(value: formattedDate),
            ),
            if (isEditing && vm.isAdmin) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => vm.setTodayDate(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Icon(Icons.today, color: Colors.blue),
                ),
              ),
            ],
          ],
        ),
      ],
    );

    fields['Hasil Inventaris'] = AsyncSearchableDropdown<String>(
      label: "Hasil Inventaris",
      hint: isEditing ? "Pilih Hasil" : "",
      controller: getCtrl('inventoryResult', asset.inventoryResult),
      readOnly: !isEditing,
      futureRequest: (query) async {
        const List<String> options = [
          "Match",
          "Different Location",
          "Not Found",
        ];
        if (query.isEmpty) return options;
        return options
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      },
      displayItem: (item) => item,
      onCreateNew: (val) => vm.editControllers['inventoryResult']!.text = val,
    );

    if (isEditing) {
      fields['PIC Tim Favorit'] = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("PIC Utama (Anda)", style: labelStyle),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: vm.user?.user.name ?? "User",
            readOnly: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade200,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: const Icon(Icons.lock, size: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),
          if (vm.additionalPics.isNotEmpty)
            ...List.generate(vm.additionalPics.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: AsyncSearchableDropdown<User>(
                        label: "PIC Tambahan ${index + 1}",
                        hint: "Cari PIC...",
                        controller: vm.additionalPicControllers[index],
                        futureRequest: (query) => vm.searchUsers(query),
                        displayItem: (user) => user.name,
                        onSelected: (user) => vm.updatePicSlot(index, user),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => vm.removePicSlot(index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          if (vm.getTotalPics() < 5)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => vm.addPicSlot(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Tambah Anggota Tim"),
                ),
              ),
            ),
        ],
      );
    }

    return fields;
  }

  void _handleSave(BuildContext context) async {
    final vm = context.read<AssetMasterDetailViewModel>();
    showLoadingDialog(context);
    final success = await vm.saveAssetChanges();

    if (context.mounted) Navigator.pop(context);

    if (success && context.mounted) {
      showSuccessDialog(context, "Aset berhasil diperbarui.", () {
        setState(() => _isEditing = false);
        vm.fetchAssetByNumber(vm.selectedAsset!.assetNumber);
      });
    } else if (vm.errorMessage != null && context.mounted) {
      showErrorDialog(context, vm.errorMessage!);
    }
  }

  void _handleDeactivate(BuildContext context, AssetModel asset) {
    final vm = Provider.of<AssetMasterDetailViewModel>(context, listen: false);

    showConfirmationDialog(
      context,
      "Hapus Akses Aset?",
      "Anda akan menonaktifkan aset ${asset.assetName} (${asset.assetNumber}). \n\n"
          "Data aset ini akan hilang dari daftar aktif. Lanjutkan?",
      () async {
        showLoadingDialog(context);
        final message = await vm.deactivateAsset(asset.assetNumber);
        if (context.mounted) {
          Navigator.pop(context);
          if (message != null) {
            showSuccessDialog(context, message, () => Navigator.pop(context));
          } else {
            showErrorDialog(
              context,
              vm.errorMessage ?? "Gagal menonaktifkan aset.",
            );
          }
        }
      },
    );
  }

  void _showPhotoSourceDialog(BuildContext context, String type) async {
    final vm = context.read<AssetMasterDetailViewModel>();

    if (Platform.isWindows) {
      await vm.pickImage(type, ImageSource.gallery);

      if (context.mounted && vm.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    showSelectionActionDialog(
      context: context,
      title: "Pilih Sumber Foto",
      actions: [
        DialogActionItem(
          id: 'camera',
          label: 'Kamera',
          icon: Icons.camera_alt,
          color: Colors.blue,
        ),
        DialogActionItem(
          id: 'gallery',
          label: 'Galeri',
          icon: Icons.photo_library,
          color: Colors.orange,
        ),
      ],
      onSelected: (actionId) async {
        if (actionId == 'camera') {
          await vm.pickImage(type, ImageSource.camera);
        } else if (actionId == 'gallery') {
          await vm.pickImage(type, ImageSource.gallery);
        }

        if (context.mounted && vm.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(vm.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  Widget _buildStatusBanner(Map<String, dynamic>? info) {
    if (info == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,

      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: info['color'],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: info['borderColor']),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(info['icon'], color: info['iconColor'], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              info['message'],
              style: TextStyle(
                color: info['textColor'],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Aset',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            ),
        ],
      ),
      body: Consumer<AssetMasterDetailViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.state == AssetMasterDetailState.loading &&
              viewModel.selectedAsset == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.state == AssetMasterDetailState.error &&
              viewModel.selectedAsset == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      viewModel.errorMessage ?? 'Terjadi kesalahan',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          viewModel.fetchAssetByNumber(assetNumber!),
                      child: const Text("Coba Lagi"),
                    ),
                  ],
                ),
              ),
            );
          }

          Map<String, Widget>? customFields;
          if (viewModel.selectedAsset != null) {
            customFields = _buildCustomFields(
              viewModel.selectedAsset!,
              _isEditing,
              viewModel,
            );
          }

          return Column(
            children: [
              _buildStatusBanner(viewModel.statusInfo),

              Expanded(
                child: AssetFormBody(
                  asset: viewModel.selectedAsset,
                  isReadOnly: !_isEditing,
                  customFields: customFields,

                  canEditMasterInfo: viewModel.canEditMasterInfo,

                  photoCodeFile: viewModel.photoCodeFile,
                  photoAssetFile: viewModel.photoAssetFile,
                  photoLocationFile: viewModel.photoLocationFile,
                  onPickPhoto: (type) => _showPhotoSourceDialog(context, type),
                ),
              ),

              if (viewModel.selectedAsset != null && viewModel.canEditAsset)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: _isEditing
                      ? Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => _isEditing = false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text("Batal"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _handleSave(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text("Simpan"),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            if (viewModel.isAdmin) ...[
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                  ),
                                  label: const Text("Nonaktifkan"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => _handleDeactivate(
                                    context,
                                    viewModel.selectedAsset!,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text("Edit Asset"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  viewModel.initEditMode();
                                  setState(() => _isEditing = true);
                                },
                              ),
                            ),
                          ],
                        ),
                ),
            ],
          );
        },
      ),
    );
  }
}
