import 'package:flutter/material.dart';
import 'dart:math' as math;

class GenericDataTable<T> extends StatefulWidget {
  final List<DataHeader> headers;
  final List<T> data;
  final Widget Function(BuildContext context, int index, T item) rowBuilder;
  final bool isLoading;
  final String emptyMessage;
  final Future<void> Function()? onRefresh;
  final void Function(T item)? onRowTap;
  final double? minWidth;
  final ScrollController? scrollController;

  const GenericDataTable({
    super.key,
    required this.headers,
    required this.data,
    required this.rowBuilder,
    this.isLoading = false,
    this.emptyMessage = 'Tidak ada data ditemukan.',
    this.onRefresh,
    this.onRowTap,
    this.minWidth,
    this.scrollController,
  });

  @override
  State<GenericDataTable<T>> createState() => _GenericDataTableState<T>();
}

class _GenericDataTableState<T> extends State<GenericDataTable<T>> {
  final ScrollController _headerController = ScrollController();
  late ScrollController _horizontalBodyController;

  @override
  void initState() {
    super.initState();
    _horizontalBodyController = ScrollController();
    _horizontalBodyController.addListener(() {
      if (_headerController.hasClients) {
        _headerController.jumpTo(_horizontalBodyController.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _horizontalBodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.data.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.data.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh ?? () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    widget.emptyMessage,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double parentWidth = constraints.maxWidth;
        final double contentWidth = math.max(parentWidth, widget.minWidth ?? 0);
        return Column(
          children: [
            SingleChildScrollView(
              controller: _headerController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Container(
                width: contentWidth,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.headers
                      .map((h) => _buildHeaderCell(h))
                      .toList(),
                ),
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: widget.onRefresh ?? () async {},
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  scrollDirection: Axis.vertical,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SingleChildScrollView(
                    controller: _horizontalBodyController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        children: List.generate(widget.data.length, (index) {
                          final item = widget.data[index];
                          final rowColor = index.isEven
                              ? Colors.white
                              : Colors.blue.shade50;
                          return Material(
                            color: rowColor,
                            child: InkWell(
                              onTap: widget.onRowTap != null
                                  ? () => widget.onRowTap!(item)
                                  : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 12.0,
                                ),
                                child: widget.rowBuilder(context, index, item),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderCell(DataHeader header) {
    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: header.textAlign == TextAlign.center
          ? MainAxisAlignment.center
          : (header.textAlign == TextAlign.right
                ? MainAxisAlignment.end
                : MainAxisAlignment.start),
      children: [
        Text(
          header.text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.black87,
          ),
          textAlign: header.textAlign,
        ),
        if (header.onSort != null) ...[
          const SizedBox(width: 4),
          Icon(
            header.isAscending == true
                ? Icons.arrow_drop_up
                : Icons.arrow_drop_down,
            size: 20,
            color: header.isAscending == null ? Colors.grey : Colors.black87,
          ),
        ],
      ],
    );

    if (header.onSort != null) {
      child = InkWell(
        onTap: header.onSort,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: child,
        ),
      );
    }

    if (header.width != null) {
      return SizedBox(width: header.width, child: child);
    }
    return Expanded(flex: header.flex, child: child);
  }
}

class DataHeader {
  final String text;
  final int flex;
  final double? width;
  final TextAlign textAlign;
  final VoidCallback? onSort;
  final bool? isAscending;

  DataHeader({
    required this.text,
    this.flex = 1,
    this.width,
    this.textAlign = TextAlign.left,
    this.onSort,
    this.isAscending,
  });
}

class DataCellWidget extends StatelessWidget {
  final String text;
  final FontWeight? fontWeight;
  final Color? color;
  final int flex;
  final double? width;
  final TextAlign textAlign;

  const DataCellWidget({
    super.key,
    required this.text,
    this.fontWeight,
    this.color,
    this.flex = 1,
    this.width,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Text(
      text,
      style: TextStyle(
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color ?? Colors.black87,
        fontSize: 13,
      ),
      textAlign: textAlign,
    );

    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(flex: flex, child: child);
  }
}
