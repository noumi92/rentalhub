/// One page of an admin list, for the lists that used to stop at a
/// silent 200-row cap with no way past it.
///
/// `cursor` is an opaque Firestore document snapshot: the view holds
/// it and passes it back to the next page call. It is `Object?` here
/// so views never import Firestore types; data sources cast it back.
/// For the in-memory (offline / test) path a data source may use an
/// integer offset as the cursor instead.
///
/// Phase 3 (3.4): `total` is the whole list's size when the data
/// source knows it (a `count()` aggregate, or the filtered list's
/// length on the in-memory path), so a view can say "Showing first
/// N of M" instead of silently truncating. Null when the total was
/// not counted.
class AdminPage<T> {
  const AdminPage({
    required this.items,
    required this.hasMore,
    this.cursor,
    this.total,
  });

  /// The rows on this page.
  final List<T> items;

  /// True when another page exists after this one.
  final bool hasMore;

  /// Pass back to the data source to load the next page, or null
  /// when this is the last page.
  final Object? cursor;

  /// The total number of rows in the whole list, when known.
  final int? total;
}
