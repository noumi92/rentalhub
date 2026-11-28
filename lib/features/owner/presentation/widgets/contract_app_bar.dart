import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/widgets/minimal_app_bar.dart';

/// Finish build: the contract screen's app bar, extracted from
/// [OwnerContractView] so the view stays under the 250-line cap — the
/// view gained the fare table and the signing section. Download /
/// Share / Print are the same actions the view had inline.
class ContractAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback onDownload;

  const ContractAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MinimalAppBar(
      title: title,
      subtitle: subtitle,
      onBack: onBack,
      actions: [
        IconButton(
          icon: const Icon(Icons.download_rounded, color: Colors.white),
          tooltip: l10n.contractDownloadPdf,
          onPressed: onDownload,
        ),
      ],
    );
  }
}
