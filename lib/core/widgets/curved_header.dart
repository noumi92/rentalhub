import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'custom_curved_header.dart';
import 'verified_badge.dart';

class CurvedHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottomContent;
  final double height;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showGreeting;
  final String userName;
  final String urduGreeting;

  const CurvedHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.bottomContent,
    this.height = 235,
    this.showBack = false,
    this.onBack,
    this.showGreeting = true,
    this.userName = 'Ahmed Raza',
    this.urduGreeting = 'اسلام علیکم',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: height),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3316194F),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: CustomPaint(
          painter: CurvedGradientHeaderPainter(isDark: isDark),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 44, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              if (showGreeting && !showBack) ...[
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.sunsetOrange.withValues(alpha: 0.2),
                        border: Border.all(
                          color: AppColors.sunsetOrange,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        userName.isNotEmpty ? userName[0] : 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Hi, $userName',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '($urduGreeting)',
                            style: const TextStyle(
                              color: AppColors.textLavender,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VerifiedBadge(isVerified: true),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (showBack)
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed:
                          onBack ?? () => Navigator.of(context).maybePop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else if (leading != null)
                    leading!
                  else
                    const SizedBox(width: 20),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (actions != null)
                    Row(mainAxisSize: MainAxisSize.min, children: actions!)
                  else
                    const SizedBox(width: 20),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textLavender.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
              if (bottomContent != null) ...[
                const SizedBox(height: 12),
                bottomContent!,
              ],
            ],
          ),
        ),
      ),
    ),
    ),
    );
  }
}
