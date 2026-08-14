import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared responsive column policy for dashboard sections.
abstract final class DashboardGridPolicy {
  static int columnsFor({
    required double availableWidth,
    required double minimumTileWidth,
    required int maxColumns,
    required double spacing,
  }) {
    if (!availableWidth.isFinite || availableWidth <= 0) return 1;
    final fitted =
        ((availableWidth + spacing) / (minimumTileWidth + spacing)).floor();
    return math.max(1, math.min(maxColumns, fitted));
  }
}

/// A non-scrolling dashboard grid whose children consume the full width.
class ResponsiveDashboardGrid extends StatelessWidget {
  const ResponsiveDashboardGrid({
    super.key,
    required this.children,
    required this.minimumTileWidth,
    required this.maxColumns,
    required this.mainAxisExtent,
    this.spacing = 12,
  });

  final List<Widget> children;
  final double minimumTileWidth;
  final int maxColumns;
  final double mainAxisExtent;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = DashboardGridPolicy.columnsFor(
            availableWidth: constraints.maxWidth,
            minimumTileWidth: minimumTileWidth,
            maxColumns: maxColumns,
            spacing: spacing,
          );
          return GridView.count(
            key: ValueKey('dashboard-grid-$columns-columns'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: mainAxisExtent,
            children: children,
          );
        },
      );
}
