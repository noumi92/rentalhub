import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Day-detail status chip for the booking calendar.
///
/// Round 4, light-theme contrast: in LIGHT theme the label is onSurface
/// on the pale container with a 1.5px strong status border — the light
/// on-container tokens (success 2.41:1, warning 2.07:1, error 3.44:1 on
/// their containers) are not legible as chip text. Dark theme keeps its
/// existing container/on-container pair (light text on a dark container)
/// and no border, byte-identical to before. The mapping lives in
/// [colorsFor] so tests can assert the measured contrast without pumping
/// the whole calendar view (whose bookings come from DI).
class CalendarStatusChip extends StatelessWidget {
  final String status;
  final String label;

  const CalendarStatusChip({
    super.key,
    required this.status,
    required this.label,
  });

  /// Pure colour mapping for one booking status. [onSurface] and
  /// [surfaceContainerHighest] come from the ambient theme (the callers
  /// pass `Theme.of(context).colorScheme` values); [border] is null in
  /// dark theme and for unknown statuses.
  static ({Color background, Color label, Color? border}) colorsFor({
    required Brightness brightness,
    required String status,
    required Color onSurface,
    required Color surfaceContainerHighest,
  }) {
    final isLight = brightness == Brightness.light;
    switch (status) {
      case 'completed':
      case 'active':
      case 'approved':
      case 'paid':
        return (
          background: AppColors.successContainerFor(brightness),
          label: isLight
              ? onSurface
              : AppColors.successOnContainerFor(brightness),
          border: isLight ? AppColors.accentSuccessStrong : null,
        );
      case 'requested':
      case 'payment_submitted':
        return (
          background: AppColors.warningContainerFor(brightness),
          label: isLight
              ? onSurface
              : AppColors.warningOnContainerFor(brightness),
          border: isLight ? AppColors.orangeTextFor(brightness) : null,
        );
      case 'rejected':
      case 'cancelled':
        return (
          background: AppColors.errorContainerFor(brightness),
          label: isLight
              ? onSurface
              : AppColors.errorOnContainerFor(brightness),
          border: isLight ? AppColors.errorDark : null,
        );
      default:
        return (
          background: surfaceContainerHighest,
          label: onSurface,
          border: null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = colorsFor(
      brightness: Theme.of(context).brightness,
      status: status,
      onSurface: scheme.onSurface,
      surfaceContainerHighest: scheme.surfaceContainerHighest,
    );
    return Chip(
      backgroundColor: c.background,
      side: c.border == null
          ? null
          : BorderSide(color: c.border!, width: 1.5),
      label: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: c.label, fontWeight: FontWeight.w500)),
    );
  }
}
