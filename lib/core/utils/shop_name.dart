/// The shop display name from a `shops` document's raw data.
///
/// Live shop docs store the name under snake_case `shop_name`
/// (`ShopModel.toMap()`); `name` / `shopName` are legacy fallbacks
/// only. The Al-Falah doc has `shop_name` and no `name`, so a read
/// of `name` first — or only — yields an empty name (the handover
/// wizard's "Shop name could not be loaded" failure, build 89).
/// Every shop-name read must go through here so the key order
/// cannot drift again.
String shopNameFromData(Map<String, dynamic>? data) =>
    (data?['shop_name'] ?? data?['name'] ?? data?['shopName'] ?? '')
        as String;
