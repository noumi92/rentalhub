import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../../customer/data/datasources/dispute_remote_data_source.dart';
import '../../data/datasources/admin_platform_data_source.dart';
import '../widgets/admin_shell.dart';
import '../widgets/dispute_decision_panel.dart';

/// Phase 2 (2.4) — one dispute as a route, like the shop, customer,
/// booking and KYC detail routes: the list navigates here instead of
/// opening the decision sheet, so a dispute is deep-linkable and the
/// back button returns to the centre. The decision form itself is
/// [DisputeDecisionPanel] (shared with the sheet); a saved decision
/// reloads the dispute read-only instead of popping.
class AdminDisputeDetailView extends StatefulWidget {
  const AdminDisputeDetailView({super.key, required this.disputeId, this.loadDispute});

  final String disputeId;

  /// Test seam (data access). Defaults read the real data source;
  /// tests pass a fake so no Firebase/DI is needed.
  final Future<DisputeRecord?> Function(String disputeId)? loadDispute;

  @override
  State<AdminDisputeDetailView> createState() =>
      _AdminDisputeDetailViewState();
}

class _AdminDisputeDetailViewState extends State<AdminDisputeDetailView> {
  DisputeRecord? _dispute;
  bool _isLoading = true;
  bool _hasError = false;
  final _decisionController = DisputeDecisionController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final dispute = await (widget.loadDispute?.call(widget.disputeId) ??
          sl<AdminPlatformDataSource>().getDispute(widget.disputeId));
      if (!mounted) return;
      setState(() {
        _dispute = dispute;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final dispute = _dispute;
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    return AdminShell(
      activeRoute: RouteNames.adminDisputes,
      title: dispute == null
          ? l10n.admin2_disputesTitle
          : l10n.admin2_disputeTitle(dispute.id),
      subtitle: l10n.admin2_disputesSubtitle,
      onRefresh: _load,
      onBack: () => context.go(RouteNames.adminDisputes),
      // Phase 4 (4.4a) — Save decision is the sticky bar now
      // (resolved disputes are read-only, so no bar then).
      bottomBar: dispute == null || dispute.status == 'resolved'
          ? null
          : SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48)),
                onPressed: () => _decisionController.save(),
                child: Text(l10n.admin2_disputeSave),
              ),
            ),
      child: _isLoading
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: l10n.admin2_disputesLoadFailed,
                  onRetry: _load,
                )
              : dispute == null
                  ? AppEmptyState(title: l10n.admin2_disputeDetailNotFound)
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(compact ? 16 : 24),
                      child: DisputeDecisionPanel(
                        // A status change after deciding rebuilds
                        // the panel fresh (read-only form) instead
                        // of reusing the pre-decision controllers.
                        key: ValueKey(
                            '${dispute.id}:${dispute.status}'),
                        dispute: dispute,
                        onDecided: _load,
                        readOnly: dispute.status == 'resolved',
                        popOnDecided: false,
                        controller: _decisionController,
                        showSaveButton: false,
                      ),
                    ),
    );
  }
}
