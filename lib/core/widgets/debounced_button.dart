import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

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

  String get displayLabel => text ?? label ?? 'Submit';
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
        backgroundColor: widget.backgroundColor ?? AppColors.secondary,
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
                    widget.displayLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
