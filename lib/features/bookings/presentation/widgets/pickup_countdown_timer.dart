import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class PickupCountdownTimer extends StatefulWidget {
  final DateTime targetPickupTime;
  // E3: the label above the digits — the pickup pass counts down to
  // pickup; the active-trip view reuses this for the return.
  final String? label;
  // CU-m8: the label once the target time has passed (the pickup
  // pass passes its "pickup time reached" text, the active-trip view
  // its "return time reached" text). Falls back to a generic
  // "time reached" label when unset.
  final String? overdueLabel;

  const PickupCountdownTimer({
    super.key,
    required this.targetPickupTime,
    this.label,
    this.overdueLabel,
  });

  @override
  State<PickupCountdownTimer> createState() => _PickupCountdownTimerState();
}

class _PickupCountdownTimerState extends State<PickupCountdownTimer> {
  late Timer _timer;
  Duration _remaining = Duration.zero;
  // CU-m8: how long ago the target passed — the digits count UP
  // this once the countdown hits zero, instead of freezing at
  // 00:00:00 forever.
  Duration _overdue = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _calculateRemaining();
    });
  }

  void _calculateRemaining() {
    final diff = widget.targetPickupTime.difference(DateTime.now());
    setState(() {
      if (diff.isNegative) {
        _remaining = Duration.zero;
        _overdue = -diff;
      } else {
        _remaining = diff;
        _overdue = Duration.zero;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // CU-m8: past the target the digits count UP the overdue time
    // under a "time reached" label — never a frozen 00:00:00.
    final isOverdue = _overdue > Duration.zero;
    final shown = isOverdue ? _overdue : _remaining;
    final hours = shown.inHours.toString().padLeft(2, '0');
    final minutes = (shown.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (shown.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isOverdue
                ? (widget.overdueLabel ?? l10n.countdownTimeReached)
                : (widget.label ?? l10n.countdownToPickup),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: AppColors.primaryContainer, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeUnit(hours, l10n.countdownHours),
              _buildColon(),
              _buildTimeUnit(minutes, l10n.countdownMinutes),
              _buildColon(),
              _buildTimeUnit(seconds, l10n.countdownSeconds),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String unit) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: AppColors.primaryContainer),
        ),
      ],
    );
  }

  Widget _buildColon() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        ':',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: Colors.white70),
      ),
    );
  }
}

