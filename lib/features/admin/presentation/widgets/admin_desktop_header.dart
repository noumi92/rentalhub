import 'package:flutter/material.dart';

class AdminDesktopHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRefresh;

  const AdminDesktopHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Admin final pass (2026-11-10): the title is one
                // line with an ellipsis — the 41-character tribunal
                // title wrapped to two lines in this fixed 70dp
                // header and overflowed at 2.0x text scale. At
                // normal scales nothing changes; per-view title
                // shortening is no longer the fix.
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text(subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Refresh',
              onPressed: onRefresh,
            ),
        ],
      ),
    );
  }
}

