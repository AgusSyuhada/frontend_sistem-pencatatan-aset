import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../data/models/response/asset_master/asset_model.dart';

class AsyncSearchableDropdown<T> extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final Future<List<T>> Function(String query) futureRequest;
  final String Function(T item) displayItem;
  final Function(T item)? onSelected;
  final Function(String val)? onCreateNew;
  final T? selectedItem;
  final bool readOnly;

  const AsyncSearchableDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.futureRequest,
    required this.displayItem,
    this.onSelected,
    this.onCreateNew,
    this.selectedItem,
    this.readOnly = false,
  });

  @override
  State<AsyncSearchableDropdown<T>> createState() =>
      _AsyncSearchableDropdownState<T>();
}

class _AsyncSearchableDropdownState<T>
    extends State<AsyncSearchableDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  bool _isLoading = false;
  List<T> _options = [];
  bool _hasSearched = false;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    if (widget.readOnly) {
      _focusNode.canRequestFocus = false;
    }

    _focusNode.addListener(() {
      if (widget.readOnly) return;

      if (_focusNode.hasFocus) {
        _onSearchChanged(widget.controller.text, isInit: true);
        _showOverlay();
      } else {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_focusNode.hasFocus) {
            _removeOverlay();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query, {bool isInit = false}) {
    if (widget.readOnly) return;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final duration = isInit ? Duration.zero : const Duration(milliseconds: 500);

    _debounce = Timer(duration, () async {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _hasSearched = true;
      });
      _updateOverlay();

      try {
        final result = await widget.futureRequest(query);

        if (!mounted) return;
        setState(() {
          _options = result;
          _isLoading = false;
        });
        _updateOverlay();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _options = [];
          _isLoading = false;
        });
        _updateOverlay();
      }
    });
  }

  void _showOverlay() {
    if (widget.readOnly) return;
    if (_overlayEntry != null) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, size.height + 5.0),
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: _buildOverlayContent(),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildOverlayContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_options.isEmpty && _hasSearched) {
      if (widget.controller.text.isNotEmpty && widget.onCreateNew != null) {
        return InkWell(
          onTap: () {
            widget.onCreateNew?.call(widget.controller.text);
            _focusNode.unfocus();
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "(+) Buat \"${widget.controller.text}\"",
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Data tidak ditemukan.",
            style: TextStyle(color: Colors.grey),
          ),
        );
      }
    }

    if (_options.isEmpty && !_hasSearched) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _options.length,
      itemBuilder: (context, index) {
        final item = _options[index];
        return ListTile(
          title: Text(widget.displayItem(item)),
          onTap: () {
            widget.controller.text = widget.displayItem(item);
            widget.onSelected?.call(item);
            _focusNode.unfocus();
          },
        );
      },
    );
  }

  void _updateOverlay() {
    if (_overlayEntry != null && mounted) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder commonBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    final OutlineInputBorder readOnlyFocusedBorder = commonBorder;
    final OutlineInputBorder editFocusedBorder = commonBorder.copyWith(
      borderSide: const BorderSide(color: Colors.blue, width: 2),
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: (val) => _onSearchChanged(val),
              readOnly: widget.readOnly,
              enableInteractiveSelection: !widget.readOnly,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: widget.readOnly ? null : widget.hint,
                filled: true,
                fillColor: widget.readOnly
                    ? Colors.grey.shade100
                    : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (widget.readOnly
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                widget.controller.clear();
                                _onSearchChanged("", isInit: true);
                                _focusNode.requestFocus();
                              },
                            )),
                border: commonBorder,
                enabledBorder: commonBorder,
                disabledBorder: commonBorder,
                focusedBorder: widget.readOnly
                    ? readOnlyFocusedBorder
                    : editFocusedBorder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AssetFormBody extends StatelessWidget {
  final AssetModel? asset;
  final bool isReadOnly;
  final bool canEditMasterInfo;
  final Map<String, TextEditingController>? controllers;
  final File? photoCodeFile;
  final File? photoAssetFile;
  final File? photoLocationFile;
  final Function(String type)? onPickPhoto;

  final Map<String, Widget>? customFields;

  const AssetFormBody({
    super.key,
    this.asset,
    this.isReadOnly = true,
    this.canEditMasterInfo = false,
    this.controllers,
    this.customFields,
    this.photoCodeFile,
    this.photoAssetFile,
    this.photoLocationFile,
    this.onPickPhoto,
  });

  String _tryFormatDate(String? date) {
    if (date == null || date.isEmpty) return '-';
    try {
      return DateFormat('dd-MMM-yyyy').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (asset == null && isReadOnly) {
      return const Center(child: Text("Data aset tidak tersedia."));
    }

    final bool masterReadOnly = isReadOnly || !canEditMasterInfo;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssetPhotoSection(
            assetCodePhoto: asset?.assetCodePhoto,
            assetPhoto: asset?.assetPhoto,
            assetLocationPhoto: asset?.assetLocationPhoto,
            localCodePhoto: photoCodeFile,
            localAssetPhoto: photoAssetFile,
            localLocationPhoto: photoLocationFile,
            isReadOnly: isReadOnly,
            onPickPhoto: onPickPhoto,
          ),

          const SizedBox(height: 24),

          _buildField(
            label: 'Nomor Aset',
            key: 'assetNumber',
            value: asset?.assetNumber,
            isReadOnlyOverride: true,
          ),

          _buildField(
            label: 'Nama Aset',
            key: 'assetName',
            value: asset?.assetName,
            isReadOnlyOverride: masterReadOnly,
          ),
          _buildField(
            label: 'HBM',
            key: 'hbm',
            value: asset?.hbm,
            isReadOnlyOverride: masterReadOnly,
          ),
          _buildField(
            label: 'Serial Number',
            key: 'serialNumber',
            value: asset?.serialNumber,
            isReadOnlyOverride: masterReadOnly,
          ),
          _buildField(
            label: 'Tipe Model',
            key: 'modelType',
            value: asset?.modelType,
            isReadOnlyOverride: masterReadOnly,
          ),

          _buildCustomOrStandardField(
            'Manufaktur',
            'manufacturer',
            asset?.manufacturerName,
          ),
          _buildCustomOrStandardField(
            'Kondisi',
            'condition',
            asset?.conditionName,
          ),

          _buildField(
            label: 'Nilai Aset',
            key: 'assetValue',
            value: asset?.assetValue != null
                ? 'Rp ${NumberFormat('#,##0.00', 'id_ID').format(asset!.assetValue)}'
                : '-',
            isReadOnlyOverride: masterReadOnly,
          ),

          _buildCustomOrStandardField(
            'Cost Center',
            'costCenter',
            asset?.costCenter,
          ),
          _buildCustomOrStandardField('Nama Tim', 'team', asset?.teamName),
          _buildCustomOrStandardField(
            'Kode Lokasi SAP',
            'sapLocationCode',
            asset?.sapLocationCode,
          ),
          _buildCustomOrStandardField('Area', 'area', asset?.area),
          _buildCustomOrStandardField(
            'Lokasi',
            'location',
            asset?.locationName,
          ),

          _buildField(
            label: 'Lokasi Spesifik',
            key: 'specificLocation',
            value: asset?.specificLocation,
            isCustom: true,
          ),

          _buildCustomOrStandardField(
            'Koordinat GPS',
            'gpsCoordinate',
            asset?.gpsCoordinate,
          ),

          _buildField(
            label: 'Hasil Inventaris',
            key: 'inventoryResult',
            value: asset?.inventoryResult,
            isCustom: true,
          ),

          _buildCustomOrStandardField(
            'Tanggal Inventaris',
            'inventoryDate',
            _tryFormatDate(asset?.inventoryDate),
          ),
          _buildCustomOrStandardField(
            'PIC Tim Favorit',
            'picTeamFav',
            asset?.picTeamFav,
          ),

          _buildField(
            label: 'Deskripsi',
            key: 'description',
            value: asset?.description,
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomOrStandardField(String label, String key, String? value) {
    if (customFields != null && customFields!.containsKey(label)) {
      return customFields![label]!;
    }
    return _buildField(label: label, key: key, value: value);
  }

  Widget _buildField({
    required String label,
    required String key,
    String? value,
    int maxLines = 1,
    bool isCustom = false,
    bool? isReadOnlyOverride,
  }) {
    if (customFields != null && customFields!.containsKey(label)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.0),
        child: customFields![label]!,
      );
    }

    return AssetInfoField(
      label: label,
      value: value,
      controller: controllers?[key],
      isReadOnly: isReadOnlyOverride ?? isReadOnly,
      maxLines: maxLines,
    );
  }
}

class AssetInfoField extends StatelessWidget {
  final String label;
  final String? value;
  final int maxLines;
  final bool isReadOnly;
  final TextEditingController? controller;

  const AssetInfoField({
    super.key,
    required this.label,
    this.value,
    this.maxLines = 1,
    this.isReadOnly = true,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder commonBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    final OutlineInputBorder readOnlyFocusedBorder = commonBorder;
    final OutlineInputBorder editFocusedBorder = commonBorder.copyWith(
      borderSide: const BorderSide(color: Colors.blue, width: 2),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            initialValue: controller == null
                ? ((value == null || value!.trim().isEmpty)
                      ? (isReadOnly ? '-' : '')
                      : value)
                : null,
            readOnly: isReadOnly,
            enabled: !isReadOnly,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              hintText: !isReadOnly ? "Masukkan $label" : null,
              filled: true,
              fillColor: isReadOnly ? Colors.grey.shade100 : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: commonBorder,
              enabledBorder: commonBorder,
              disabledBorder: commonBorder,
              focusedBorder: isReadOnly
                  ? readOnlyFocusedBorder
                  : editFocusedBorder,
            ),
          ),
        ],
      ),
    );
  }
}

