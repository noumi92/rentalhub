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
      // upload.php returns BOTH a full public `url` and a bare
      // `filename`. The key media.php serves is the RELATIVE path
      // `<folder>/<filename>` — returning the full URL here used to
      // wrap it as the media.php key, so every stored image link
      // was broken (payment proof, vehicle photos, KYC). Prefer
      // the filename; fall back to the path after '/storage/' in
      // `url` for servers that only return the full URL.
      final filename = json['filename'] as String?;
      if (filename != null && filename.isNotEmpty) {
        return '$folder/$filename';
      }
      final url = json['url'] as String?;
      if (url != null && url.isNotEmpty) {
        const marker = '/storage/';
        final idx = url.indexOf(marker);
        if (idx >= 0) return url.substring(idx + marker.length);
        return url;
      }
      // Item 8: a 200 with neither a filename nor a usable URL used
      // to return '' — and every caller then wrapped '' into a
      // signed media.php URL (`?key=&auth=…`) and reported the
      // upload a success, so the booking was marked
      // `payment_submitted` with a proof that can never display.
      // A 200 with no key is a failed upload: throw so callers
      // queue / report failure instead of filing a blank proof.
      throw const ServerException(
          message: 'cPanel upload returned no filename or URL');
    } else {
      throw ServerException(
          message:
              'cPanel upload failed (${streamedResponse.statusCode}): $responseBody');
    }
  }

  /// Item 8: turns whatever a Firestore media field holds into a
  /// URL an image viewer can load. The field has held three shapes
  /// and the owner proof view used to pass it raw to Image.network,
  /// so a bare key (`payments/<file>`, filed by the PaymentCubit
  /// path and by key-storing drains) could never display — it is
  /// not a URL. Bare keys are signed through media.php; a full
  /// public URL (`https://…/storage/payments/<file>`, pre-build-86)
  /// and a stored signed media.php URL load as-is and are left
  /// alone — re-signing the public URL would route a working link
  /// through media.php, and media.php enforces no token expiry, so
  /// re-signing a stored signed URL gains nothing. Blank → ''.
  String resolveStoredMediaUrl(String stored, [String? userUid]) {
    final trimmed = stored.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return getSignedMediaUrl(trimmed, userUid);
  }

  /// Generates a short-lived signed URL for private media viewing.
  /// [fileKey] is the relative path media.php serves
  /// (`<category>/<filename>`). Back-compat: Firestore docs written
  /// before the key fix store the full public URL as the key, and
  /// some store a full signed URL — both are stripped down to the
  /// relative key here so old stored values keep working.
  String getSignedMediaUrl(String fileKey, [String? userUid]) {
    var key = fileKey.trim();
    const marker = '/storage/';
    final idx = key.indexOf(marker);
    if (idx >= 0) key = key.substring(idx + marker.length);
    final uri = Uri.tryParse(key);
    if (uri != null && uri.queryParameters.containsKey('key')) {
      key = uri.queryParameters['key'] ?? key;
    }
    final token = generateAuthToken(userUid);
    return '$baseUrl${ApiEndpoints.mediaEndpoint}?key=${Uri.encodeComponent(key)}&auth=${Uri.encodeComponent(token)}';
  }
}

