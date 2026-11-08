import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';

class DamagePin {
  final String zone; // 'Front', 'Rear', 'Left', 'Right', 'Roof'
  final String type; // 'Scratch', 'Dent', 'Crack'

  const DamagePin({required this.zone, required this.type});
}

class VehicleDamageSchematicWidget extends StatefulWidget {
  final List<DamagePin> initialPins;
  final ValueChanged<List<DamagePin>>? onPinsChanged;

  // Available vehicle inspection zones
  static const List<String> zones = [
    'Front Bumper',
    'Hood / Bonnet',
    'Left Fender',
    'Right Fender',
    'Roof Panel',
    'Rear Left Door',
    'Rear Right Door',
    'Rear Trunk / Bumper',
  ];

  const VehicleDamageSchematicWidget({
    super.key,
    this.initialPins = const [
      DamagePin(zone: 'Front Bumper', type: 'Minor Scratch'),
      DamagePin(zone: 'Rear Left Door', type: 'Small Dent'),
    ],
    this.onPinsChanged,
  });

  @override
  State<VehicleDamageSchematicWidget> createState() =>
      _VehicleDamageSchematicWidgetState();
}

class _VehicleDamageSchematicWidgetState
    extends State<VehicleDamageSchematicWidget> {
  late List<DamagePin> _pins;

  @override
  void initState() {
    super.initState();
    _pins = List<DamagePin>.from(widget.initialPins);
  }

  void _toggleZone(String zone) {
    setState(() {
      final existingIdx = _pins.indexWhere((p) => p.zone == zone);
      if (existingIdx >= 0) {
        _pins.removeAt(existingIdx);
      } else {
        _pins.add(DamagePin(zone: zone, type: 'Scratch / Mark'));
      }
    });
    widget.onPinsChanged?.call(_pins);
  }

  bool _hasPin(String zone) => _pins.any((p) => p.zone == zone);

  @override
  Widget build(BuildContext context) {
    // Phase F: the schematic chrome is localized (English fallback
    // for delegate-less pumps). The zone/type strings stay as stored
    // data values — they are the pin identity, not copy.
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.car_crash_rounded,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    l10n?.damageSchematicTitle ??
                        '4-Quadrant Exterior Inspection Schematic',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _pins.isEmpty
                      ? AppColors.accentSuccess.withValues(alpha: 0.12)
                      : AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n?.damageMarksLogged(_pins.length) ??
                      '${_pins.length} Mark${_pins.length == 1 ? '' : 's'} Logged',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _pins.isEmpty
                        ? AppColors.accentSuccess
                        : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n?.damageTapHint ??
                'Tap any vehicle quadrant below to pin/unpin pre-existing scratches or dents:',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 12),
          // Top-down schematic grid representation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                _buildZoneButton('Front Bumper', Icons.keyboard_double_arrow_up_rounded),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildZoneButton('Left Fender', Icons.arrow_left_rounded),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: _buildZoneButton('Hood / Bonnet', Icons.shield_outlined),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildZoneButton('Right Fender', Icons.arrow_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildZoneButton('Rear Left Door', Icons.sensor_door_outlined),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: _buildZoneButton('Roof Panel', Icons.crop_square_rounded),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildZoneButton('Rear Right Door', Icons.sensor_door_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildZoneButton('Rear Trunk / Bumper', Icons.keyboard_double_arrow_down_rounded),
              ],
            ),
          ),
          if (_pins.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _pins.map((pin) {
                return Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.accentDanger.withValues(alpha: 0.1),
                  side: BorderSide(
                    color: AppColors.accentDanger.withValues(alpha: 0.3),
                  ),
                  avatar: Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppColors.dangerTextFor(Theme.of(context).brightness),
                  ),
                  label: Text(
                    '${pin.zone}: ${pin.type}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.dangerTextFor(Theme.of(context).brightness),
                    ),
                  ),
                  onDeleted: () => _toggleZone(pin.zone),
                  deleteIconColor: AppColors.dangerTextFor(Theme.of(context).brightness),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildZoneButton(String zone, IconData icon) {
    final bool flagged = _hasPin(zone);
    return InkWell(
      onTap: () => _toggleZone(zone),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: flagged
              ? AppColors.accentDanger.withValues(alpha: 0.14)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: flagged ? AppColors.accentDanger : Theme.of(context).dividerColor,
            width: flagged ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              flagged ? Icons.warning_amber_rounded : icon,
              size: 14,
              color: flagged ? AppColors.accentDanger : AppColors.primary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                zone,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: flagged ? FontWeight.w800 : FontWeight.w600,
                  color:
                      flagged ? AppColors.accentDanger : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

