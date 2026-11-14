import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Phase E (E2): the three shared feedback states every screen renders
/// instead of its own ad-hoc spinner / bare `Text('No ...')` / silent
/// failure. Colours come from the theme only, so both light and dark
/// modes stay readable; nothing here hardcodes a light surface.
///
/// - [AppLoadingState]: a screen's loading UI.
/// - [AppEmptyState]: a screen's (or section's) empty list, with an
///   optional action (e.g. "Browse shops", "Add Vehicle").
/// - [AppErrorState]: a load failure, with a retry button whenever a
///   retry action exists — pass [onRetry] and the button appears.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.message});

  /// Optional one-line caption under the spinner, e.g.
  /// 'Finding nearby shops…'.
  final String? message;

  @override
  Widget build(BuildContext context) {
    // E3: scrollable — at 200% text scale the icon + title +
    // message + action is taller than a short viewport, and the
    // fixed Column overflowed (up to 150px on the Requests tab).
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 12),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.add_rounded,
  });

  /// The headline, e.g. 'No bookings found.'
  final String title;

  /// Optional supporting line under the headline.
  final String? message;

  /// Leading icon; defaults to an inbox.
  final IconData icon;

  /// When both [actionLabel] and [onAction] are set, a filled action
  /// button renders under the text.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Icon for the action button; defaults to a "+" for add-style
  /// actions (pass e.g. [Icons.document_scanner_rounded] for scan).
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // E3: scrollable — at 200% text scale the icon + title +
    // message + action is taller than a short viewport, and the
    // fixed Column overflowed (up to 150px on the Requests tab).
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              if (message != null) ...[
                const SizedBox(height: 4),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon, size: 18),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  /// What went wrong, e.g. 'Could not load your bookings.'
  final String message;

  /// When set, a retry button renders under the message.
  final VoidCallback? onRetry;

  /// Retry button label; defaults to the localized 'Retry' when
  /// unset (English fallback for delegate-less pumps).
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // E3: scrollable — at 200% text scale the icon + title +
    // message + action is taller than a short viewport, and the
    // fixed Column overflowed (up to 150px on the Requests tab).
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 52, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(retryLabel ??
                      AppLocalizations.of(context)?.commonRetry ??
                      'Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
