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

  /// Generates HMAC-SHA256 bearer token from user UID and current timestamp
  String generateAuthToken(String userUid) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final message = '$userUid:$timestamp';
    final hmac = Hmac(sha256, utf8.encode(apiSecretKey));
    final digest = hmac.convert(utf8.encode(message));
    return '$message:${digest.toString()}';
  }

  /// Uploads media file to cPanel secure storage endpoint
  Future<String> uploadFile({
    required File file,
    required String userUid,
    required String folder, // 'kyc', 'payments', 'handovers', 'agreements'
  }) async {
    final uri = Uri.parse('$baseUrl${ApiEndpoints.uploadEndpoint}');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${generateAuthToken(userUid)}'
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('media_file', file.path));

    final streamedResponse = await _httpClient.send(request);
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      return json['file_key'] as String; // e.g. 'kyc/cnic_front_35201.jpg'
    } else {
      throw ServerException(message: 'cPanel upload failed (${streamedResponse.statusCode}): $responseBody');
    }
  }

  /// Generates a short-lived signed URL for private media viewing
  String getSignedMediaUrl(String fileKey, String userUid) {
    final token = generateAuthToken(userUid);
    return '$baseUrl${ApiEndpoints.mediaEndpoint}?key=${Uri.encodeComponent(fileKey)}&auth=${Uri.encodeComponent(token)}';
  }
}

