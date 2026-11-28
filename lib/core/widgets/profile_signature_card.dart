import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../widgets/app_feedback.dart';

/// Reusable editable signature card for Customer KYC (walk-in & online),
/// Owner KYC/Shop Settings, and Guarantor personal data.
/// Auto-loads the saved signature; if none exists (or when Edit is tapped),
/// displays a scratch pad to draw and save directly to Firestore.
class ProfileSignatureCard extends StatefulWidget {
  const ProfileSignatureCard({
    super.key,
    required this.title,
    this.subtitle,
    this.initialPng,
    this.onLoad,
    required this.onSave,
    this.readOnly = false,
  });

  final String title;
  final String? subtitle;
  final Uint8List? initialPng;
  final Future<Uint8List?> Function()? onLoad;
  final Future<bool> Function(Uint8List pngBytes) onSave;
  final bool readOnly;

  @override
  State<ProfileSignatureCard> createState() => _ProfileSignatureCardState();
}

class _ProfileSignatureCardState extends State<ProfileSignatureCard> {
  final _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  Uint8List? _savedPng;
  bool _loading = false;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _savedPng = widget.initialPng;
    if (_savedPng == null && widget.onLoad != null) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final png = await widget.onLoad!();
      if (mounted) setState(() => _savedPng = png);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final bytes = await _controller.toPngBytes();
      if (bytes == null || bytes.isEmpty) return;
      final ok = await widget.onSave(bytes);
      if (!mounted) return;
      if (ok) {
        setState(() {
          _savedPng = bytes;
          _editing = false;
        });
        _controller.clear();
        AppFeedback.showSuccess(
          context,
          AppLocalizations.of(context)?.agreementWizardSaved ?? 'Saved',
        );
      } else {
        AppFeedback.showError(
          context,
          AppLocalizations.of(context)?.shopSaveError ?? 'Could not save.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showPad = !widget.readOnly && (_editing || _savedPng == null);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? cs.outlineVariant : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.draw_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (!widget.readOnly && _savedPng != null && !_editing)
                TextButton.icon(
                  onPressed: () => setState(() => _editing = true),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(l10n?.customerDetailEdit ?? 'Edit'),
                ),
            ],
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.subtitle!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 10),
          if (_loading)
            const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (!showPad && _savedPng != null)
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.memory(_savedPng!, fit: BoxFit.contain),
            )
          else if (showPad) ...[
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Signature(
                controller: _controller,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (_savedPng != null)
                    TextButton(
                      onPressed: () {
                        _controller.clear();
                        setState(() => _editing = false);
                      },
                      child: Text(l10n?.cancel ?? 'Cancel'),
                    ),
                  TextButton.icon(
                    onPressed: _controller.clear,
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    label: Text(l10n?.handoverClear ?? 'Clear'),
                  ),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 16),
                    label: Text(l10n?.admin2_save ?? 'Save'),
                  ),
                ],
              ),
            ),
          ] else
            Text(
              l10n?.manualBookingNoSignature ?? 'No signature on file',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
