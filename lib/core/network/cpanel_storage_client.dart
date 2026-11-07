import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../error/exceptions.dart';

class CPanelStorageClient {
  final String baseUrl;
  final String apiSecretKey;
  final http.Client _httpClient;

  CPanelStorageClient({
    this.baseUrl = ApiEndpoints.cpanelBaseUrl,
    required this.apiSecretKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Generates base64-encoded timestamp:hmac bearer token matched with cPanel upload.php
  String generateAuthToken([String? userUid]) {
    final timestampInSeconds =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final hmac = Hmac(sha256, utf8.encode(apiSecretKey));
    final digest = hmac.convert(utf8.encode(timestampInSeconds)).toString();
    final message = '$timestampInSeconds:$digest';
    return base64Encode(utf8.encode(message));
  }

  /// Uploads media file to cPanel secure storage endpoint.
  ///
  /// Phase B (B3): single-attempt uploads used to hang forever on a
  /// dead connection and then throw the file away. The request now
  /// times out ([timeout], default 60s) — callers queue the file in
  /// the offline sync queue on failure instead of losing it.
  Future<String> uploadFile({
    required File file,
    required String userUid,
    required String folder, // 'kyc', 'payments', 'handovers', 'agreements'
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final uri = Uri.parse('$baseUrl${ApiEndpoints.uploadEndpoint}');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${generateAuthToken(userUid)}'
      ..fields['category'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse =
        await _httpClient.send(request).timeout(timeout);
    final responseBody =
        await streamedResponse.stream.bytesToString().timeout(timeout);

    if (streamedResponse.statusCode == 200) {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      return (json['url'] ?? json['filename'] ?? '') as String;
    } else {
      throw ServerException(
          message:
              'cPanel upload failed (${streamedResponse.statusCode}): $responseBody');
    }
  }

  /// Generates a short-lived signed URL for private media viewing
  String getSignedMediaUrl(String fileKey, [String? userUid]) {
    final token = generateAuthToken(userUid);
    return '$baseUrl${ApiEndpoints.mediaEndpoint}?key=${Uri.encodeComponent(fileKey)}&auth=${Uri.encodeComponent(token)}';
  }
}

