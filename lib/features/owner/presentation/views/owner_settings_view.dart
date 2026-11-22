import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/utils/sign_out_confirm_dialog.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/widgets/delete_account_section.dart';
import '../widgets/notification_preferences_section.dart';
import '../widgets/shop_profile_card.dart';
import '../../../../core/theme/card_decoration.dart';

/// Phase B (G3): the owner settings screen. Language and theme persist in SharedPreferences and the whole app rebuilds with the new locale (Urdu flips the layout to RTL) and theme; the screen's own strings come from the `.arb` files, so switching to Urdu translates it immediately. Showroom redesign Phase 4 (2026-11-16): the "Showroom Owner" card on top (with a shortcut to the shop editor), language + theme as two side-by-side cards — a dropdown pill for the language, a Light | Dark | System segmented switch for the theme (System is kept) — and the remaining rows grouped into an Operations card and an Account & Alerts card. Every row keeps its old target and carries a 36x36 pastel circular icon badge. The five notification toggles stay in the bottom sheet opened by the Notifications row, with the link to the list below.
class OwnerSettingsView extends StatefulWidget {
  const OwnerSettingsView({super.key});

  @override
  State<OwnerSettingsView> createState() => _OwnerSettingsViewState();
}

/// One pastel badge colour per row, from the existing container tokens — never a hardcoded hex. Dark legs come from the matching `*For(brightness)` helpers / dark container tokens.
enum _BadgeKind { orange, green, red, amber, navy, grey }

