import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/customer_remote_data_source.dart';
import '../../domain/entities/customer_entity.dart';
import '../widgets/profile_sign_out_tile.dart';
import '../widgets/settings_section_card.dart';

// H2: the settings that do what they say. Language and theme go through
// AppSettingsCubit (the owner G3 pattern — this is the second
// translated screen), notification preferences persist on the
// customer's own record, and the version comes from the installed
// package, not a hardcoded string. The dead Terms/Privacy tiles are
// gone — there is no such content in the app.
class CustomerSettingsView extends StatefulWidget {
  final VoidCallback? onSignOut;
  final VoidCallback? onBack;

  const CustomerSettingsView({super.key, this.onSignOut, this.onBack});

  @override
  State<CustomerSettingsView> createState() => _CustomerSettingsViewState();
}

class _CustomerSettingsViewState extends State<CustomerSettingsView> {
  CustomerEntity? _customer;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    String version = '';
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    CustomerEntity? customer;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && sl.isRegistered<CustomerRemoteDataSource>()) {
        customer = await sl<CustomerRemoteDataSource>().getCustomerById(uid);
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _version = version;
        _customer = customer;
      });
    }
  }

  Future<void> _setNotifications({
    bool? push,
    bool? whatsapp,
  }) async {
    final customer = _customer;
    if (customer == null) return;
    final updated = customer.copyWith(
      pushNotifications: push ?? customer.pushNotifications,
      whatsappNotifications: whatsapp ?? customer.whatsappNotifications,
    );
    setState(() => _customer = updated);
    try {
      await sl<CustomerRemoteDataSource>().upsertCustomer(updated);
    } catch (_) {
      if (mounted) setState(() => _customer = customer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customer = _customer;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.customerSettings,
              onBack: widget.onBack,
            ),
            Expanded(
              child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
                bloc: sl<AppSettingsCubit>(),
                builder: (context, settings) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingsSectionCard(
                          title: l10n.language,
                          child: Row(
                            children: [
                              ChoiceChip(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.padded,
                                label: Text(l10n.languageEnglish),
                                selected: settings.localeCode == 'en',
                                onSelected: (_) =>
                                    sl<AppSettingsCubit>().setLocale('en'),
                              ),
                              const SizedBox(width: 8),
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
                        SettingsSectionCard(
                          title: l10n.theme,
                          child: Row(
                            children: [
                              ChoiceChip(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.padded,
                                label: Text(l10n.themeLight),
                                selected: settings.themeMode == ThemeMode.light,
                                onSelected: (_) => sl<AppSettingsCubit>()
                                    .setThemeMode(ThemeMode.light),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.padded,
                                label: Text(l10n.themeDark),
                                selected: settings.themeMode == ThemeMode.dark,
                                onSelected: (_) => sl<AppSettingsCubit>()
                                    .setThemeMode(ThemeMode.dark),
                              ),
                              const SizedBox(width: 8),
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
                        SettingsSectionCard(
                          title: l10n.notifications,
                          child: Column(
                            children: [
                              SwitchListTile(
                                activeThumbColor: AppColors.secondary,
                                title: Text(l10n.pushNotifications,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                    l10n.settingsPushSubtitle,
                                    style:
                                        Theme.of(context).textTheme.labelSmall),
                                // CU-m7: while no customer record has
                                // loaded the switch defaults to OFF, not
                                // ON — a disabled switch must not claim
                                // the preference is enabled.
                                value: customer?.pushNotifications ?? false,
                                onChanged: customer == null
                                    ? null
                                    : (val) => _setNotifications(push: val),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                activeThumbColor: AppColors.secondary,
                                title: Text(l10n.whatsappNotifications,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                    l10n.settingsWhatsappSubtitle,
                                    style:
                                        Theme.of(context).textTheme.labelSmall),
                                value: customer?.whatsappNotifications ?? false,
                                onChanged: customer == null
                                    ? null
                                    : (val) => _setNotifications(whatsapp: val),
                              ),
                              if (customer == null)
                                Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    l10n.settingsNotifNote,
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SettingsSectionCard(
                          title: l10n.appVersion,
                          child: Text(
                            _version.isEmpty ? '—' : _version,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SettingsSectionCard(
                          title: l10n.syncDetailsTitle,
                          child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.sync_rounded), title: Text(l10n.syncDetailsTitle), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => context.push(RouteNames.syncDetails)),
                        ),
                        const SizedBox(height: 16),
                        ProfileSignOutTile(onTap: widget.onSignOut),
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
}
