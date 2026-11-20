import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rentalhub/core/error/exceptions.dart';
import 'package:rentalhub/core/network/cpanel_storage_client.dart';

/// Item 8 root cause (found 2026-11-20 from the live upload.php):
/// the server returns BOTH a full public `url` and a bare
/// `filename`, and uploadFile used to return the full URL — which
/// every caller then wrapped as the media.php key, so every stored
/// image link was broken (payment proof, vehicle photos, KYC).
/// The key media.php serves is the relative path
/// `<folder>/<filename>`.
void main() {
  const secret = 'test-secret';

  CPanelStorageClient clientWithBody(String body, {int status = 200}) {
    return CPanelStorageClient(
      apiSecretKey: secret,
      httpClient: MockClient(
        (_) async => http.Response(body, status),
      ),
    );
  }

  Future<File> tempFile() async {
    final file = File(
      '${Directory.systemTemp.path}/cpanel-client-test-${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);
    return file;
  }

  test('uploadFile returns folder/filename, not the full public URL', () async {
    final client = clientWithBody(
      jsonEncode({
        'success': true,
        'url':
            'https://rentalhub.62onlinestore.com/storage/payments/abc123.jpg',
        'filename': 'abc123.jpg',
        'category': 'payments',
      }),
    );
    final file = await tempFile();
    final key = await client.uploadFile(
      file: file,
      userUid: 'customer-1',
      folder: 'payments',
    );
    expect(key, 'payments/abc123.jpg');
    await file.delete();
  });

  test('uploadFile extracts the key from a full URL when filename is absent',
      () async {
    final client = clientWithBody(
      jsonEncode({
        'success': true,
        'url':
            'https://rentalhub.62onlinestore.com/storage/vehicles/def456.jpg',
      }),
    );
    final file = await tempFile();
    final key = await client.uploadFile(
      file: file,
      userUid: 'shop-1',
      folder: 'vehicles',
    );
    expect(key, 'vehicles/def456.jpg');
    await file.delete();
  });

  test('uploadFile throws on a non-200 response', () async {
    final client = clientWithBody(
      '{"error": "Invalid category specified."}',
      status: 400,
    );
    final file = await tempFile();
    await expectLater(
      client.uploadFile(file: file, userUid: 'u', folder: 'payments'),
      throwsA(isA<ServerException>()),
    );
    await file.delete();
  });

  test('getSignedMediaUrl passes a relative key through unchanged', () {
    final client = CPanelStorageClient(apiSecretKey: secret);
    final url = client.getSignedMediaUrl('payments/abc123.jpg', 'u');
    final key = Uri.parse(url).queryParameters['key'];
    expect(key, 'payments/abc123.jpg');
    expect(Uri.parse(url).queryParameters.containsKey('auth'), isTrue);
  });

  test('getSignedMediaUrl normalizes a stored full public URL', () {
    final client = CPanelStorageClient(apiSecretKey: secret);
    final url = client.getSignedMediaUrl(
      'https://rentalhub.62onlinestore.com/storage/payments/abc123.jpg',
      'u',
    );
    expect(Uri.parse(url).queryParameters['key'], 'payments/abc123.jpg');
  });

  test('getSignedMediaUrl unwraps a stored signed URL to the relative key',
      () {
    final client = CPanelStorageClient(apiSecretKey: secret);
    final stored =
        'https://rentalhub.62onlinestore.com/storage/media.php?key=payments%2Fabc123.jpg&auth=oldtoken';
    final url = client.getSignedMediaUrl(stored, 'u');
    final params = Uri.parse(url).queryParameters;
    expect(params['key'], 'payments/abc123.jpg');
    expect(params['auth'], isNot('oldtoken'));
  });
}
