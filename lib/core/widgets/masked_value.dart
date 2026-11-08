import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// E1: a sensitive value (money, CNIC) that stays masked until the
/// user taps the eye — and re-masks on the second tap. Masked by
/// default: the real value is never painted until the user asks for it.
///
/// Pass [maskedValue] for a domain-shaped mask (e.g. a CNIC that keeps
/// its first block and check digit), or leave it out and every digit
/// is replaced with a bullet — 'Rs. 125000' becomes 'Rs. ••••••'.
class MaskedValue extends StatefulWidget {
  const MaskedValue({
    super.key,
    required this.value,
    this.maskedValue,
    this.style,
    this.iconColor,
    this.iconSize = 20,
    this.showTooltip,
    this.hideTooltip,
    this.initiallyMasked = true,
  });

  /// The real value, shown only while revealed.
  final String value;

  /// What to show while masked. Defaults to [maskDigits] of [value].
  final String? maskedValue;

  /// Text style for the value (masked and revealed alike).
  final TextStyle? style;

  /// Colour of the eye icon. Defaults to the theme's
  /// `onSurfaceVariant`, so callers on dark surfaces (the wallet's
  /// navy card) pass an explicit light colour instead.
  final Color? iconColor;

  final double iconSize;

  /// Eye-toggle tooltips. When unset they resolve to the localized
  /// 'Show/Hide value' (English fallback for delegate-less pumps).
  /// Callers with a specific value (wallet balance, escrow amount,
  /// CNIC) pass their own localized tooltip instead.
  final String? showTooltip;
  final String? hideTooltip;
  final bool initiallyMasked;

  /// Masks every digit with a bullet, keeping separators and any
  /// currency prefix: 'Rs. 125000' → 'Rs. ••••••',
  /// '35202-1234567-1' → '•••••-•••••••-•'.
  static String maskDigits(String value) =>
      value.replaceAll(RegExp(r'[0-9]'), '•');

  /// CNIC-shaped mask: keeps the first block and the check digit,
  /// masks the middle: '35202-1234567-1' → '35202-•••••••-1'.
  /// Falls back to [maskDigits] for anything that is not a
  /// `XXXXX-XXXXXXX-X` CNIC.
  static String maskCnic(String cnic) {
    final parts = cnic.split('-');
    if (parts.length == 3) {
      return '${parts[0]}-${'•' * parts[1].length}-${parts[2]}';
    }
    return maskDigits(cnic);
  }

  @override
  State<MaskedValue> createState() => _MaskedValueState();
}

class _MaskedValueState extends State<MaskedValue> {
  late bool _revealed = !widget.initiallyMasked;

  @override
  Widget build(BuildContext context) {
    final displayed = _revealed
        ? widget.value
        : (widget.maskedValue ?? MaskedValue.maskDigits(widget.value));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            displayed,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          ),
        ),
        IconButton(
          icon: Icon(
            _revealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          ),
          iconSize: widget.iconSize,
          color: widget.iconColor ??
              Theme.of(context).colorScheme.onSurfaceVariant,
          tooltip: _revealed
              ? widget.hideTooltip ??
                  AppLocalizations.of(context)?.commonHideValue ??
                  'Hide value'
              : widget.showTooltip ??
                  AppLocalizations.of(context)?.commonShowValue ??
                  'Show value',
          onPressed: () => setState(() => _revealed = !_revealed),
        ),
      ],
    );
  }
}
