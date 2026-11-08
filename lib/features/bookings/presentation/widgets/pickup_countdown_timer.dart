import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class PickupCountdownTimer extends StatefulWidget {
  final DateTime targetPickupTime;
  // E3: the label above the digits — the pickup pass counts down to
  // pickup; the active-trip view reuses this for the return.
  final String? label;

  const PickupCountdownTimer({
    super.key,
    required this.targetPickupTime,
    this.label,
  });

  @override
  State<PickupCountdownTimer> createState() => _PickupCountdownTimerState();
}

class _PickupCountdownTimerState extends State<PickupCountdownTimer> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

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
      _remaining = diff.isNegative ? Duration.zero : diff;
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
    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final minutes = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

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
            (widget.label ?? l10n.countdownToPickup),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryContainer, letterSpacing: 1.2),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primaryContainer),
        ),
      ],
    );
  }

  Widget _buildColon() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        ':',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white70),
      ),
    );
  }
}

