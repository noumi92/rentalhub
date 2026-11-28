import '../../../../../l10n/app_localizations.dart';

/// Item 9 (O26–O30): the wizard cubit's error codes rendered as
/// user-facing messages. Extracted from the wizard shell so the
/// shell stays under the 250-line cap.
String handoverWizardErrorMessage(AppLocalizations l10n, String code) {
  switch (code) {
    case 'face':
      return l10n.handoverWizardFaceRequired;
    case 'payment':
      return l10n.handoverWizardPaymentRequired;
    case 'payment_confirm':
      return l10n.handoverWizardBalanceConfirmRequired;
    case 'deposit':
      return l10n.handoverWizardDepositMethodRequired;
    case 'deposit_confirm':
      return l10n.handoverWizardDepositConfirmRequired;
    case 'checklist':
      return l10n.handoverWizardChecklistRequired;
    case 'signatures':
      return l10n.handoverSignRequired;
    default:
      return code;
  }
}
