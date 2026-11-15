import 'package:flutter/widgets.dart';

/// Phase D (D3): Material 3 window size classes, from the logical width
/// (rulebook §4.4 / M3 defaults): compact < 600dp (phones), medium
/// 600–840dp (large phones / small tablets), expanded ≥ 840dp (tablets /
/// desktop). One tiny helper, no dependencies — views ask for the class
/// and pick a layout. Compact layouts stay exactly as they were; only
/// medium+ changes.
enum WindowSizeClass { compact, medium, expanded }

/// The size class of the current window.
WindowSizeClass windowSizeClassOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) return WindowSizeClass.compact;
  if (width < 840) return WindowSizeClass.medium;
  return WindowSizeClass.expanded;
}

/// True on medium and expanded windows (≥ 600dp) — the widths where a
/// second column earns its keep.
bool isMediumOrLarger(BuildContext context) =>
    windowSizeClassOf(context) != WindowSizeClass.compact;

/// Pick a value per size class. [expanded] falls back to [medium] when
/// it is not given, so callers only name the widths that differ.
T columnsFor<T>(
  BuildContext context, {
  required T compact,
  required T medium,
  T? expanded,
}) {
  switch (windowSizeClassOf(context)) {
    case WindowSizeClass.compact:
      return compact;
    case WindowSizeClass.medium:
      return medium;
    case WindowSizeClass.expanded:
      return expanded ?? medium;
  }
}

/// D3: two-column layout for medium+ widths — items split by index
/// parity so both columns stay balanced. Returns a [Row] of two
/// [Expanded] columns; callers keep their single-column list for
/// compact widths. [itemSpacing] is the vertical gap between cards in
/// a column (pass 0 when the cards carry their own bottom margin, as
/// [ShopListCard] does); [gap] is the horizontal gap between columns;
/// [padding] is the outer padding (the compact list's padding, so both
/// layouts align). [flushLastItem] drops the bottom spacing under the
/// last card of each column, so the list bottom is the outer padding
/// alone (BP-18) — off by default, so existing callers are unchanged.
Widget twoColumnLayout<T>({
  required List<T> items,
  required Widget Function(T item) itemBuilder,
  double gap = 14,
  double itemSpacing = 14,
  EdgeInsetsGeometry padding = EdgeInsets.zero,
  bool flushLastItem = false,
  Key? key,
}) {
  final columns = [<T>[], <T>[]];
  for (var i = 0; i < items.length; i++) {
    columns[i % 2].add(items[i]);
  }
  Widget column(List<T> vs) => Column(
        children: [
          for (var i = 0; i < vs.length; i++)
            Padding(
              padding: EdgeInsets.only(
                  bottom: flushLastItem && i == vs.length - 1
                      ? 0
                      : itemSpacing),
              child: itemBuilder(vs[i]),
            ),
        ],
      );
  return Padding(
    padding: padding,
    child: Row(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: column(columns[0])),
        SizedBox(width: gap),
        Expanded(child: column(columns[1])),
      ],
    ),
  );
}
