/// One page of an admin list, for the lists that used to stop at a
/// silent 200-row cap with no way past it.
///
/// `cursor` is an opaque Firestore document snapshot: the view holds
/// it and passes it back to the next page call. It is `Object?` here
/// so views never import Firestore types; data sources cast it back.
class AdminPage<T> {
  const AdminPage({
    required this.items,
    required this.hasMore,
    this.cursor,
  });

  /// The rows on this page.
  final List<T> items;

  /// True when another page exists after this one.
  final bool hasMore;

  /// Pass back to the data source to load the next page, or null
  /// when this is the last page.
  final Object? cursor;
}
