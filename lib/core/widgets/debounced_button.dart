import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_dimensions.dart';
import '../../l10n/app_localizations.dart';

class DebouncedButton extends StatefulWidget {
  final String? text;
  final String? label;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final Duration debounceDuration;
  final int? debounceMs;

  const DebouncedButton({
    super.key,
    this.text,
    this.label,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.debounceDuration = const Duration(milliseconds: 400),
    this.debounceMs,
  });

  // Phase F: the no-label fallback is the localized 'Submit'
  // (English fallback for delegate-less pumps). Callers always pass
  // a label in practice; this only covers a bare button.
  String displayLabel(BuildContext context) =>
      text ?? label ?? AppLocalizations.of(context)?.commonSubmit ?? 'Submit';
  Duration get effectiveDuration => debounceMs != null
      ? Duration(milliseconds: debounceMs!)
      : debounceDuration;

  @override
  State<DebouncedButton> createState() => _DebouncedButtonState();
}

class _DebouncedButtonState extends State<DebouncedButton> {
  bool _isLocked = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    if (_isLocked || widget.isLoading) return;

    // E2: a light impact on the primary CTA tap.
    HapticFeedback.lightImpact();
    setState(() => _isLocked = true);
    widget.onPressed();

    _debounceTimer = Timer(widget.effectiveDuration, () {
      if (mounted) {
        setState(() => _isLocked = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: (widget.isLoading || _isLocked) ? null : _handleTap,
      style: ElevatedButton.styleFrom(
        // Theme secondary in both modes (light orange / dark orange);
        // the old hardcoded light secondary was wrong in dark mode.
        backgroundColor:
            widget.backgroundColor ?? Theme.of(context).colorScheme.secondary,
        foregroundColor: widget.textColor ?? Colors.white,
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
        ),
      ),
      child: widget.isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.displayLabel(context),
                    overflow: TextOverflow.ellipsis,
                    // No theme text colour here: the label must take the
                    // button's foregroundColor (white). The old titleSmall
                    // colour forced onSurface text onto the orange button.
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: widget.textColor ?? Colors.white,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
