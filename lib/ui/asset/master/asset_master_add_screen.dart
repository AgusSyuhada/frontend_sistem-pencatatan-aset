import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/helpers/permission_helper.dart';
import '../../common/app_dialogs.dart';
import '../widgets/asset_form_components.dart';
import '../../../data/models/response/lookup/team_model.dart';
import '../../../data/models/response/lookup/manufacturer_model.dart';
import '../../../data/models/response/lookup/condition_model.dart';
import '../../../data/models/response/lookup/location_model.dart';
import '../../../data/models/response/lookup/costcenter_model.dart';
import '../../../data/models/response/user/user.dart';

import 'asset_master_add_viewmodel.dart';

class AssetMasterAddScreen extends StatefulWidget {
  const AssetMasterAddScreen({super.key});

  @override
  State<AssetMasterAddScreen> createState() => _AssetMasterAddScreenState();
}

class _AssetMasterAddScreenState extends State<AssetMasterAddScreen> {
  final PermissionHelper _permissionHelper = PermissionHelper();
  late AssetMasterAddViewModel _vm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssetMasterAddViewModel>().initData();
      _checkLocationPermission();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm = context.read<AssetMasterAddViewModel>();
  }

  @override
  void dispose() {
    _vm.resetState();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    await _permissionHelper.requestNecessaryPermissions();
  }

  void _showPhotoSourceDialog(BuildContext context, String type) async {
    final vm = context.read<AssetMasterAddViewModel>();

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

  Future<void> _showNativeDatePicker(BuildContext context) async {
    final vm = context.read<AssetMasterAddViewModel>();
    DateTime initialDate = DateTime.now();
    try {
      if (vm.controllers['inventoryDate']!.text.isNotEmpty) {
        initialDate = DateFormat(
          "dd-MMM-yyyy",
          "en_US",
        ).parse(vm.controllers['inventoryDate']!.text);
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssetMasterAddViewModel>();
    final customFields = <String, Widget>{};

    TextStyle labelStyle = TextStyle(fontSize: 12, color: Colors.grey.shade600);
    final OutlineInputBorder localBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    customFields['Manufaktur'] = AsyncSearchableDropdown<ManufacturerModel>(
      label: "Manufaktur",
      hint: "Cari atau ketik baru...",
      controller: vm.controllers['manufacturer']!,
      futureRequest: (query) => vm.searchManufacturers(query),
      displayItem: (item) => item.manufacturerName,
      selectedItem: vm.selectedManufacturer,
      onSelected: (item) {
        vm.selectedManufacturer = item;
      },
      onCreateNew: (val) {
        vm.selectedManufacturer = null;
        vm.controllers['manufacturer']!.text = val;
      },
    );

    customFields['Nama Tim'] = AsyncSearchableDropdown<TeamModel>(
      label: "Nama Tim",
      hint: "Cari atau ketik tim baru...",
      controller: vm.controllers['team']!,
      futureRequest: (query) => vm.searchTeams(query),
      displayItem: (item) => item.teamName,
      onSelected: (item) => vm.selectedTeam = item,
      onCreateNew: (val) {
        vm.selectedTeam = null;
        vm.controllers['team']!.text = val;
      },
    );

    customFields['Cost Center'] = AsyncSearchableDropdown<CostCenterModel>(
      label: "Cost Center",
      hint: "Cari Cost Center...",
      controller: vm.controllers['costCenter']!,
      futureRequest: (query) => vm.searchCostCenters(query),
      displayItem: (item) => item.costCenterCode,
      onSelected: (item) => vm.selectedCostCenter = item,
      onCreateNew: (val) {
        vm.selectedCostCenter = null;
        vm.controllers['costCenter']!.text = val;
      },
    );

    customFields['Area'] = AsyncSearchableDropdown<String>(
      label: "Area",
      hint: "Masukkan Area",
      controller: vm.controllers['area']!,
      futureRequest: (query) => vm.searchAreas(query),
      displayItem: (item) => item,
      onSelected: (item) => vm.controllers['area']!.text = item,
      onCreateNew: (val) => vm.controllers['area']!.text = val,
    );

    customFields['Kode Lokasi SAP'] = AsyncSearchableDropdown<String>(
      label: "Kode Lokasi SAP",
      hint: "Masukkan Kode SAP",
      controller: vm.controllers['sapLocationCode']!,
      futureRequest: (query) => vm.searchSapCodes(query),
      displayItem: (item) => item,
      onSelected: (item) => vm.controllers['sapLocationCode']!.text = item,
      onCreateNew: (val) => vm.controllers['sapLocationCode']!.text = val,
    );

    customFields['Lokasi'] = AsyncSearchableDropdown<LocationModel>(
      label: "Lokasi",
      hint: "Cari Lokasi...",
      controller: vm.controllers['generalLocation']!,
      futureRequest: (query) => vm.searchGeneralLocations(query),
      displayItem: (item) => item.location ?? "",
      onSelected: (item) {
        vm.selectedLocation = item;
        vm.controllers['generalLocation']!.text = item.location ?? "";

        if (item.area != null && item.area!.isNotEmpty) {
          vm.controllers['area']!.text = item.area!;
        }
        if (item.sapLocationCode != null && item.sapLocationCode!.isNotEmpty) {
          vm.controllers['sapLocationCode']!.text = item.sapLocationCode!;
        }
      },
      onCreateNew: (val) {
        vm.selectedLocation = null;
        vm.controllers['generalLocation']!.text = val;
      },
    );

    customFields['Kondisi'] = AsyncSearchableDropdown<ConditionModel>(
      label: "Kondisi",
      hint: "Pilih Kondisi",
      controller: vm.controllers['condition']!,
      futureRequest: (query) => vm.searchConditions(query),
      displayItem: (item) => item.conditionName,
      onSelected: (item) => vm.selectedCondition = item,
      onCreateNew: (val) {
        vm.selectedCondition = null;
        vm.controllers['condition']!.text = val;
      },
    );

    customFields['Koordinat GPS'] = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Koordinat GPS", style: labelStyle),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: vm.controllers['gpsCoordinate'],
                readOnly: true,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: "Masukkan Koordinat GPS",
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
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => vm.getCurrentLocation(),
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
        ),
      ],
    );

    customFields['Tanggal Inventaris'] = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tanggal Inventaris", style: labelStyle),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: vm.controllers['inventoryDate'],
                readOnly: true,
                onTap: () => _showNativeDatePicker(context),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: "Masukkan Tanggal Inventaris",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: localBorder,
                  enabledBorder: localBorder,
                  focusedBorder: localBorder.copyWith(
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
            ),
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
        ),
      ],
    );

    customFields['Hasil Inventaris'] = AsyncSearchableDropdown<String>(
      label: "Hasil Inventaris",
      hint: "Pilih Hasil",
      controller: vm.controllers['inventoryResult']!,

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
      onSelected: (item) => vm.controllers['inventoryResult']!.text = item,
      onCreateNew: (val) => vm.controllers['inventoryResult']!.text = val,
    );

    customFields['PIC Tim Favorit'] = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("PIC Utama (Anda)", style: labelStyle),
        const SizedBox(height: 4),
        TextFormField(
          controller: vm.controllers['picTeamFav'],
          readOnly: true,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
          decoration: InputDecoration(
            hintText: "Memuat PIC...",
            filled: true,
            fillColor: Colors.grey.shade200,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: localBorder,
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
                      onSelected: (user) {
                        vm.updatePicSlot(index, user);
                      },
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              "Maksimal 5 PIC tercapai.",
              style: TextStyle(
                color: Colors.orange,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Tambah Aset Baru",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: AssetFormBody(
        isReadOnly: false,
        controllers: vm.controllers,
        customFields: customFields,
        photoCodeFile: vm.photoCodeFile,
        photoAssetFile: vm.photoAssetFile,
        photoLocationFile: vm.photoLocationFile,
        onPickPhoto: (type) => _showPhotoSourceDialog(context, type),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _handleSave(context),
          child: const Text(
            "SIMPAN ASET",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _handleSave(BuildContext context) async {
    final vm = context.read<AssetMasterAddViewModel>();
    showLoadingDialog(context);
    final success = await vm.submitAsset();

    if (context.mounted) Navigator.pop(context);

    if (success && context.mounted) {
      showSuccessDialog(context, "Aset berhasil disimpan.", () {
        Navigator.pop(context, true);
      });
    } else if (vm.errorMessage != null && context.mounted) {
      showErrorDialog(context, vm.errorMessage ?? "Terjadi kesalahan.");
    }
  }
}
