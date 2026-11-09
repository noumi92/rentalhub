import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';

/// Audit item 17/18 (O20, O24): the agreement-PDF actions shared by
/// the contract view and the Agreement Signed screen — share, print,
/// and Download PDF (save to device). Download writes into the app
/// documents directory via `path_provider`, which is already a
/// dependency — no new package is needed. The guarantor signature
/// resolves lazily from Firestore: the booking's customer doc
/// carries `guarantorCustomerId`, and that customer's wizard-saved
/// `signatureUrl` is the signature — never invented; absent means
/// "pending", rendered honestly as such.
class ContractPdfActions {
  /// Shares the agreement PDF through the system share sheet — the
  /// user picks the app (e.g. WhatsApp or email). Nothing is sent
  /// automatically and nothing is claimed to have been sent.
  static Future<void> sharePdf({
    required BuildContext context,
    required String bookingId,
    required Uint8List? bytes,
    String? subject,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (bytes == null) {
      AppFeedback.showError(context, l10n.contractPdfUnavailable);
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        subject: subject,
        files: [
          XFile.fromData(
            bytes,
            name: 'agreement-$bookingId.pdf',
            mimeType: 'application/pdf',
          ),
        ],
        text: l10n.contractShareText(bookingId),
      ),
    );
  }

  /// Reads the explicit-agreement state off `agreements/{bookingId}`
  /// (merge-written by [saveAgreementState]): the "I agree" checkbox
  /// and the guarantor signature captured on the contract view.
  /// Anything unreadable resolves to "not agreed / not signed" —
  /// never an error and never an invented signature.
  static Future<({
    bool agreedToTerms,
    bool fullySigned,
    Uint8List? guarantorSignaturePng,
  })> loadAgreementState({required String bookingId}) async {
    try {
      final fs = FirebaseFirestore.instance;
      final doc = await fs.collection('agreements').doc(bookingId).get();
      final data = doc.data();
      if (data == null) {
        return (agreedToTerms: false, fullySigned: false, guarantorSignaturePng: null);
      }
      final b64 = data['guarantorSignatureB64'] as String?;
      return (
        agreedToTerms: data['agreedToTerms'] == true,
        fullySigned: data['fullySigned'] == true,
        guarantorSignaturePng:
            b64 != null && b64.isNotEmpty ? base64Decode(b64) : null,
      );
    } catch (_) {
      return (agreedToTerms: false, fullySigned: false, guarantorSignaturePng: null);
    }
  }

  /// Persists the explicit-agreement state on `agreements/{bookingId}`
  /// (merge — never clobbers the PDF URL, hash or status written at
  /// handover). Only the fields passed non-null are written. Returns
  /// false when the write failed so the caller can revert its UI.
  static Future<bool> saveAgreementState({
    required String bookingId,
    bool? agreedToTerms,
    Uint8List? guarantorSignaturePng,
    bool? fullySigned,
    Uint8List? agreementPdfB64,
  }) async {
    try {
      final fs = FirebaseFirestore.instance;
      final data = <String, dynamic>{
        'bookingId': bookingId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (agreedToTerms != null) data['agreedToTerms'] = agreedToTerms;
      if (guarantorSignaturePng != null) {
        data['guarantorSignatureB64'] = base64Encode(guarantorSignaturePng);
      }
      if (fullySigned != null) {
        data['fullySigned'] = fullySigned;
        if (fullySigned) data['signedAt'] = FieldValue.serverTimestamp();
      }
      if (agreementPdfB64 != null) {
        data['agreementPdfB64'] = base64Encode(agreementPdfB64);
      }
      await fs.collection('agreements').doc(bookingId).set(
            data,
            SetOptions(merge: true),
          );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> printPdf({
    required BuildContext context,
    required Uint8List? bytes,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (bytes == null) {
      AppFeedback.showError(context, l10n.contractPdfUnavailable);
      return;
    }
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  /// Saves the agreement PDF to the app documents directory and
  /// reports the file name. Returns the saved path, or null when
  /// there was no PDF or the write failed.
  static Future<String?> downloadPdf({
    required BuildContext context,
    required String bookingId,
    required Uint8List? bytes,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (bytes == null) {
      AppFeedback.showError(context, l10n.contractPdfUnavailable);
      return null;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/agreement-$bookingId.pdf');
      await file.writeAsBytes(bytes);
      if (context.mounted) {
        AppFeedback.showSuccess(
            context, l10n.contractPdfDownloaded(file.path.split('/').last));
      }
      return file.path;
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(context, l10n.contractPdfDownloadFailed(e.toString()));
      }
      return null;
    }
  }

  /// The wizard-saved signature of the booking's guarantor, if any.
  /// Returns (guarantorName, signatureUrl); either may be null.
  /// Firestore resolves lazily — without it the answer is "none",
  /// never an error and never a fabricated signature.
  static Future<({String? name, String? signatureUrl})>
      resolveGuarantorSignature({
    required String customerId,
    String? bookingGuarantorName,
  }) async {
    String? name = bookingGuarantorName;
    String? signatureUrl;
    try {
      final fs = FirebaseFirestore.instance;
      final customerDoc =
          await fs.collection('customers').doc(customerId).get();
      final guarantorId =
          customerDoc.data()?['guarantorCustomerId'] as String?;
      if (guarantorId == null || guarantorId.isEmpty) {
        return (name: name, signatureUrl: null);
      }
      final guarantorDoc =
          await fs.collection('customers').doc(guarantorId).get();
      final data = guarantorDoc.data();
      name ??= data?['fullName'] as String? ?? data?['name'] as String?;
      signatureUrl = data?['signatureUrl'] as String?;
    } catch (_) {}
    return (name: name, signatureUrl: signatureUrl);
  }
}
