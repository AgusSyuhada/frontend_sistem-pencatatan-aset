import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'asset_cycle_detail_viewmodel.dart';
import '../../../data/models/response/asset_cycle/asset_cycle_model.dart';
import '../../../data/models/response/lookup/condition_model.dart';
import '../../../data/models/response/lookup/location_model.dart';
import '../../../data/models/response/user/user.dart';
import '../widgets/asset_form_components.dart';
import '../../common/app_dialogs.dart';

class AssetCycleDetailArguments {
  final int year;
  final int cycle;
  final String assetNumber;
  final bool startEditing;

  AssetCycleDetailArguments({
    required this.year,
    required this.cycle,
    required this.assetNumber,
    this.startEditing = false,
  });
}

class AssetCycleDetailScreen extends StatefulWidget {
  static const routeName = '/asset-cycle-detail';

  const AssetCycleDetailScreen({super.key});

  @override
  State<AssetCycleDetailScreen> createState() => _AssetCycleDetailScreenState();
}

class _AssetCycleDetailScreenState extends State<AssetCycleDetailScreen> {
  bool _isInit = true;
  late int _year;
  late int _cycle;
  late String _assetNumber;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is AssetCycleDetailArguments) {
        _year = args.year;
        _cycle = args.cycle;
        _assetNumber = args.assetNumber;

        final vm = Provider.of<AssetCycleDetailViewModel>(
          context,
          listen: false,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.fetchAssetDetail(_year, _cycle, _assetNumber).then((_) {
            if (args.startEditing && vm.canEdit) {
              vm.initEditMode();
              setState(() {
                _isEditing = true;
              });
            }
          });
        });
      }
      _isInit = false;
    }
  }

  String _formatCurrency(num? value) {
    if (value == null) return '-';
    try {
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 2,
      ).format(value);
    } catch (_) {
      return value.toString();
    }
  }

  void _showPhotoSourceDialog(BuildContext context, String type) async {
    final vm = context.read<AssetCycleDetailViewModel>();

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

  void _onSavePressed(BuildContext context) async {
    final vm = context.read<AssetCycleDetailViewModel>();

    if (vm.editControllers['inventoryResult']!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap isi 'Hasil Inventaris' terlebih dahulu."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showLoadingDialog(context);

    final success = await vm.saveAsset(_year, _cycle);

    if (context.mounted) {
      Navigator.pop(context);

      if (success) {
        showSuccessDialog(context, "Data siklus berhasil disimpan!", () {
          setState(() {
            _isEditing = false;
          });
          vm.fetchAssetDetail(_year, _cycle, _assetNumber);
        });
      } else {
        showErrorDialog(
          context,
          vm.errorMessage ?? "Terjadi kesalahan saat menyimpan data.",
        );
      }
    }
  }

  void _onDeletePressed(BuildContext context) {
    final vm = Provider.of<AssetCycleDetailViewModel>(context, listen: false);

    showConfirmationDialog(
      context,
      "Hapus dari Siklus?",
      "Anda yakin ingin menghapus aset $_assetNumber dari periode siklus ini? Data akan hilang dari laporan siklus ini, tetapi Master Data aman.",
      () async {
        showLoadingDialog(context);
        final msg = await vm.deleteAsset(_year, _cycle, _assetNumber);

        if (context.mounted) {
          Navigator.pop(context);

          if (msg != null) {
            showSuccessDialog(context, msg, () {
              Navigator.pop(context, true);
            });
          } else {
            showErrorDialog(
              context,
              vm.errorMessage ?? "Gagal menghapus aset.",
            );
          }
        }
      },
    );
  }

  Widget _buildStatusBanner(Map<String, dynamic>? info) {
    if (info == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
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

  Widget _buildStaticField({required String value, String hint = "-"}) {
    return TextFormField(
      controller: TextEditingController(text: value),
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
      ),
    );
  }

  Map<String, Widget> _buildEditableFields(
    AssetCycleModel asset,
    AssetCycleDetailViewModel vm,
  ) {
    final Map<String, Widget> fields = {};
    TextStyle labelStyle = TextStyle(fontSize: 12, color: Colors.grey.shade600);

    TextEditingController getCtrl(String key) => vm.editControllers[key]!;

    fields['Kondisi'] = AsyncSearchableDropdown<ConditionModel>(
      label: "Kondisi",
      hint: _isEditing ? "Pilih Kondisi" : "",
      controller: getCtrl('condition'),
      readOnly: !_isEditing,
      futureRequest: (q) => vm.searchConditions(q),
      displayItem: (item) => item.conditionName,
      onSelected: (item) => vm.selectedCondition = item,
    );

    fields['Kode Lokasi SAP'] = AsyncSearchableDropdown<String>(
      label: "Kode Lokasi SAP",
      hint: _isEditing ? "Masukkan Kode SAP" : "",
      controller: getCtrl('sapLocationCode'),
      readOnly: !_isEditing,
      futureRequest: (q) => vm.searchSapCodes(q),
      displayItem: (item) => item,
      onSelected: (item) => vm.setSapText(item),
      onCreateNew: (val) => vm.setSapText(val),
    );

    fields['Area'] = AsyncSearchableDropdown<String>(
      label: "Area",
      hint: _isEditing ? "Masukkan Area" : "",
      controller: getCtrl('area'),
      readOnly: !_isEditing,
      futureRequest: (q) => vm.searchAreas(q),
      displayItem: (item) => item,
      onSelected: (item) => vm.setAreaText(item),
      onCreateNew: (val) => vm.setAreaText(val),
    );

    fields['Lokasi'] = AsyncSearchableDropdown<LocationModel>(
      label: "Lokasi",
      hint: _isEditing ? "Cari Lokasi..." : "",
      controller: getCtrl('generalLocation'),
      readOnly: !_isEditing,
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

    fields['Koordinat GPS'] = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Koordinat GPS", style: labelStyle),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _isEditing
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
            if (_isEditing) ...[
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

    fields['Hasil Inventaris'] = AsyncSearchableDropdown<String>(
      label: "Hasil Inventaris",
      hint: _isEditing ? "Pilih Hasil" : "",
      controller: getCtrl('inventoryResult'),
      readOnly: !_isEditing,
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

    if (_isEditing) {
      fields['PIC Tim Favorit'] = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("PIC Utama (Anda)", style: labelStyle),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: vm.user?.user.name ?? "Loading...",
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
    } else {
      fields['PIC Tim Favorit'] = AssetInfoField(
        label: "PIC Tim Favorit",
        value: asset.picTeamFav,
        isReadOnly: true,
      );
    }

    return fields;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Detail Aset Siklus",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                final vm = Provider.of<AssetCycleDetailViewModel>(
                  context,
                  listen: false,
                );
                setState(() {
                  _isEditing = false;
                });
                vm.initEditMode();
              },
            ),
        ],
      ),
      body: Consumer<AssetCycleDetailViewModel>(
        builder: (context, vm, child) {
          if (vm.state == AssetCycleDetailState.loading &&
              vm.selectedAsset == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.state == AssetCycleDetailState.error &&
              vm.selectedAsset == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    vm.errorMessage ?? "Gagal memuat data",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        vm.fetchAssetDetail(_year, _cycle, _assetNumber),
                    child: const Text("Coba Lagi"),
                  ),
                ],
              ),
            );
          }

          final asset = vm.selectedAsset;
          if (asset == null) return const SizedBox.shrink();

          final customFields = _buildEditableFields(asset, vm);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusBanner(vm.statusBannerInfo),

                      AssetPhotoSection(
                        assetCodePhoto: asset.assetCodePhoto,
                        assetPhoto: asset.assetPhoto,
                        assetLocationPhoto: asset.assetLocationPhoto,
                        localCodePhoto: vm.photoCodeFile,
                        localAssetPhoto: vm.photoAssetFile,
                        localLocationPhoto: vm.photoLocationFile,
                        isReadOnly: !_isEditing,
                        onPickPhoto: _isEditing
                            ? (type) => _showPhotoSourceDialog(context, type)
                            : null,
                      ),

                      const SizedBox(height: 24),

                      AssetInfoField(
                        label: "Nomor Aset",
                        value: asset.assetNumber,
                        isReadOnly: true,
                      ),

                      AssetInfoField(
                        label: "Nama Aset",
                        value: asset.assetName,
                        isReadOnly: true,
                      ),

                      AssetInfoField(
                        label: "HBM",
                        value: asset.hbm,
                        isReadOnly: true,
                      ),

                      AssetInfoField(
                        label: "Serial Number",
                        value: asset.serialNumber,
                        isReadOnly: true,
                      ),

                      AssetInfoField(
                        label: "Tipe Model",
                        value: asset.modelType,
                        isReadOnly: true,
                      ),

                      AssetInfoField(
                        label: "Manufaktur",
                        value: asset.manufacturerName,
                        isReadOnly: true,
                      ),

                      const SizedBox(height: 12),
                      customFields['Kondisi'] ?? const SizedBox(),
                      const SizedBox(height: 12),

                      AssetInfoField(
                        label: "Nilai Aset",
                        value: _formatCurrency(asset.assetValue),
                        isReadOnly: true,
                      ),

                      AssetInfoField(
                        label: "Cost Center",
                        value: asset.costCenter,
                        isReadOnly: true,
                      ),

                      AssetInfoField(
                        label: "Nama Tim",
                        value: asset.teamName,
                        isReadOnly: true,
                      ),

                      const SizedBox(height: 12),
                      customFields['Kode Lokasi SAP'] ?? const SizedBox(),

                      const SizedBox(height: 12),
                      customFields['Area'] ?? const SizedBox(),

                      const SizedBox(height: 12),
                      customFields['Lokasi'] ?? const SizedBox(),

                      const SizedBox(height: 12),
                      AssetInfoField(
                        label: "Lokasi Spesifik",
                        controller: vm.editControllers['specificLocation'],
                        isReadOnly: !_isEditing,
                      ),

                      const SizedBox(height: 12),
                      customFields['Koordinat GPS'] ?? const SizedBox(),

                      const SizedBox(height: 12),
                      customFields['Hasil Inventaris'] ?? const SizedBox(),

                      const SizedBox(height: 12),
                      AssetInfoField(
                        label: "Tanggal Inventaris",
                        value: vm.editControllers['inventoryDate']?.text ?? "-",
                        isReadOnly: true,
                      ),

                      const SizedBox(height: 12),
                      customFields['PIC Tim Favorit'] ?? const SizedBox(),

                      const SizedBox(height: 12),
                      AssetInfoField(
                        label: "Deskripsi",
                        controller: vm.editControllers['description'],
                        maxLines: 4,
                        isReadOnly: !_isEditing,
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              if (vm.canEdit)
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
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                  });
                                  vm.initEditMode();
                                },
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
                                onPressed: () => _onSavePressed(context),
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
                            if (vm.isAdmin) ...[
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                  ),
                                  label: const Text("Hapus dari Siklus"),
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
                                  onPressed: () => _onDeletePressed(context),
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
                                  vm.initEditMode();
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
