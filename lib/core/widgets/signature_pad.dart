import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class SignaturePadWidget extends StatefulWidget {
  final String signerLabel;
  final String signerName;
  final ValueChanged<bool>? onSignedChange;

  const SignaturePadWidget({
    super.key,
    required this.signerLabel,
    required this.signerName,
    this.onSignedChange,
  });

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  final List<Offset?> _points = [];
  bool _isSigned = false;

  void _clear() {
    setState(() {
      _points.clear();
      _isSigned = false;
    });
    widget.onSignedChange?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    // Phase F: the pad chrome is localized (English fallback for
    // delegate-less pumps). The signer name stays data.
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isSigned ? AppColors.accentSuccess : AppColors.borderSubtle,
          width: _isSigned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      _isSigned ? Icons.check_circle : Icons.draw_outlined,
                      color: _isSigned
                          ? AppColors.accentSuccessStrong
                          : AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.signerLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _clear,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  minimumSize: const Size(0, 48),
                ),
                child: Text(
                  l10n?.handoverClear ?? 'Clear',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariantLight,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              // Audit SH-N3: was AppColors.background (deleted alias).
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.borderSubtle.withValues(alpha: 0.6),
                  style: BorderStyle.solid),
            ),
            // E3: the drawing area is a labelled semantics node so a
            // screen reader can find and describe it.
            child: Semantics(
              label: l10n?.signatureDrawArea ?? 'Signature drawing area',
              hint: l10n?.signatureDrawHint ??
                  'Draw your signature with your finger',
              child: GestureDetector(
                onPanUpdate: (details) {
                  final localPosition = details.localPosition;
                  setState(() {
                    _points.add(localPosition);
                    _isSigned = true;
                  });
                  widget.onSignedChange?.call(true);
                },
                onPanEnd: (details) => _points.add(null),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomPaint(
                    painter: _SignaturePainter(points: _points),
                    child: Center(
                      child: _points.isEmpty
                          ? Text(
                              l10n?.signatureSignHere(widget.signerName) ??
                                  'Sign here on screen (${widget.signerName})',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.onSurfaceVariantLight,
                                    fontStyle: FontStyle.italic,
                                  ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n?.signatureSignedBy(widget.signerName) ??
                      'Signed by: ${widget.signerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariantLight,
                      ),
                ),
              ),
              if (_isSigned) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n?.signatureNadraValidated ?? 'Signature captured',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.accentSuccessStrong,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryDark
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
