import 'package:flutter/material.dart';

import '../../../customer/data/datasources/dispute_remote_data_source.dart';
import 'dispute_decision_panel.dart';

export 'dispute_decision_panel.dart' show disputeDecisionLabel;

/// The D2 decision sheet for one dispute — a thin wrapper: the form
/// itself is [DisputeDecisionPanel], shared with the dispute detail
/// route (Phase 2, 2.4), so the sheet and the route never drift.
/// The sheet keeps the drag handle and the pop-on-decide behaviour;
/// the detail route keeps the panel on screen and reloads instead.
class DisputeDecisionSheet extends StatelessWidget {
  const DisputeDecisionSheet({
    super.key,
    required this.dispute,
    required this.onDecided,
    this.readOnly = false,
  });

  final DisputeRecord dispute;
  final VoidCallback onDecided;

  /// AD-M10: a resolved dispute opens read-only — the decision,
  /// amount and note are shown, nothing can be changed.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        child: DisputeDecisionPanel(
          dispute: dispute,
          onDecided: onDecided,
          readOnly: readOnly,
        ),
      ),
    );
  }
}
