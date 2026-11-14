// Admin-panel audit fixes (2026-11-14) — the findings this batch owns
// that the sibling's admin_audit_fixes_test.dart does not cover:
// F-M6 admin reads throw instead of rendering zeros/empty states,
// F-M12 settings read returns null (no document) and throws on
// failure, AD-M12 draft validation + dirty guard, F-M13 maintenance
// mode parsing, F-M1 no seeded blacklist sample, F-M5/F-m5/F-m11/
// F-m17 invite create/revoke/accept, F-m4 expired-invite pruning,
// AD-m14 email-format validation.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rentalhub/core/utils/email_validation.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:rentalhub/features/admin/data/datasources/admin_support_data_source.dart';
import 'package:rentalhub/features/admin/data/repositories/platform_settings_repository.dart';
import 'package:rentalhub/features/admin/presentation/widgets/admin_settings_draft.dart';
import 'package:rentalhub/features/blacklist/data/datasources/blacklist_remote_data_source.dart';

/// A Firestore that fails every collection read/write, so the
/// F-M6 "throw, don't render empty" behaviour can be pinned.
class _ThrowingFirestore extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    throw FirebaseException(
        plugin: 'cloud_firestore', code: 'unavailable');
  }
}

void main() {
  group('F-M5/F-m17 — invites round-trip on real document ids', () {
    test('createInvite returns the Firestore doc id and persists',
        () async {
      final fake = FakeFirebaseFirestore();
      final ds = AdminRemoteDataSource(firestore: fake);
      final invite = await ds.createInvite(
        email: 'ops-test@rentalhub.pk',
        adminRole: 'operations',
        callerRole: 'super_admin',
      );
      expect(invite.id, isNotEmpty);
      expect(invite.id.startsWith('INV-'), isFalse);
      final snap = await fake
          .collection('admin_invites')
          .doc(invite.id)
          .get();
      expect(snap.exists, isTrue);
      expect(snap.data()?['email'], 'ops-test@rentalhub.pk');
    });

    test('revokeInvite deletes the document; accept marks it accepted',
        () async {
      final fake = FakeFirebaseFirestore();
      final ds = AdminRemoteDataSource(firestore: fake);
      final invite = await ds.createInvite(
        email: 'accept-test@rentalhub.pk',
        adminRole: 'support',
        callerRole: 'super_admin',
      );
      await ds.markInviteAccepted(invite.id, callerRole: 'super_admin');
      final accepted = await ds.getInvites();
      expect(accepted.singleWhere((i) => i.id == invite.id).accepted,
          isTrue);

      final second = await ds.createInvite(
        email: 'revoke-test@rentalhub.pk',
        adminRole: 'support',
        callerRole: 'super_admin',
      );
      await ds.revokeInvite(second.id, callerRole: 'super_admin');
      final after = await ds.getInvites();
      expect(after.any((i) => i.id == second.id), isFalse);
    });

    test('F-m4 — pruneExpiredInvites removes only expired invites',
        () async {
      final fake = FakeFirebaseFirestore();
      final ds = AdminRemoteDataSource(firestore: fake);
      await fake.collection('admin_invites').add({
        'email': 'old@rentalhub.pk',
        'admin_role': 'support',
        'accepted': false,
        'expires_at':
            Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'created_at': Timestamp.now(),
      });
      await fake.collection('admin_invites').add({
        'email': 'fresh@rentalhub.pk',
        'admin_role': 'support',
        'accepted': false,
        'expires_at':
            Timestamp.fromDate(DateTime.now().add(const Duration(hours: 47))),
        'created_at': Timestamp.now(),
      });
      expect(await ds.pruneExpiredInvites(), 1);
      final remaining = await ds.getInvites();
      expect(remaining.length, 1);
      expect(remaining.first.email, 'fresh@rentalhub.pk');
    });
  });

  group('F-M6 — admin reads throw on Firestore failure', () {
    test('invite/team/audit/stats reads throw instead of empty', () async {
      final ds = AdminRemoteDataSource(firestore: _ThrowingFirestore());
      expect(
          () => ds.createInvite(
              email: 'x@rentalhub.pk',
              adminRole: 'support',
              callerRole: 'super_admin'),
          throwsA(isA<FirebaseException>()));
      expect(() => ds.revokeInvite('some-id', callerRole: 'super_admin'),
          throwsA(isA<FirebaseException>()));
      expect(() => ds.getInvites(), throwsA(isA<FirebaseException>()));
      expect(() => ds.getTeamMembers(), throwsA(isA<FirebaseException>()));
      expect(() => ds.getAuditLogs(), throwsA(isA<FirebaseException>()));
      expect(() => ds.getPlatformStats(), throwsA(isA<FirebaseException>()));
    });
  });

  group('F-M12 — settings read distinguishes no-document from failure',
      () {
    test('getPlatformSettings returns null when no document exists',
        () async {
      final ds = AdminSupportDataSource(firestore: FakeFirebaseFirestore());
      expect(await ds.getPlatformSettings(), isNull);
    });

    test('getPlatformSettings throws on a failed read', () async {
      final ds = AdminSupportDataSource(firestore: _ThrowingFirestore());
      expect(() => ds.getPlatformSettings(),
          throwsA(isA<FirebaseException>()));
    });
  });

  group('F-M13 — maintenance mode parsing is fail-open', () {
    test('only an explicit true enables maintenance mode', () {
      expect(
          PlatformSettingsRepository.maintenanceModeFromData(
              {'maintenance_mode': true}),
          isTrue);
      expect(
          PlatformSettingsRepository.maintenanceModeFromData(
              {'maintenance_mode': false}),
          isFalse);
      expect(
          PlatformSettingsRepository.maintenanceModeFromData({}), isFalse);
      expect(PlatformSettingsRepository.maintenanceModeFromData(null),
          isFalse);
      expect(
          PlatformSettingsRepository.maintenanceModeFromData(
              {'maintenance_mode': 'yes'}),
          isFalse);
    });
  });

  group('F-M1 — no seeded blacklist sample', () {
    test('a fresh data source knows no blacklisted CNIC', () async {
      final ds = BlacklistRemoteDataSource();
      expect(await ds.isCnicBlacklisted('35201-9999999-1'), isFalse);
      expect(await ds.getBlacklistRecordByCnic('35201-9999999-1'), isNull);
      expect(await ds.getAllRecordsStrict(), isEmpty);
    });
  });

  group('AD-m14 — email-format validation', () {
    test('isValidEmailAddress accepts real addresses only', () {
      expect(isValidEmailAddress('ops@rentalhub.pk'), isTrue);
      expect(isValidEmailAddress('a.b+tag@example.co.uk'), isTrue);
      expect(isValidEmailAddress('no-at-sign'), isFalse);
      expect(isValidEmailAddress('missing-domain@'), isFalse);
      expect(isValidEmailAddress('@missing-local.pk'), isFalse);
      expect(isValidEmailAddress('spaces in@address.pk'), isFalse);
      expect(isValidEmailAddress(''), isFalse);
    });
  });

  group('AD-M12 — settings draft validation and dirty guard', () {
    test('validate flags out-of-range numbers with inline errors', () {
      final draft = AdminSettingsDraft();
      draft.advanceController.text = '101';
      draft.depositController.text = '-5';
      draft.graceController.text = 'abc';
      final errors = draft.validate(null);
      expect(errors.keys, {'advance', 'deposit', 'grace'});

      draft.advanceController.text = '30';
      draft.depositController.text = '10000';
      draft.graceController.text = '60';
      expect(draft.validate(null), isEmpty);
    });

    test('isDirty is false before load and after applying, true on edit',
        () {
      final draft = AdminSettingsDraft();
      expect(draft.isDirty, isFalse);
      draft.apply(const PlatformSettings());
      expect(draft.isDirty, isFalse);
      draft.advanceController.text = '31';
      expect(draft.isDirty, isTrue);
      draft.advanceController.text = '30';
      expect(draft.isDirty, isFalse);
    });
  });
}
