import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../utils/shop_id_resolution.dart';

/// Unified persistence & auto-fetch for Customer, Owner, and Guarantor
/// signatures stored in Firestore (as base64 PNG with URL fallback).
class SignatureProfileService {
  static FirebaseFirestore? _resolveFs(FirebaseFirestore? fs) {
    if (fs != null) return fs;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static Uint8List? _decodeB64(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> fetchPngUrl(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 || res.bodyBytes.length < 8) return null;
      const pngMagic = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
      for (var i = 0; i < pngMagic.length; i++) {
        if (res.bodyBytes[i] != pngMagic[i]) return null;
      }
      return res.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  /// Loads a customer's saved signature PNG from `customers/{customerId}`.
  static Future<({Uint8List? pngBytes, String? url})> loadCustomerSignature(
    String customerId, {
    FirebaseFirestore? firestore,
  }) async {
    final fs = _resolveFs(firestore);
    if (fs == null || customerId.isEmpty) return (pngBytes: null, url: null);
    try {
      final doc = await fs.collection('customers').doc(customerId).get();
      final data = doc.data();
      if (data == null) return (pngBytes: null, url: null);
      final url = data['signatureUrl'] as String?;
      final b64Png = _decodeB64(data['signatureB64']);
      if (b64Png != null) return (pngBytes: b64Png, url: url);
      final urlPng = await fetchPngUrl(url);
      return (pngBytes: urlPng, url: url);
    } catch (_) {
      return (pngBytes: null, url: null);
    }
  }

  /// Saves a customer's signature PNG onto `customers/{customerId}`.
  static Future<bool> saveCustomerSignature(
    String customerId,
    Uint8List pngBytes, {
    FirebaseFirestore? firestore,
  }) async {
    final fs = _resolveFs(firestore);
    if (fs == null || customerId.isEmpty || pngBytes.isEmpty) return false;
    try {
      await fs.collection('customers').doc(customerId).set({
        'signatureB64': base64Encode(pngBytes),
        'signatureUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Loads the shop owner's saved signature PNG from `shops/{shopDocId}`.
  static Future<({Uint8List? pngBytes, String? url})> loadOwnerSignature(
    String shopId, {
    FirebaseFirestore? firestore,
  }) async {
    final fs = _resolveFs(firestore);
    if (fs == null || shopId.isEmpty) return (pngBytes: null, url: null);
    try {
      final docId = await canonicalShopId(fs, shopId);
      final doc = await fs.collection('shops').doc(docId).get();
      final data = doc.data();
      if (data == null) return (pngBytes: null, url: null);
      final url =
          (data['ownerSignatureUrl'] ?? data['signatureUrl']) as String?;
      final b64Png = _decodeB64(data['ownerSignatureB64']);
      if (b64Png != null) return (pngBytes: b64Png, url: url);
      final urlPng = await fetchPngUrl(url);
      return (pngBytes: urlPng, url: url);
    } catch (_) {
      return (pngBytes: null, url: null);
    }
  }

  /// Saves the shop owner's signature PNG onto `shops/{shopDocId}`.
  static Future<bool> saveOwnerSignature(
    String shopId,
    Uint8List pngBytes, {
    FirebaseFirestore? firestore,
  }) async {
    final fs = _resolveFs(firestore);
    if (fs == null || shopId.isEmpty || pngBytes.isEmpty) return false;
    try {
      final docId = await canonicalShopId(fs, shopId);
      await fs.collection('shops').doc(docId).set({
        'ownerSignatureB64': base64Encode(pngBytes),
        'ownerSignatureUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Loads the guarantor's saved signature PNG from `customers/{customerId}`
  /// (inline `guarantorSignatureB64`) or from the linked `guarantorCustomerId`.
  static Future<({String? name, Uint8List? pngBytes, String? url})>
      loadGuarantorSignature(
    String customerId, {
    String? fallbackName,
    FirebaseFirestore? firestore,
  }) async {
    final fs = _resolveFs(firestore);
    if (fs == null || customerId.isEmpty) {
      return (name: fallbackName, pngBytes: null, url: null);
    }
    var name = fallbackName;
    try {
      final doc = await fs.collection('customers').doc(customerId).get();
      final data = doc.data();
      if (data == null) {
        return (name: name, pngBytes: null, url: null);
      }
      name ??= data['guarantorName'] as String?;
      final inlinePng = _decodeB64(data['guarantorSignatureB64']);
      if (inlinePng != null) {
        return (name: name, pngBytes: inlinePng, url: null);
      }
      final guarantorId = data['guarantorCustomerId'] as String?;
      if (guarantorId == null || guarantorId.isEmpty) {
        return (name: name, pngBytes: null, url: null);
      }
      final gDoc = await fs.collection('customers').doc(guarantorId).get();
      final gData = gDoc.data();
      name ??= (gData?['fullName'] ?? gData?['name']) as String?;
      final url = gData?['signatureUrl'] as String?;
      final gPng =
          _decodeB64(gData?['signatureB64']) ?? await fetchPngUrl(url);
      return (name: name, pngBytes: gPng, url: url);
    } catch (_) {
      return (name: name, pngBytes: null, url: null);
    }
  }

  /// Saves the guarantor's signature PNG onto `customers/{customerId}` (and
  /// onto the linked `guarantorCustomerId` doc if present).
  static Future<bool> saveGuarantorSignature(
    String customerId,
    Uint8List pngBytes, {
    FirebaseFirestore? firestore,
  }) async {
    final fs = _resolveFs(firestore);
    if (fs == null || customerId.isEmpty || pngBytes.isEmpty) return false;
    try {
      final b64 = base64Encode(pngBytes);
      final ref = fs.collection('customers').doc(customerId);
      await ref.set({
        'guarantorSignatureB64': b64,
        'guarantorSignatureUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final snap = await ref.get();
      final linkedId = snap.data()?['guarantorCustomerId'] as String?;
      if (linkedId != null && linkedId.isNotEmpty) {
        await fs.collection('customers').doc(linkedId).set({
          'signatureB64': b64,
          'signatureUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
