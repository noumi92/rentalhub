import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/card_decoration.dart';
import '../../../../core/widgets/masked_value.dart';
import '../../../../l10n/app_localizations.dart';

/// Unified Personal Details card on the Customer Profile tab.
///
/// Omits Name and Email (already shown in [ProfileHeader] directly above),
/// folds the masked CNIC directly into the card, uses an RTL- and
/// 200%-text-scale-friendly stacked layout, and displays a compact
/// profile-completion prompt whenever optional details are missing.
class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({
    super.key,
    required this.phone,
    required this.cnic,
    required this.dateOfBirth,
    required this.fatherName,
    required this.address,
    this.onEdit,
  });

  final String phone;
  final String cnic;
  final String? dateOfBirth;
  final String? fatherName;
  final String? address;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final dob = (dateOfBirth ?? '').trim();
    final father = (fatherName ?? '').trim();
    final addr = (address ?? '').trim();
    final cleanPhone = phone.trim();
    final cleanCnic = cnic.trim();

    final fields = [cleanPhone, cleanCnic, dob, father, addr];
    final completed = fields.where((v) => v.isNotEmpty).length;
    final total = fields.length;

    final rows = <Widget>[
      if (cleanPhone.isNotEmpty)
        _DetailRow(
          icon: Icons.phone_outlined,
          label: l10n.editPhone,
          value: cleanPhone,
        ),
      if (cleanCnic.isNotEmpty)
        _MaskedCnicDetailRow(cnic: cleanCnic),
      if (dob.isNotEmpty)
        _DetailRow(
          icon: Icons.cake_outlined,
          label: l10n.editDateOfBirth,
          value: dob,
        ),
      if (father.isNotEmpty)
        _DetailRow(
          icon: Icons.person_outline_rounded,
          label: l10n.editFatherName,
          value: father,
        ),
      if (addr.isNotEmpty)
        _DetailRow(
          icon: Icons.location_on_outlined,
          label: l10n.editAddress,
          value: addr,
        ),
    ];

    return Container(
      decoration: AppCardDecoration.of(context, radius: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.profileIdentityTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (onEdit != null && completed == total)
                IconButton(
                  tooltip: l10n.profileEditProfile,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onEdit,
                ),
            ],
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (var i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i < rows.length - 1)
                const Divider(height: 16, thickness: 0.8),
            ],
          ],
          if (completed < total && onEdit != null) ...[
            if (rows.isNotEmpty) const SizedBox(height: 14),
            if (rows.isEmpty) const SizedBox(height: 10),
            _CompletionBanner(
              completed: completed,
              total: total,
              isRtl: isRtl,
              onTap: onEdit!,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MaskedCnicDetailRow extends StatelessWidget {
  const _MaskedCnicDetailRow({required this.cnic});

  final String cnic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.badge_outlined, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.cnicLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              MaskedValue(
                value: cnic,
                maskedValue: MaskedValue.maskCnic(cnic),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                showTooltip: l10n.cnicShow,
                hideTooltip: l10n.cnicHide,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  const _CompletionBanner({
    required this.completed,
    required this.total,
    required this.isRtl,
    required this.onTap,
  });

  final int completed;
  final int total;
  final bool isRtl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final bg = AppColors.orangeContainerFor(brightness);
    final fg = AppColors.orangeOnContainerFor(brightness);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.profileCompleteTitle,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(
                    isRtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    size: 18,
                    color: fg,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                l10n.profileCompleteProgress(completed, total),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: fg.withValues(alpha: 0.85),
                    ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : completed / total,
                  minHeight: 5,
                  backgroundColor: fg.withValues(alpha: 0.16),
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