class AssetPhotoSection extends StatelessWidget {
  final String? assetCodePhoto;
  final String? assetPhoto;
  final String? assetLocationPhoto;

  final File? localCodePhoto;
  final File? localAssetPhoto;
  final File? localLocationPhoto;

  final bool isReadOnly;
  final Function(String type)? onPickPhoto;

  const AssetPhotoSection({
    super.key,
    this.assetCodePhoto,
    this.assetPhoto,
    this.assetLocationPhoto,
    this.localCodePhoto,
    this.localAssetPhoto,
    this.localLocationPhoto,
    this.isReadOnly = true,
    this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildPhotoCard(
            context,
            'Foto Kode',
            'code',
            assetCodePhoto,
            localCodePhoto,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPhotoCard(
            context,
            'Foto Aset',
            'asset',
            assetPhoto,
            localAssetPhoto,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPhotoCard(
            context,
            'Foto Lokasi',
            'location',
            assetLocationPhoto,
            localLocationPhoto,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoCard(
    BuildContext context,
    String title,
    String type,
    String? imageUrl,
    File? localFile,
  ) {
    final bool hasLocal = localFile != null;
    final bool hasUrl =
        imageUrl != null &&
        imageUrl.isNotEmpty &&
        Uri.tryParse(imageUrl)?.hasAbsolutePath == true;
    final bool hasImage = hasLocal || hasUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        AspectRatio(
          aspectRatio: 1.0,
          child: Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Colors.grey[200],
                  child: _buildImageContent(
                    hasLocal,
                    localFile,
                    hasUrl,
                    imageUrl,
                  ),
                ),

                if (!isReadOnly)
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (onPickPhoto != null) {
                          onPickPhoto!(type);
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                if (hasImage)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        _showImagePopup(
                          context,
                          imageUrl: imageUrl,
                          localFile: localFile,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.open_in_full,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent(
    bool hasLocal,
    File? localFile,
    bool hasUrl,
    String? imageUrl,
  ) {
    if (hasLocal) {
      return Image.file(localFile!, fit: BoxFit.cover);
    } else if (hasUrl) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),

        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      );
    } else {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }
  }

  void _showImagePopup(
    BuildContext context, {
    String? imageUrl,
    File? localFile,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: localFile != null
                    ? Image.file(localFile, fit: BoxFit.contain)
                    : CachedNetworkImage(
                        imageUrl: imageUrl ?? "",
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.error,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
