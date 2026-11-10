import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../l10n/app_localizations.dart';

/// Compact Terms / Privacy disclaimer at the bottom of the login screen.
///
/// One flowing 11sp paragraph with inline tappable links — the old
/// two-TextButton Wrap cost two 40px rows on a phone-width screen.
/// There is no sign-up affordance here: users are onboarded by the
/// business, there is no self sign-up.
class LoginLegalFooter extends StatefulWidget {
  const LoginLegalFooter({super.key});

  @override
  State<LoginLegalFooter> createState() => _LoginLegalFooterState();
}

class _LoginLegalFooterState extends State<LoginLegalFooter> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push(RouteNames.legalTermsOfService);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push(RouteNames.legalPrivacyPolicy);
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: l10n.authLegalIntro),
          const TextSpan(text: ' '),
          TextSpan(
            text: l10n.authTermsOfService,
            style: TextStyle(color: scheme.primary),
            recognizer: _termsRecognizer,
          ),
          TextSpan(text: ' ${l10n.authLegalAnd} '),
          TextSpan(
            text: l10n.authPrivacyPolicy,
            style: TextStyle(color: scheme.primary),
            recognizer: _privacyRecognizer,
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}
