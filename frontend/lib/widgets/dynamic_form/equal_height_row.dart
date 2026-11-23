import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Cards side by side in equal-width columns, all as tall as the tallest
/// card, so a row of section boxes lines up top and bottom.
///
/// Works with children that cannot report their intrinsic height (for
/// example ones that use LayoutBuilder), which IntrinsicHeight cannot.
class EqualHeightRow extends MultiChildRenderObjectWidget {
  const EqualHeightRow({
    super.key,
    required this.columns,
    this.gap = 16,
    required super.children,
  });

  /// Number of equal columns; missing children leave their column empty.
  final int columns;

  /// Space between columns.
  final double gap;

  @override
  RenderEqualHeightRow createRenderObject(BuildContext context) =>
      RenderEqualHeightRow(columns: columns, gap: gap);

  @override
  void updateRenderObject(
      BuildContext context, RenderEqualHeightRow renderObject) {
    renderObject
      ..columns = columns
      ..gap = gap;
  }
}

class _EqualHeightParentData extends ContainerBoxParentData<RenderBox> {}

class RenderEqualHeightRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _EqualHeightParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _EqualHeightParentData> {
  RenderEqualHeightRow({required int columns, required double gap})
      : _columns = columns,
        _gap = gap;

  int _columns;
  int get columns => _columns;
  set columns(int v) {
    if (v == _columns) return;
    _columns = v;
    markNeedsLayout();
  }

  double _gap;
  double get gap => _gap;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _EqualHeightParentData) {
      child.parentData = _EqualHeightParentData();
    }
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final n = math.max(columns, childCount);
    final colWidth = math.max(0.0, (width - gap * (n - 1)) / n);

    // First pass: natural height of each card at its column width
    var tallest = 0.0;
    var child = firstChild;
    while (child != null) {
      child.layout(BoxConstraints.tightFor(width: colWidth),
          parentUsesSize: true);
      tallest = math.max(tallest, child.size.height);
      child = childAfter(child);
    }

    // Second pass: every card as tall as the tallest one. The height is a
    // minimum, not tight: tight constraints would make each card a relayout
    // boundary, so a card that grows on its own (a field added inside it)
    // would be re-laid out alone at the old height and overflow.
    var x = 0.0;
    child = firstChild;
    while (child != null) {
      child.layout(
          BoxConstraints(
              minWidth: colWidth, maxWidth: colWidth, minHeight: tallest),
          parentUsesSize: true);
      (child.parentData! as _EqualHeightParentData).offset = Offset(x, 0);
      x += colWidth + gap;
      child = childAfter(child);
    }
    size = constraints.constrain(Size(width, tallest));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  double computeMinIntrinsicHeight(double width) => 0;

  @override
  double computeMaxIntrinsicHeight(double width) => 0;

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;
}
