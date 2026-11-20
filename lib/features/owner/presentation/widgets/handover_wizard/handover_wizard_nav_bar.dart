import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/debounced_button.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../handover/presentation/cubit/handover_wizard_cubit.dart';

/// Item 9 (O26–O30): the wizard's bottom navigation — Back /
/// Continue on steps 0–3, "Car Handed Over" on step 4. Extracted
/// so the shell stays under the 250-line cap. The Continue gate
/// lives in [HandoverWizardCubit.nextStep] (balance due / deposit
/// passed in by the shell); the shell owns finalize.
class HandoverWizardNavBar extends StatelessWidget {
  final int balanceDue;
  final int securityDeposit;
  final VoidCallback onFinalize;

  const HandoverWizardNavBar({
    super.key,
    required this.balanceDue,
    required this.securityDeposit,
    required this.onFinalize,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<HandoverWizardCubit, HandoverWizardState>(
      builder: (context, state) {
        if (state.completed != null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              if (state.step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context
                        .read<HandoverWizardCubit>()
                        .previousStep(),
                    child: Text(l10n.commonGoBack),
                  ),
                ),
              if (state.step > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DebouncedButton(
                  text: state.step == 4
                      ? l10n.handoverWizardHandedOver
                      : l10n.packageContinue,
                  icon: state.step == 4
                      ? Icons.assignment_turned_in_rounded
                      : Icons.arrow_forward_rounded,
                  isLoading: state.isFinalizing,
                  onPressed: state.step == 4
                      ? onFinalize
                      : () => context.read<HandoverWizardCubit>().nextStep(
                          balanceDue: balanceDue,
                          securityDeposit: securityDeposit),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
