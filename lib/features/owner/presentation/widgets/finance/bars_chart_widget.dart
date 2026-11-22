import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../l10n/app_localizations.dart';

/// Audit impl (O38/O45): a small bar chart built from Flutter
/// primitives only — no chart dependency. Bars scale to the largest
/// value; a zero max renders flat bars, never a divide-by-zero.
/// [values] are whole rupees; [labels] are the short axis labels.
class BarsChartWidget extends StatelessWidget {
  final List<String> labels;
  final List<int> values;

  const BarsChartWidget({
    super.key,
    required this.labels,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final max = values.fold<int>(0, (m, v) => v > m ? v : m);
    final height = 140.0;
    final barColor = AppColors.primaryTextFor(Theme.of(context).brightness);
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (values[i] > 0)
                        Text(
                          l10n.amountRs(formatRs(values[i])),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      const SizedBox(height: 4),
                      Container(
                        height: max == 0
                            ? 2
                            : (values[i] / max * height).clamp(2, height),
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
