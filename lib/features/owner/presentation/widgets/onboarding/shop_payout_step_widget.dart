import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class ShopPayoutStepWidget extends StatelessWidget {
  final bool jazzCashEnabled;
  final ValueChanged<bool> onJazzCashToggle;
  final TextEditingController jazzCashAccount;
  final TextEditingController jazzCashTitle;

  final bool easyPaisaEnabled;
  final ValueChanged<bool> onEasyPaisaToggle;
  final TextEditingController easyPaisaAccount;
  final TextEditingController easyPaisaTitle;

  final bool bankEnabled;
  final ValueChanged<bool> onBankToggle;
  final String selectedBankName;
  final ValueChanged<String> onBankNameChanged;
  final List<String> pakistaniBanks;
  final TextEditingController bankAccountController;
  final TextEditingController bankAccountTitle;

  const ShopPayoutStepWidget({
    super.key,
    required this.jazzCashEnabled,
    required this.onJazzCashToggle,
    required this.jazzCashAccount,
    required this.jazzCashTitle,
    required this.easyPaisaEnabled,
    required this.onEasyPaisaToggle,
    required this.easyPaisaAccount,
    required this.easyPaisaTitle,
    required this.bankEnabled,
    required this.onBankToggle,
    required this.selectedBankName,
    required this.onBankNameChanged,
    required this.pakistaniBanks,
    required this.bankAccountController,
    required this.bankAccountTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payout Accounts & Settlement',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Select at least one payout channel to receive rental bookings and customer advance deposits.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),

        // JazzCash Card (Initially disabled)
        _buildWalletCard(
          context: context,
          title: 'JazzCash Mobile Account',
          subtitle: 'Instant mobile wallet payout',
          isEnabled: jazzCashEnabled,
          onToggle: onJazzCashToggle,
          iconColor: const Color(0xFFE11D48),
          accountController: jazzCashAccount,
          titleController: jazzCashTitle,
          accountLabel: 'JazzCash Mobile Number',
          hintAccount: '03001234567',
        ),
        const SizedBox(height: 12),

        // EasyPaisa Card (Initially disabled)
        _buildWalletCard(
          context: context,
          title: 'EasyPaisa Wallet Account',
          subtitle: 'Instant digital wallet payout',
          isEnabled: easyPaisaEnabled,
          onToggle: onEasyPaisaToggle,
          iconColor: const Color(0xFF16A34A),
          accountController: easyPaisaAccount,
          titleController: easyPaisaTitle,
          accountLabel: 'EasyPaisa Mobile Number',
          hintAccount: '03457654321',
        ),
        const SizedBox(height: 12),

        // Bank Account Card (Requirement 6: Bank Name, Account No, Account Title)
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: bankEnabled ? AppColors.secondary : Theme.of(context).dividerColor,
              width: bankEnabled ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance_rounded, color: Color(0xFF0284C7), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Direct Commercial Bank', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                          Text('1-Link / IBAN direct bank settlement', style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ),
                    Switch(
                      value: bankEnabled,
                      activeThumbColor: AppColors.secondary,
                      onChanged: onBankToggle,
                    ),
                  ],
                ),
                if (bankEnabled) ...[
                  const Divider(height: 20),
                  // Bank Name Dropdown
                  Text('Select Bank Name', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        value: selectedBankName,
                        isExpanded: true,
                        items: pakistaniBanks.map((b) => DropdownMenuItem(value: b, child: Text(b, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)))).toList(),
                        onChanged: (v) {
                          if (v != null) onBankNameChanged(v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Account Number / IBAN
                  Text('Account Number / IBAN', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: bankAccountController,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      hintText: 'e.g. PK36MEZN0001234567890123',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Account Title
                  Text('Account Title (Business / Owner)', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: bankAccountTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      hintText: 'e.g. Al-Falah Rent a Car',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
    required Color iconColor,
    required TextEditingController accountController,
    required TextEditingController titleController,
    required String accountLabel,
    required String hintAccount,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isEnabled ? AppColors.secondary : Theme.of(context).dividerColor,
          width: isEnabled ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.wallet_rounded, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
                Switch(value: isEnabled, activeThumbColor: AppColors.secondary, onChanged: onToggle),
              ],
            ),
            if (isEnabled) ...[
              const Divider(height: 20),
              TextField(
                controller: accountController,
                keyboardType: TextInputType.phone,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  labelText: accountLabel,
                  hintText: hintAccount,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleController,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  labelText: 'Account Title',
                  hintText: 'Ahmed Raza',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

