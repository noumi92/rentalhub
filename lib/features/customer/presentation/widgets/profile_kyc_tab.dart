import 'package:flutter/material.dart';

import '../../../trust/domain/entities/kyc_document_entity.dart';
import '../../../trust/presentation/views/widgets/kyc_documents_panel.dart';

// Profile hub (2026-11-25): the "Documents & KYC" tab — the shared
// KYC panel in a card. Extracted from CustomerProfileView so the view
// stays under the 250-line cap.
class ProfileKycTab extends StatelessWidget {
  final KycDocumentEntity? existing;
  final String initialCnic;
  final String? rejectionReason;
  final bool loading;
  final bool signedOut;
  final String userUid;
  final Future<void> Function(String cnic) onSubmitted;
  final Future<void> Function() onRetry;

  const ProfileKycTab({
    super.key,
    required this.existing,
    required this.initialCnic,
    required this.rejectionReason,
    required this.loading,
    required this.signedOut,
    required this.userUid,
    required this.onSubmitted,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: KycDocumentsPanel(
            existing: existing,
            initialCnic: initialCnic,
            rejectionReason: rejectionReason,
            loading: loading,
            signedOut: signedOut,
            userUid: userUid,
            onSubmitted: onSubmitted,
            onRetry: onRetry,
          ),
        ),
      ),
    );
  }
}
