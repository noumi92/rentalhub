import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';

/// Structured Personal Info tab inside the redesigned customer detail
/// screen: grouped hairline card with leading outline icons for personal
/// details, a dedicated Guarantor Information card (with 1-tap Call and
/// Add/Edit action), and the walk-in Security Wallet card.
class CustomerDetailPersonalTab extends StatelessWidget {
  final CustomerEntity customer;
  final CustomerEntity? guarantor;
  final bool isWalkIn;
  final VoidCallback? onAddOrEditGuarantor;

  const CustomerDetailPersonalTab({
    super.key,
    required this.customer,
    this.guarantor,
    required this.isWalkIn,
    this.onAddOrEditGuarantor,
  });

  Future<void> _call(BuildContext context, String phone) async {
    final l10n = AppLocalizations.of(context)!;
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return;
    if (!await launchUrl(Uri(scheme: 'tel', path: digits)) && context.mounted) {
      AppFeedback.showError(context, l10n.couldNotOpenDialer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final border = brightness == Brightness.dark
        ? cs.outlineVariant
        : AppColors.borderSubtle;

    final personalRows = <(IconData, String, String?)>[
      (Icons.person_outline_rounded, l10n.addCustomerName, customer.name),
      (
        Icons.family_restroom_outlined,
        l10n.kycWizardFatherName,
        customer.fatherName
      ),
      (
        Icons.chat_bubble_outline_rounded,
        l10n.kycWizardWhatsappNumber,
        customer.phone
      ),
      (Icons.badge_outlined, l10n.addCustomerCnic, customer.cnic),
      (Icons.cake_outlined, l10n.kycWizardDateOfBirth, customer.dateOfBirth),
      (Icons.event_outlined, l10n.kycWizardCnicExpiry, customer.cnicExpiry),
      (Icons.location_on_outlined, l10n.kycWizardAddress, customer.address),
      (
        Icons.directions_car_outlined,
        l10n.kycWizardLicenseNumber,
        customer.licenseNumber
      ),
      (
        Icons.event_available_outlined,
        l10n.kycWizardLicenseExpiry,
        customer.licenseExpiry
      ),
    ];

    final gName = (customer.guarantorName?.trim().isNotEmpty ?? false)
        ? customer.guarantorName!.trim()
        : (guarantor?.name.trim() ?? '');
    final gPhone = (customer.guarantorPhone?.trim().isNotEmpty ?? false)
        ? customer.guarantorPhone!.trim()
        : (guarantor?.phone.trim() ?? '');
    final gCnic = (customer.guarantorCnic?.trim().isNotEmpty ?? false)
        ? customer.guarantorCnic!.trim()
        : (guarantor?.cnic?.trim() ?? '');
    final gAddress = (customer.guarantorAddress?.trim().isNotEmpty ?? false)
        ? customer.guarantorAddress!.trim()
        : (guarantor?.address?.trim() ?? '');
    final gRelation = customer.guarantorRelation?.trim();
    final hasGuarantor = gName.isNotEmpty ||
        gPhone.isNotEmpty ||
        gCnic.isNotEmpty ||
        (customer.guarantorCustomerId?.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _surfaceCard(
          context,
          border: border,
          child: Column(
            children: [
              for (var i = 0; i < personalRows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 42,
                    color: border.withValues(alpha: 0.7),
                  ),
                _infoRow(
                  context,
                  icon: personalRows[i].$1,
                  label: personalRows[i].$2,
                  value: personalRows[i].$3,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _surfaceCard(
          context,
          border: border,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.customerDetailGuarantorSection,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (gRelation != null &&
                        gRelation.isNotEmpty &&
                        hasGuarantor)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.successBadgeFor(brightness),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          gRelation,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color:
                                    AppColors.successBadgeTextFor(brightness),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: border.withValues(alpha: 0.7)),
              if (!hasGuarantor)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.customerDetailNoGuarantor,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                      if (onAddOrEditGuarantor != null)
                        TextButton.icon(
                          key: const ValueKey('customer_add_guarantor_btn'),
                          onPressed: onAddOrEditGuarantor,
                          style: TextButton.styleFrom(
                            foregroundColor:
                                AppColors.orangeTextFor(brightness),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(l10n.customerDetailAddGuarantor),
                        ),
                    ],
                  ),
                )
              else ...[
                _infoRow(
                  context,
                  icon: Icons.person_outline_rounded,
                  label: l10n.guarantorNameLabel,
                  value:
                      gName.isNotEmpty ? gName : customer.guarantorCustomerId,
                ),
                Divider(
                    height: 1,
                    indent: 42,
                    color: border.withValues(alpha: 0.7)),
                _infoRow(
                  context,
                  icon: Icons.phone_outlined,
                  label: l10n.guarantorPhoneLabel,
                  value: gPhone,
                  trailing: gPhone.isNotEmpty
                      ? IconButton(
                          tooltip: l10n.call,
                          icon: Icon(
                            Icons.call_outlined,
                            size: 18,
                            color: AppColors.orangeTextFor(brightness),
                          ),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _call(context, gPhone),
                        )
                      : null,
                ),
                Divider(
                    height: 1,
                    indent: 42,
                    color: border.withValues(alpha: 0.7)),
                _infoRow(
                  context,
                  icon: Icons.badge_outlined,
                  label: l10n.guarantorCnicLabel,
                  value: gCnic,
                ),
                Divider(
                    height: 1,
                    indent: 42,
                    color: border.withValues(alpha: 0.7)),
                _infoRow(
                  context,
                  icon: Icons.location_on_outlined,
                  label: l10n.guarantorAddressLabel,
                  value: gAddress,
                ),
              ],
            ],
          ),
        ),
        if (isWalkIn) ...[
          const SizedBox(height: 14),
          _surfaceCard(
            context,
            border: border,
            child: ListTile(
              leading:
                  const Icon(Icons.account_balance_wallet_outlined, size: 20),
              title: Text(
                l10n.customerDetailSecurityWallet,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              onTap: () => context.push(
                RouteNames.ownerCustomerSecurityWallet
                    .replaceFirst(':id', customer.customerId),
                extra: customer,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _surfaceCard(
    BuildContext context, {
    required Color border,
    required Widget child,
  }) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String? value,
    Widget? trailing,
  }) {
    final cs = Theme.of(context).colorScheme;
    final text = (value == null || value.trim().isEmpty) ? '—' : value.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              text,
              textAlign: TextAlign.end,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
