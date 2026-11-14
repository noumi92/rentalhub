import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../blacklist/data/datasources/blacklist_remote_data_source.dart';

/// Admin final pass (2026-11-10) — the customer-facing half of the
/// blacklist appeal flow.
///
/// Worker 1 added `BlacklistRemoteDataSource.submitAppeal` (writes
/// `appeal_status: 'pending'` + reason on the `blacklist` document
/// the tribunal reads) but nothing in the app called it. This sheet
/// is the entry point: the profile shows it when the customer is
/// blacklisted, the customer writes a reason, and the appeal is
/// filed. The record stays active until the tribunal decides.
///
/// `onSubmit` is an injectable seam for tests (the real data source
/// needs Firestore, which widget tests do not have); production
/// callers leave it null and the sheet uses the registered data
/// source. Returns true from [showBlacklistAppealSheet] when the
/// appeal was filed.
class BlacklistAppealSheet extends StatefulWidget {
  const BlacklistAppealSheet({
    super.key,
    required this.blacklistId,
    this.onSubmit,
  });

  final String blacklistId;

  /// Filed the appeal; returns true when the write landed. Defaults
  /// to `BlacklistRemoteDataSource.submitAppeal`.
  final Future<bool> Function(String reason)? onSubmit;

  @override
  State<BlacklistAppealSheet> createState() => _BlacklistAppealSheetState();
}

class _BlacklistAppealSheetState extends State<BlacklistAppealSheet> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<bool> _submit(String reason) async {
    if (widget.onSubmit != null) return widget.onSubmit!(reason);
    if (!sl.isRegistered<BlacklistRemoteDataSource>()) return false;
    return sl<BlacklistRemoteDataSource>().submitAppeal(
      blacklistId: widget.blacklistId,
      reason: reason,
    );
  }

  Future<void> _onSubmitPressed() async {
    final l10n = AppLocalizations.of(context)!;
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      AppFeedback.showError(context, l10n.appealReasonRequired);
      return;
    }
    setState(() => _isSubmitting = true);
    final filed = await _submit(reason);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (filed) {
      AppFeedback.showSuccess(context, l10n.appealSuccess);
      Navigator.of(context).pop(true);
    } else {
      AppFeedback.showError(context, l10n.appealError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.appealTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.appealIntro,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.appealReasonLabel,
                hintText: l10n.appealReasonHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DebouncedButton(
              label: l10n.appealSubmit,
              isLoading: _isSubmitting,
              onPressed: _onSubmitPressed,
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the appeal sheet for [blacklistId]. Returns true when the
/// appeal was filed, false/null otherwise.
Future<bool?> showBlacklistAppealSheet(
  BuildContext context, {
  required String blacklistId,
  Future<bool> Function(String reason)? onSubmit,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlacklistAppealSheet(
      blacklistId: blacklistId,
      onSubmit: onSubmit,
    ),
  );
}
