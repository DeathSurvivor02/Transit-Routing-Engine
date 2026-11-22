import 'package:flutter/material.dart';
import 'search_header_delegate.dart';

/// Persistent gesture-coordinated multi-snap bottom sheet.
class TransitPersistentBottomSheet extends StatelessWidget {
  final DraggableScrollableController sheetController;
  final Widget searchHeader;
  final Widget itineraryList;

  const TransitPersistentBottomSheet({
    super.key,
    required this.sheetController,
    required this.searchHeader,
    required this.itineraryList,
  });

  static Widget sheetDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8.0, bottom: 4.0),
        width: 36.0,
        height: 4.0,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(2.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: sheetController,
      initialChildSize: 0.22,
      minChildSize: 0.16,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.22, 0.50, 0.95],
      builder: (context, scrollController) {
        return Material(
          elevation: 16.0,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
          color: Theme.of(context).colorScheme.surface,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(child: sheetDragHandle()),
              SliverPersistentHeader(
                pinned: true,
                delegate: SearchHeaderDelegate(child: searchHeader, height: 120.0),
              ),
              itineraryList,
            ],
          ),
        );
      },
    );
  }
}
