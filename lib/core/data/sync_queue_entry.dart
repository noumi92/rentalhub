import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Phase B (B3): one unit of work that must reach the server.
///
/// A queue entry survives a restart (the queue is SharedPreferences-
/// backed) and is never deleted until the server confirms the work.
/// Retries are safe: [idempotencyKey] is derived from the kind,
/// the entity id and the payload hash, so enqueueing the same work
/// twice yields the same entry instead of a duplicate — and a retry
/// after a partial success resumes from [result] (e.g. an already
/// uploaded file's URL) instead of repeating the completed step.
///
/// [payload] is JSON. It carries either document fields (a Firestore
/// write) or a file reference (`filePath` for a file copied into the
/// queue dir, or `fileB64` for a small file stored inline) plus the
/// upload target (`folder`, `targetCollection`, `targetDocId`,
/// `targetField`).
/// jsonEncode's `toEncodable` hook for payloads: every model in this
/// codebase already serializes dates as ISO strings in toMap(), but a
/// raw DateTime must never crash an offline write — it becomes the
/// same ISO string. Anything else unknown is left for jsonEncode to
/// reject loudly rather than silently corrupting the record.
Object? encodeJsonValue(Object? value) =>
    value is DateTime ? value.toIso8601String() : value;

class SyncQueueEntry {
  /// `<kind>:<entityId>:<first 12 hex of the idempotency key>`.
  final String id;
  final String kind;
  final String entityId;
  final Map<String, dynamic> payload;
  final String idempotencyKey;
  final int attempts;
  final DateTime createdAt;
  final DateTime? nextRetryAt;
  final String? lastError;

  /// Outputs of steps already completed (e.g. `{'remoteUrl': ...}`).
  /// Handlers read this to resume instead of repeating work.
  final Map<String, dynamic> result;

  /// Optional dedupe scope: entries sharing a [dedupeKey] are the
  /// same logical work (e.g. one upload for one document field).
  /// Enqueueing with the same key replaces the older entry, so a
  /// re-submitted file supersedes the previous one instead of
  /// queueing a duplicate upload.
  final String? dedupeKey;

  const SyncQueueEntry({
    required this.id,
    required this.kind,
    required this.entityId,
    required this.payload,
    required this.idempotencyKey,
    required this.attempts,
    required this.createdAt,
    this.nextRetryAt,
    this.lastError,
    this.result = const {},
    this.dedupeKey,
  });

  /// The entry is in its terminal retry state: it has exhausted its
  /// fast backoff and is kept queued, visible as failed, retrying
  /// slowly — never silently dropped.
  bool get isExhausted => attempts >= SyncQueueEntry.maxAttempts;

  static const int maxAttempts = 5;

  static String computeIdempotencyKey(
    String kind,
    String entityId,
    Map<String, dynamic> payload,
  ) {
    final bytes = utf8.encode(
      '$kind|$entityId|${jsonEncode(payload, toEncodable: encodeJsonValue)}',
    );
    return sha256.convert(bytes).toString();
  }

  static String computeId(String kind, String entityId, String key) =>
      '$kind:$entityId:${key.substring(0, 12)}';

  factory SyncQueueEntry.create({
    required String kind,
    required String entityId,
    required Map<String, dynamic> payload,
    String? dedupeKey,
  }) {
    final key = computeIdempotencyKey(kind, entityId, payload);
    return SyncQueueEntry(
      id: computeId(kind, entityId, key),
      kind: kind,
      entityId: entityId,
      payload: Map<String, dynamic>.from(payload),
      idempotencyKey: key,
      attempts: 0,
      createdAt: DateTime.now(),
      dedupeKey: dedupeKey,
    );
  }

  SyncQueueEntry copyWith({
    int? attempts,
    DateTime? nextRetryAt,
    String? lastError,
    Map<String, dynamic>? result,
    bool clearNextRetryAt = false,
    bool clearLastError = false,
  }) {
    return SyncQueueEntry(
      id: id,
      kind: kind,
      entityId: entityId,
      payload: payload,
      idempotencyKey: idempotencyKey,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt,
      nextRetryAt:
          clearNextRetryAt ? null : (nextRetryAt ?? this.nextRetryAt),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      result: result ?? this.result,
      dedupeKey: dedupeKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'entityId': entityId,
        'payload': payload,
        'idempotencyKey': idempotencyKey,
        'attempts': attempts,
        'createdAt': createdAt.toIso8601String(),
        'nextRetryAt': nextRetryAt?.toIso8601String(),
        'lastError': lastError,
        'result': result,
        'dedupeKey': dedupeKey,
      };

  factory SyncQueueEntry.fromJson(Map<String, dynamic> json) {
    return SyncQueueEntry(
      id: json['id'] as String,
      kind: json['kind'] as String,
      entityId: json['entityId'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      idempotencyKey: json['idempotencyKey'] as String,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      nextRetryAt: json['nextRetryAt'] != null
          ? DateTime.parse(json['nextRetryAt'] as String)
          : null,
      lastError: json['lastError'] as String?,
      result: json['result'] != null
          ? Map<String, dynamic>.from(json['result'] as Map)
          : const {},
      dedupeKey: json['dedupeKey'] as String?,
    );
  }
}
