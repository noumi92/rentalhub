import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';

/// WhatsApp dispatch log (O67/O70) — gated on D2 (Meta/WhatsApp).
/// There is no dispatch-records collection yet, so this screen renders
/// the honest empty state instead of sample entries, and the Resend
/// action is gone until a real dispatch exists to resend. The
/// `WhatsAppLogTile` widget is kept in place unused for that future
/// real list (the push cannot carry file deletions).
class OwnerWhatsAppLogsView extends StatelessWidget {
  final VoidCallback? onBack;

  const OwnerWhatsAppLogsView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.whatsappLogsTitle,
              onBack: onBack,
            ),
            Expanded(
              child: AppEmptyState(
                title: l10n.whatsappLogsEmpty,
                icon: Icons.chat_bubble_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
