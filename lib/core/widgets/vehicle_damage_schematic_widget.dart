import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class DamagePin {
  final String zone; // 'Front', 'Rear', 'Left', 'Right', 'Roof'
  final String type; // 'Scratch', 'Dent', 'Crack'

  const DamagePin({required this.zone, required this.type});
}

class VehicleDamageSchematicWidget extends StatefulWidget {
  final List<DamagePin> initialPins;
  final ValueChanged<List<DamagePin>>? onPinsChanged;

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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.car_crash_rounded,
                    size: 18,
                    color: AppColors.sunsetOrange,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '4-Quadrant Exterior Inspection Schematic',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.midnightNavy,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _pins.isEmpty
                      ? AppColors.emeraldGreen.withValues(alpha: 0.12)
                      : AppColors.amberGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_pins.length} Marks Logged',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _pins.isEmpty
                        ? AppColors.emeraldGreen
                        : AppColors.amberGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap any vehicle quadrant below to pin/unpin pre-existing scratches or dents:',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          // Top-down schematic grid representation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
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
                  backgroundColor: AppColors.crimsonRed.withValues(alpha: 0.1),
                  side: BorderSide(
                    color: AppColors.crimsonRed.withValues(alpha: 0.3),
                  ),
                  avatar: const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppColors.crimsonRed,
                  ),
                  label: Text(
                    '${pin.zone}: ${pin.type}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.crimsonRed,
                    ),
                  ),
                  onDeleted: () => _toggleZone(pin.zone),
                  deleteIconColor: AppColors.crimsonRed,
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
              ? AppColors.crimsonRed.withValues(alpha: 0.14)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: flagged ? AppColors.crimsonRed : AppColors.border,
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
              color: flagged ? AppColors.crimsonRed : AppColors.midnightNavy,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                zone,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: flagged ? FontWeight.w800 : FontWeight.w600,
                  color:
                      flagged ? AppColors.crimsonRed : AppColors.midnightNavy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

