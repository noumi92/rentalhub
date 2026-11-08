import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/sync_status_section.dart';

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
  String _shopName = '';

  @override
  void initState() {
    super.initState();
    _loadShopName();
  }

  Future<void> _loadShopName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(currentShopId())
          .get();
      final name = (doc.data()?['name'] ?? doc.data()?['shopName']) as String?;
      if (name != null && name.isNotEmpty && mounted) {
        setState(() => _shopName = name);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.compact,
              // Tab root: no back button. The header's back policy
              // renders one only when the route can pop, which a
              // branch root never can.
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.settings,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(l10n.settingsSubtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
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
                        _sectionCard(
                          title: l10n.shop,
                          child: Text(
                            _shopName.isNotEmpty
                                ? _shopName
                                : l10n.shopNotSet,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sectionCard(
                          title: l10n.language,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: Text(l10n.languageEnglish),
                                selected: settings.localeCode == 'en',
                                onSelected: (_) => sl<AppSettingsCubit>()
                                    .setLocale('en'),
                              ),
                              ChoiceChip(
                                label: Text(l10n.languageUrdu),
                                selected: settings.localeCode == 'ur',
                                onSelected: (_) => sl<AppSettingsCubit>()
                                    .setLocale('ur'),
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
                                label: Text(l10n.themeLight),
                                selected:
                                    settings.themeMode == ThemeMode.light,
                                onSelected: (_) => sl<AppSettingsCubit>()
                                    .setThemeMode(ThemeMode.light),
                              ),
                              ChoiceChip(
                                label: Text(l10n.themeDark),
                                selected:
                                    settings.themeMode == ThemeMode.dark,
                                onSelected: (_) => sl<AppSettingsCubit>()
                                    .setThemeMode(ThemeMode.dark),
                              ),
                              ChoiceChip(
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
                        const SyncStatusSection(),
                        const SizedBox(height: 16),
                        _sectionCard(
                          title: l10n.quickLinks,
                          child: Column(
                            children: [
                              _link(context, Icons.route_rounded,
                                  l10n.fixedRoutes, RouteNames.ownerFixedRoutes),
                              _link(context, Icons.shield_rounded,
                                  l10n.blacklist, RouteNames.ownerBlacklist),
                              _link(context, Icons.workspace_premium_rounded,
                                  l10n.subscription, RouteNames.ownerSubscription),
                              _link(context, Icons.chat_rounded,
                                  l10n.whatsappLogs, RouteNames.ownerWhatsappLogs),
                              _link(context, Icons.notifications_rounded,
                                  l10n.notifications, RouteNames.ownerNotifications),
                              _link(context, Icons.report_problem_outlined,
                                  l10n.disputes, RouteNames.ownerDisputes),
                              _link(context, Icons.account_balance_rounded,
                                  l10n.finance, RouteNames.ownerFinance),
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
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) {
                                context.go(RouteNames.auth);
                              }
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(route),
      ),
    );
  }
}
