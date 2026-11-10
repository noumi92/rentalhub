import 'package:flutter/material.dart';

import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/card_decoration.dart';

/// G1: the support screen's FAQ list (search-filtered). Extracted from
/// [CustomerSupportView] so the view stays under the 250-line cap.
class SupportFaqList extends StatelessWidget {
  const SupportFaqList({super.key, required this.faqs});

  final List<Map<String, String>> faqs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.supportFaqTitle,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        // E2: a search that matches nothing renders the shared empty
        // state instead of a bare heading with nothing under it.
        if (faqs.isEmpty)
           AppEmptyState(
            title: l10n.supportFaqEmpty,
            message: l10n.supportFaqEmptyHint,
            icon: Icons.search_off_rounded,
          )
        else
          ...faqs.map((faq) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppCardDecoration.shadow(context)
                ),
                child: ExpansionTile(
                  shape: const Border(),
                  title: Text(
                    faq['q']!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        faq['a']!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(height: 1.45),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
