import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/utils/sign_out_confirm_dialog.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/notification_preferences_section.dart';
import '../widgets/shop_profile_card.dart';
import '../widgets/sync_status_section.dart';
import '../../../../core/theme/card_decoration.dart';

/// Phase B (G3): the owner settings screen. The language and theme
/// choices are real — they persist in SharedPreferences and the
/// whole app rebuilds with the new locale (Urdu flips the layout
/// to RTL) and theme. The screen's own strings come from the
/// `.arb` files, so switching to Urdu translates it immediately.
class OwnerSettingsView extends StatefulWidget {
  const OwnerSettingsView({super.key});

  @override
  State<OwnerSettingsView> createState() => _OwnerSettingsViewState();
}

class _OwnerSettingsViewState extends State<OwnerSettingsView> {

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.settings,
              subtitle: l10n.settingsSubtitle,
            ),
            Expanded(
              child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
                bloc: sl<AppSettingsCubit>(),
                builder: (context, settings) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Audit §5 (O33): owner name + avatar above
                        // the shop name (was shop-name-only).
                        const ShopProfileCard(),
                        const SizedBox(height: 16),
                        _sectionCard(
                          title: l10n.language,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.padded,
                                label: Text(l10n.languageEnglish),
                                selected: settings.localeCode == 'en',
                                onSelected: (_) =>
                                    sl<AppSettingsCubit>().setLocale('en'),
                              ),
                              ChoiceChip(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.padded,
                                label: Text(l10n.languageUrdu),
                                selected: settings.localeCode == 'ur',
                                onSelected: (_) =>
                                    sl<AppSettingsCubit>().setLocale('ur'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sectionCard(
                          title: l10n.theme,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.padded,
                                label: Text(l10n.themeLight),
                                selected: settings.themeMode == ThemeMode.light,
                                onSelected: (_) => sl<AppSettingsCubit>()
                                    .setThemeMode(ThemeMode.light),
                              ),
                              ChoiceChip(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.padded,
                                label: Text(l10n.themeDark),
                                selected: settings.themeMode == ThemeMode.dark,
                                onSelected: (_) => sl<AppSettingsCubit>()
                                    .setThemeMode(ThemeMode.dark),
                              ),
                              ChoiceChip(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.padded,
                                label: Text(l10n.themeSystem),
                                selected:
                                    settings.themeMode == ThemeMode.system,
                                onSelected: (_) => sl<AppSettingsCubit>()
                                    .setThemeMode(ThemeMode.system),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Audit impl (O33): persisted notification
                        // toggles — which in-app notification types
                        // the owner wants (toggles only, no dispatch).
                        const NotificationPreferencesSection(),
                        const SizedBox(height: 16),
                        const SyncStatusSection(),
                        const SizedBox(height: 16),
                        _sectionCard(
                          title: l10n.quickLinks,
                          child: Column(
                            children: [
                              _link(context, Icons.storefront_rounded,
                                  l10n.fleetShopSettings, RouteNames.ownerShopSettings),
                              _link(context, Icons.route_rounded,
                                  l10n.fixedRoutes, RouteNames.ownerFixedRoutes),
                              _link(context, Icons.shield_rounded,
                                  l10n.blacklist, RouteNames.ownerBlacklist),
                              _link(context, Icons.workspace_premium_rounded,
                                  l10n.subscription, RouteNames.ownerSubscription),
                              _link(context, Icons.chat_rounded,
                                  l10n.whatsappLogs, RouteNames.ownerWhatsappLogs),
                              // Audit impl (worker E): WhatsApp Credits
                              // sits next to the WhatsApp Logs link.
                              _link(context, Icons.message_rounded,
                                  l10n.creditsTitle, RouteNames.ownerWhatsappCredits),
                              _link(context, Icons.notifications_rounded,
                                  l10n.notifications, RouteNames.ownerNotifications),
                              _link(context, Icons.sync_rounded,
                                  l10n.syncDetailsTitle, RouteNames.syncDetails),
                              _link(context, Icons.report_problem_outlined,
                                  l10n.disputes, RouteNames.ownerDisputes),
                              _link(context, Icons.account_balance_rounded,
                                  l10n.finance, RouteNames.ownerFinance),
                              // Audit impl (worker C): finance settings +
                              // categories, staff & roles, reset options.
                              _link(context, Icons.tune_rounded,
                                  l10n.financeSettingsTitle, RouteNames.ownerFinanceSettings),
                              _link(context, Icons.category_rounded,
                                  l10n.financeCategoriesTitle, RouteNames.ownerFinanceCategories),
                              _link(context, Icons.group_rounded,
                                  l10n.staffTitle, RouteNames.ownerStaffRoles),
                              _link(context, Icons.restart_alt_rounded,
                                  l10n.resetTitle, RouteNames.ownerResetOptions),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.logout_rounded),
                            label: Text(l10n.signOut),
                            onPressed: () async {
                              // Audit impl (worker C, O49): confirm
                              // first; on confirm sign out (same
                              // repository path as signOutToAuth, same
                              // error feedback) and land on the
                              // signed-out screen instead of /auth.
                              final confirmed =
                                  await showSignOutConfirmDialog(context);
                              if (!confirmed || !context.mounted) return;
                              try {
                                await sl<AuthRepository>().signOut();
                              } catch (_) {
                                if (!context.mounted) return;
                                AppFeedback.showError(
                                  context,
                                  l10n.ownerSignOutError,
                                );
                                return;
                              }
                              if (!context.mounted) return;
                              context.go(RouteNames.ownerSignedOut);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Audit §23 (Critical): hardcoded white made the card's theme
        // text invisible in dark mode.
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _link(
      BuildContext context, IconData icon, String label, String route) {
    // Audit §23: the chevron flips in RTL (Urdu) so it still points
    // forward.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: Icon(isRtl
            ? Icons.chevron_left_rounded
            : Icons.chevron_right_rounded),
        onTap: () => context.push(route),
      ),
    );
  }
}
