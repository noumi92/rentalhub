import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';

/// Audit §5 finish (P2-1): one generic legal-text screen for the two
/// documents linked from the login footer. Top-level route (no shell,
/// no tab bar). The bodies are real RentalHub text — short, honest,
/// placeholder-free — held in .arb keys [legalTermsBody] /
/// [legalPrivacyBody] so both languages ship.
enum LegalDocument { terms, privacy }

class LegalTextView extends StatelessWidget {
  final LegalDocument document;
  final VoidCallback? onBack;

  const LegalTextView({super.key, required this.document, this.onBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTerms = document == LegalDocument.terms;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: isTerms
                  ? l10n.authTermsOfService
                  : l10n.authPrivacyPolicy,
              onBack: onBack ?? () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  isTerms ? l10n.legalTermsBody : l10n.legalPrivacyBody,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
