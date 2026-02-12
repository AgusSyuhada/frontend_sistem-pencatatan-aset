import 'dart:async';
import 'package:flutter/material.dart';

class CustomSearchableDropdown<T> extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final Future<List<T>> Function(String query)? futureRequest;
  final String Function(T item) displayItem;
  final Function(T item)? onSelected;
  final Function(String val)? onCreateNew;
  final T? selectedItem;
  final bool readOnly;
  final bool hideSearch;
  final Widget? suffixIcon;

  const CustomSearchableDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.futureRequest,
    required this.displayItem,
    this.onSelected,
    this.onCreateNew,
    this.selectedItem,
    this.readOnly = false,
    this.hideSearch = false,
    this.suffixIcon,
  });

  @override
  State<CustomSearchableDropdown<T>> createState() =>
      _CustomSearchableDropdownState<T>();
}

class _CustomSearchableDropdownState<T>
    extends State<CustomSearchableDropdown<T>> {
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
        _onSearchChanged(
          widget.hideSearch ? "" : widget.controller.text,
          isInit: true,
        );
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
    if (widget.readOnly || widget.futureRequest == null) return;
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
        final result = await widget.futureRequest!(query);
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
    if (widget.readOnly || widget.futureRequest == null) return;
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
      if (!widget.hideSearch &&
          widget.controller.text.isNotEmpty &&
          widget.onCreateNew != null) {
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

    return IgnorePointer(
      ignoring: widget.readOnly,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: widget.hideSearch
                    ? null
                    : (val) => _onSearchChanged(val),
                readOnly: widget.readOnly || widget.hideSearch,
                showCursor: !widget.readOnly && !widget.hideSearch,
                onTap: () {
                  if (widget.hideSearch && !widget.readOnly) {
                    _focusNode.requestFocus();
                  }
                },
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  filled: true,
                  fillColor: (widget.readOnly)
                      ? Colors.grey.shade100
                      : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  suffixIcon:
                      widget.suffixIcon ??
                      (widget.readOnly
                          ? null
                          : (_isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ))),
                  border: commonBorder,
                  enabledBorder: commonBorder,
                  focusedBorder: commonBorder.copyWith(
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
