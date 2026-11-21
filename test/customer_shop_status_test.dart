// Walk-in customer CRM (data layer): per-shop status lives in a
// `shopStatuses` map on the CNIC-keyed customer doc, keyed by shop
// DOCUMENT id. No entry for a shop means 'active'. Delete = archive;
// there is no hard delete.
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/features/customer/data/datasources/customer_remote_data_source.dart';
import 'package:rentalhub/features/customer/data/models/customer_model.dart';
import 'package:rentalhub/features/customer/data/repositories/customer_repository_impl.dart';
import 'package:rentalhub/features/customer/domain/entities/customer_entity.dart';

CustomerEntity _customer({
  String customerId = 'cust-3520212345671',
  Map<String, String>? shopStatuses,
}) =>
    CustomerEntity(
      customerId: customerId,
      shopId: 'shop_owner1',
      name: 'Ahmed Khan',
      phone: '0300-1234567',
      cnic: '35202-1234567-1',
      createdAt: DateTime.utc(2026, 11, 9, 4, 0),
      shopStatuses: shopStatuses,
    );

void main() {
  group('CustomerEntity.statusForShop', () {
    test("defaults to 'active' with no map", () {
      expect(_customer().shopStatuses, isNull);
      expect(_customer().statusForShop('shop_owner1'), 'active');
      expect(_customer().statusForShop('shop_other'), 'active');
    });

    test("defaults to 'active' with an empty map", () {
      expect(_customer(shopStatuses: const {}).statusForShop('shop_owner1'),
          'active');
    });

    test("stored 'blocked' and 'archived' read back per shop", () {
      final entity = _customer(shopStatuses: const {
        'shop_owner1': 'blocked',
        'shop_owner2': 'archived',
      });
      expect(entity.statusForShop('shop_owner1'), 'blocked');
      expect(entity.statusForShop('shop_owner2'), 'archived');
      // A shop with no entry still reads active.
      expect(entity.statusForShop('shop_owner3'), 'active');
    });

    test('status constants name the three values', () {
      expect(CustomerEntity.statusActive, 'active');
      expect(CustomerEntity.statusBlocked, 'blocked');
      expect(CustomerEntity.statusArchived, 'archived');
    });

    test('copyWith preserves and replaces shopStatuses', () {
      final entity = _customer(shopStatuses: const {'shop_owner1': 'blocked'});
      expect(entity.copyWith().shopStatuses, {'shop_owner1': 'blocked'});
      expect(entity.copyWith().statusForShop('shop_owner1'), 'blocked');
      final updated = entity.copyWith(
          shopStatuses: const {'shop_owner1': 'archived'});
      expect(updated.statusForShop('shop_owner1'), 'archived');
      // copyWith leaves the other fields untouched.
      expect(updated.name, entity.name);
      expect(updated.customerId, entity.customerId);
    });
  });

  group('CustomerModel shopStatuses round-trip', () {
    test('full record with two shops round-trips', () {
      final model = CustomerModel.fromEntity(_customer(shopStatuses: const {
        'shop_owner1': 'blocked',
        'shop_owner2': 'archived',
      }));
      final restored = CustomerModel.fromMap(model.toMap(), model.customerId);
      expect(restored, equals(model));
      expect(restored.shopStatuses,
          {'shop_owner1': 'blocked', 'shop_owner2': 'archived'});
      expect(restored.statusForShop('shop_owner1'), 'blocked');
      expect(restored.statusForShop('shop_owner2'), 'archived');
    });

    test('missing key reads as null and writes back without the key', () {
      final restored = CustomerModel.fromMap({
        'customerId': 'cust-1',
        'shopId': 'shop-1',
        'name': 'Old Customer',
        'phone': '0300-0000000',
        'source': 'walk_in',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
      });
      expect(restored.shopStatuses, isNull);
      expect(restored.statusForShop('shop-1'), 'active');
      expect(restored.toMap().containsKey('shopStatuses'), isFalse);
    });

    test('null and empty maps omit the key on write', () {
      expect(CustomerModel.fromEntity(_customer()).toMap().containsKey('shopStatuses'), isFalse);
      final model =
          CustomerModel.fromEntity(_customer(shopStatuses: const {}));
      expect(model.toMap().containsKey('shopStatuses'), isFalse);
    });

    test('malformed values are tolerated (skipped)', () {
      final restored = CustomerModel.fromMap({
        'customerId': 'cust-1',
        'shopId': 'shop-1',
        'name': 'Messy Customer',
        'phone': '0300-0000000',
        'source': 'walk_in',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'shopStatuses': {
          'shop_owner1': 'blocked',
          'shop_bad_int': 42,
          'shop_bad_null': null,
          'shop_bad_list': ['archived'],
          7: 'blocked',
        },
      });
      // Only the well-formed string->string entry survives.
      expect(restored.shopStatuses, {'shop_owner1': 'blocked'});
      expect(restored.statusForShop('shop_owner1'), 'blocked');
      expect(restored.statusForShop('shop_bad_int'), 'active');
    });

    test('a map with no well-formed entries reads as null', () {
      final restored = CustomerModel.fromMap({
        'customerId': 'cust-1',
        'shopId': 'shop-1',
        'name': 'Messy Customer',
        'phone': '0300-0000000',
        'source': 'walk_in',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'shopStatuses': {'shop_bad': 42},
      });
      expect(restored.shopStatuses, isNull);
      expect(restored.toMap().containsKey('shopStatuses'), isFalse);
    });

    test('non-map shopStatuses reads as null', () {
      final restored = CustomerModel.fromMap({
        'customerId': 'cust-1',
        'shopId': 'shop-1',
        'name': 'Messy Customer',
        'phone': '0300-0000000',
        'source': 'walk_in',
        'createdAt': DateTime.utc(2026, 1, 1).toIso8601String(),
        'shopStatuses': 'blocked',
      });
      expect(restored.shopStatuses, isNull);
    });
  });

  group('CustomerRemoteDataSource status writes (in-memory path)', () {
    // No Firestore instance is passed, so the data source falls back
    // to its in-memory store (same path the audit tests exercise via
    // DI when Firebase is not initialised); a failed direct write
    // has no queue attached here, so the in-memory copy is the
    // observable result.
    late CustomerRemoteDataSource ds;

    setUp(() {
      ds = CustomerRemoteDataSource();
    });

    Future<CustomerEntity?> stored(String customerId) =>
        ds.getCustomerById(customerId);

    test("updateCustomerStatus stores 'blocked' for one shop only", () async {
      await ds.upsertCustomer(_customer(shopStatuses: const {
        'shop_owner2': 'archived',
      }));
      await ds.updateCustomerStatus(
        customerId: 'cust-3520212345671',
        shopId: 'shop_owner1',
        status: 'blocked',
      );
      final after = await stored('cust-3520212345671');
      expect(after?.statusForShop('shop_owner1'), 'blocked');
      // The other shop's entry is untouched.
      expect(after?.statusForShop('shop_owner2'), 'archived');
      expect(after?.name, 'Ahmed Khan');
    });

    test("updateCustomerStatus can return a shop to 'active'", () async {
      await ds.upsertCustomer(_customer(shopStatuses: const {
        'shop_owner1': 'blocked',
      }));
      await ds.updateCustomerStatus(
        customerId: 'cust-3520212345671',
        shopId: 'shop_owner1',
        status: 'active',
      );
      expect(
        (await stored('cust-3520212345671'))?.statusForShop('shop_owner1'),
        'active',
      );
    });

    test('updateCustomerStatus rejects an invalid status', () async {
      await ds.upsertCustomer(_customer());
      await expectLater(
        ds.updateCustomerStatus(
          customerId: 'cust-3520212345671',
          shopId: 'shop_owner1',
          status: 'deleted',
        ),
        throwsArgumentError,
      );
      await expectLater(
        ds.updateCustomerStatus(
          customerId: 'cust-3520212345671',
          shopId: 'shop_owner1',
          status: '',
        ),
        throwsArgumentError,
      );
      // The rejected write changed nothing.
      final after = await stored('cust-3520212345671');
      expect(after?.shopStatuses, isNull);
      expect(after?.statusForShop('shop_owner1'), 'active');
    });

    test("archiveCustomer delegates with 'archived'", () async {
      await ds.upsertCustomer(_customer(shopStatuses: const {
        'shop_owner2': 'blocked',
      }));
      await ds.archiveCustomer(
        customerId: 'cust-3520212345671',
        shopId: 'shop_owner1',
      );
      final after = await stored('cust-3520212345671');
      expect(after?.statusForShop('shop_owner1'), 'archived');
      // The other shop's entry is untouched.
      expect(after?.statusForShop('shop_owner2'), 'blocked');
    });
  });

  group('CustomerRepositoryImpl delegates to the data source', () {
    test('updateCustomerStatus and archiveCustomer flow through', () async {
      final ds = CustomerRemoteDataSource();
      final repo = CustomerRepositoryImpl(remoteDataSource: ds);
      await ds.upsertCustomer(_customer());
      await repo.updateCustomerStatus(
        customerId: 'cust-3520212345671',
        shopId: 'shop_owner1',
        status: 'blocked',
      );
      expect(
        (await ds.getCustomerById('cust-3520212345671'))
            ?.statusForShop('shop_owner1'),
        'blocked',
      );
      await repo.archiveCustomer(
        customerId: 'cust-3520212345671',
        shopId: 'shop_owner1',
      );
      expect(
        (await ds.getCustomerById('cust-3520212345671'))
            ?.statusForShop('shop_owner1'),
        'archived',
      );
    });
  });
}
