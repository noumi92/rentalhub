import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

class CitySelectorBar extends StatelessWidget {
  final List<Map<String, dynamic>> majorCities;
  final String selectedCity;
  final ValueChanged<Map<String, dynamic>> onSelectCity;

  const CitySelectorBar({
    super.key,
    required this.majorCities,
    required this.selectedCity,
    required this.onSelectCity,
  });

  @override
  Widget build(BuildContext context) {
    // E3: 48dp chip + 6dp vertical padding each side — the old
    // 48dp bar squeezed the city chips to 36dp.
    // DS-1: no per-file selected fill — the selected chip wears the
    // single theme token (chipTheme.selectedColor), so this file
    // sets no selectedColor / selected side / selected label colour.
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: Theme.of(context).colorScheme.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: majorCities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final city = majorCities[index];
          final isSelected = selectedCity == city['name'];
          return ChoiceChip(
            materialTapTargetSize: MaterialTapTargetSize.padded,
            label: Text(city['name'] as String),
            selected: isSelected,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            side: BorderSide(
              color: Theme.of(context).dividerColor,
            ),
            onSelected: (_) => onSelectCity(city),
          );
        },
      ),
    );
  }
}

/// F-R1: the city picker is a bottom sheet, not a row. Search field
/// on top, "All cities" first, then the 11 major cities as a plain
/// list with a checkmark on the selected one. [majorCities] is the
/// `shopsCityMenuEntries` list ("All cities" first); [selectedCity]
/// is the display name of the current selection.
Future<void> showCityPickerBottomSheet({
  required BuildContext context,
  required List<Map<String, dynamic>> majorCities,
  required String selectedCity,
  required ValueChanged<Map<String, dynamic>> onSelectCity,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _CityPickerSheet(
      majorCities: majorCities,
      selectedCity: selectedCity,
      onSelectCity: onSelectCity,
    ),
  );
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({
    required this.majorCities,
    required this.selectedCity,
    required this.onSelectCity,
  });

  final List<Map<String, dynamic>> majorCities;
  final String selectedCity;
  final ValueChanged<Map<String, dynamic>> onSelectCity;

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? widget.majorCities
        : widget.majorCities
            .where((c) => (c['name'] as String)
                .toLowerCase()
                .contains(query))
            .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: l10n.shops_searchCities,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final city = visible[index];
                  final name = city['name'] as String;
                  final isSelected = widget.selectedCity == name;
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(name),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      widget.onSelectCity(city);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
