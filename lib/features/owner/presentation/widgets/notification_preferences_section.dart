import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';

/// Audit impl (O33): the owner settings notifications section —
///
/// one persisted toggle per notification type (booking requests,
/// payment proofs, handover, return, maintenance reminder).
/// Toggles only: they record which in-app notification types the
/// owner wants; they do not send anything (no new dispatch, and
/// WhatsApp stays gated on Phase I). Persistence follows the
/// language/theme pattern — [AppSettingsCubit] + SharedPreferences.
class NotificationPreferencesSection extends StatelessWidget {
  const NotificationPreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      bloc: sl<AppSettingsCubit>(),
      builder: (context, settings) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppCardDecoration.shadow(context)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.notifications,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              _toggle(
                context,
                label: l10n.settingsNotifyBookingRequests,
                value: settings.notifyBookingRequests,
                onChanged: (v) => sl<AppSettingsCubit>()
                    .setNotificationPreference(
                        NotificationPreference.bookingRequests, v),
              ),
              _toggle(
                context,
                label: l10n.settingsNotifyPaymentProofs,
                value: settings.notifyPaymentProofs,
                onChanged: (v) => sl<AppSettingsCubit>()
                    .setNotificationPreference(
                        NotificationPreference.paymentProofs, v),
              ),
              _toggle(
                context,
                label: l10n.settingsNotifyHandover,
                value: settings.notifyHandover,
                onChanged: (v) => sl<AppSettingsCubit>()
                    .setNotificationPreference(
                        NotificationPreference.handover, v),
              ),
              _toggle(
                context,
                label: l10n.settingsNotifyReturns,
                value: settings.notifyReturns,
                onChanged: (v) => sl<AppSettingsCubit>()
                    .setNotificationPreference(
                        NotificationPreference.returns, v),
              ),
              _toggle(
                context,
                label: l10n.settingsNotifyMaintenance,
                value: settings.notifyMaintenance,
                onChanged: (v) => sl<AppSettingsCubit>()
                    .setNotificationPreference(
                        NotificationPreference.maintenance, v),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _toggle(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    // The tile paints its ink on the nearest Material ancestor; the
    // decorated Container above would hide it, so each toggle gets
    // its own transparent Material (debug assertion).
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title:
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