class _OwnerSettingsViewState extends State<OwnerSettingsView> {

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(children: [
          MinimalAppBar(title: l10n.settings, subtitle: l10n.settingsSubtitle),
          Expanded(
            child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
              bloc: sl<AppSettingsCubit>(),
              builder: (context, settings) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const ShopProfileCard(),
                    const SizedBox(height: 16),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _languageCard(context, settings)), const SizedBox(width: 12), Expanded(child: _themeCard(context, settings))]),
                    const SizedBox(height: 16),
                    _groupCard(context, title: l10n.settingsOperations, children: [
                      _link(context, _BadgeKind.orange, Icons.storefront_rounded, l10n.fleetShopSettings, RouteNames.ownerShopSettings),
                      _link(context, _BadgeKind.navy, Icons.route_rounded, l10n.fixedRoutes, RouteNames.ownerFixedRoutes),
                      _link(context, _BadgeKind.green, Icons.account_balance_rounded, l10n.finance, RouteNames.ownerFinance),
                      _link(context, _BadgeKind.grey, Icons.tune_rounded, l10n.financeSettingsTitle, RouteNames.ownerFinanceSettings),
                      _link(context, _BadgeKind.green, Icons.drive_eta_rounded, l10n.bookingSettingsTitle, RouteNames.ownerBookingSettings),
                      _link(context, _BadgeKind.amber, Icons.category_rounded, l10n.financeCategoriesTitle, RouteNames.ownerFinanceCategories),
                      _link(context, _BadgeKind.red, Icons.shield_rounded, l10n.blacklist, RouteNames.ownerBlacklist),
                      _link(context, _BadgeKind.navy, Icons.group_rounded, l10n.staffTitle, RouteNames.ownerStaffRoles),
                      _link(context, _BadgeKind.orange, Icons.report_problem_outlined, l10n.disputes, RouteNames.ownerDisputes),
                    ]),
                    const SizedBox(height: 16),
                    _groupCard(context, title: l10n.settingsAccountAlerts, children: [
                      _row(context, _BadgeKind.orange, Icons.notifications_rounded, l10n.notifications, onTap: _openNotificationsSheet),
                      _link(context, _BadgeKind.navy, Icons.sync_rounded, l10n.syncDetailsTitle, RouteNames.syncDetails),
                      _link(context, _BadgeKind.amber, Icons.workspace_premium_rounded, l10n.subscription, RouteNames.ownerSubscription),
                      _link(context, _BadgeKind.green, Icons.chat_rounded, l10n.whatsappLogs, RouteNames.ownerWhatsappLogs),
                      _link(context, _BadgeKind.grey, Icons.message_rounded, l10n.creditsTitle, RouteNames.ownerWhatsappCredits),
                      _link(context, _BadgeKind.red, Icons.restart_alt_rounded, l10n.resetTitle, RouteNames.ownerResetOptions),
                    ]),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(l10n.signOut),
                        onPressed: () async {
                          // Audit impl (worker C, O49): confirm first; on confirm sign out (same repository path as signOutToAuth, same error feedback) and land on the signed-out screen instead of /auth.
                          final confirmed = await showSignOutConfirmDialog(context);
                          if (!confirmed || !context.mounted) return;
                          try {
                            await sl<AuthRepository>().signOut();
                          } catch (_) {
                            if (!context.mounted) return;
                            AppFeedback.showError(context, l10n.ownerSignOutError);
                            return;
                          }
                          if (!context.mounted) return;
                          context.go(RouteNames.ownerSignedOut);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    const DeleteAccountTile(isOwner: true),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _cardLabel(BuildContext context, IconData icon, String label) {
    return Row(children: [Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(width: 8), Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)))]);
  }

  Widget _languageCard(BuildContext context, AppSettingsState settings) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: AppCardDecoration.of(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel(context, Icons.language_rounded, l10n.language),
        const SizedBox(height: 12),
        Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: dark ? AppColors.borderDark : AppColors.borderSubtle), borderRadius: BorderRadius.circular(999)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: settings.localeCode,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: [DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)), DropdownMenuItem(value: 'ur', child: Text(l10n.languageUrdu))],
              onChanged: (code) { if (code != null) unawaited(sl<AppSettingsCubit>().setLocale(code)); },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _themeCard(BuildContext context, AppSettingsState settings) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final modes = <(ThemeMode, String)>[(ThemeMode.light, l10n.themeLight), (ThemeMode.dark, l10n.themeDark), (ThemeMode.system, l10n.themeSystem)];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: AppCardDecoration.of(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardLabel(context, Icons.palette_rounded, l10n.theme),
        const SizedBox(height: 12),
        Container(
          height: 48,
          decoration: BoxDecoration(border: Border.all(color: dark ? AppColors.borderDark : AppColors.borderSubtle), borderRadius: BorderRadius.circular(999)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Row(children: [for (final (mode, label) in modes) Expanded(child: _themeSegment(context, label: label, selected: settings.themeMode == mode, onTap: () => unawaited(sl<AppSettingsCubit>().setThemeMode(mode))))]),
          ),
        ),
      ]),
    );
  }

  Widget _themeSegment(BuildContext context, {required String label, required bool selected, required VoidCallback onTap}) {
    // FittedBox scales the label down instead of overflowing at 320px / large text scales.
    return Material(color: selected ? AppColors.orangeFill : Colors.transparent, child: InkWell(onTap: onTap, child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface))))));
  }

  Widget _groupCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(16, 14, 16, 8), decoration: AppCardDecoration.of(context), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)), const SizedBox(height: 6), ...children]));
  }

  Widget _row(BuildContext context, _BadgeKind badge, IconData icon, String label, {required VoidCallback onTap}) {
    // Same row language as before: pastel badge, bold label, chevron trailing (chevron flips in RTL so it still points forward).
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Material(color: Colors.transparent, child: ListTile(contentPadding: EdgeInsets.zero, leading: _iconBadge(context, badge, icon), title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)), trailing: Icon(isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded), onTap: onTap));
  }

  Widget _link(BuildContext context, _BadgeKind badge, IconData icon, String label, String route, {VoidCallback? onTap}) {
    return _row(context, badge, icon, label, onTap: onTap ?? () => context.push(route));
  }

  Widget _iconBadge(BuildContext context, _BadgeKind kind, IconData icon) {
    final colors = _badgeColors(Theme.of(context).brightness, kind);
    return Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: colors.bg), child: Icon(icon, size: 20, color: colors.fg));
  }

  ({Color bg, Color fg}) _badgeColors(Brightness brightness, _BadgeKind kind) {
    return switch (kind) {
      _BadgeKind.orange => (bg: AppColors.orangeContainerFor(brightness), fg: AppColors.orangeOnContainerFor(brightness)),
      _BadgeKind.green => (bg: AppColors.successContainerFor(brightness), fg: AppColors.successOnContainerFor(brightness)),
      _BadgeKind.red => (bg: AppColors.errorContainerFor(brightness), fg: AppColors.errorOnContainerFor(brightness)),
      _BadgeKind.amber => (bg: AppColors.warningContainerFor(brightness), fg: AppColors.warningOnContainerFor(brightness)),
      _BadgeKind.navy => (bg: brightness == Brightness.dark ? AppColors.primaryContainerOnDark : AppColors.primaryContainer, fg: brightness == Brightness.dark ? AppColors.onSurfaceDark : AppColors.primary),
      _BadgeKind.grey => (bg: brightness == Brightness.dark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevated, fg: brightness == Brightness.dark ? AppColors.onSurfaceVariantDark : AppColors.onSurfaceVariantLight),
    };
  }

  void _openNotificationsSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // The five persisted toggles, reused as-is — the notifications list itself is one tap away below.
            const NotificationPreferencesSection(),
            const SizedBox(height: 4),
            _link(sheetContext, _BadgeKind.orange, Icons.notifications_rounded, l10n.notifications, RouteNames.ownerNotifications, onTap: () {
              Navigator.of(sheetContext).pop();
              context.push(RouteNames.ownerNotifications);
            }),
          ]),
        ),
      ),
    );
  }
}
