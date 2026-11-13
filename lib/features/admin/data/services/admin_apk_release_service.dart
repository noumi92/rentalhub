import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// The release build published by CI to cPanel (`apk/version.json`).
///
/// Every field is optional: the file is written by the workflow and a
/// missing field must never be invented — the card shows only what the
/// file actually contains.
class AppReleaseInfo {
  const AppReleaseInfo({
    this.versionName,
    this.versionCode,
    this.build,
    this.commit,
    this.apkFileName,
    this.updatedAt,
  });

  factory AppReleaseInfo.fromJson(Map<String, dynamic> json) {
    return AppReleaseInfo(
      versionName: json['versionName'] as String?,
      versionCode: _asInt(json['versionCode']),
      build: _asInt(json['build']),
      commit: json['commit'] as String?,
      apkFileName: json['apk'] as String?,
      updatedAt: _asDateTime(json['updatedAt']),
    );
  }

  static int? _asInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _asDateTime(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  final String? versionName;
  final int? versionCode;
  final int? build;
  final String? commit;
  final String? apkFileName;
  final DateTime? updatedAt;

  /// The APK file name from the file; CI always writes
  /// `app-release.apk`, which is the fallback when the field is absent.
  String get apkFileNameOrDefault =>
      apkFileName != null && apkFileName!.isNotEmpty
          ? apkFileName!
          : 'app-release.apk';
}

/// Reads the latest published build from `apk/version.json`, resolved
/// relative to the panel's own URL (the CI workflow uploads the file to
/// the `apk/` folder under the same cPanel path that serves the panel).
/// Injectable (`http.Client` + base URI) so tests can answer without
/// the network.
///
/// Returns null when the file is unreachable (no build published yet);
/// throws [FormatException] when the file exists but is not valid JSON.
class AdminApkReleaseService {
  AdminApkReleaseService({http.Client? client, Uri? baseUri})
      : _client = client ?? http.Client(),
        _baseUri = baseUri ?? Uri.base;

  final http.Client _client;
  final Uri _baseUri;

  Uri get versionJsonUri => _baseUri.resolve('apk/version.json');

  Uri downloadUriFor(AppReleaseInfo info) =>
      _baseUri.resolve('apk/${info.apkFileNameOrDefault}');

  Future<AppReleaseInfo?> fetchLatest() async {
    http.Response response;
    try {
      response = await _client
          .get(versionJsonUri)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      return null;
    }
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('version.json is not a JSON object');
    }
    return AppReleaseInfo.fromJson(decoded);
  }
}
