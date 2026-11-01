import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import 'widgets/document_slot_tile.dart';

class CustomerDocumentsView extends StatefulWidget {
  final VoidCallback? onSubmitted;

  const CustomerDocumentsView({super.key, this.onSubmitted});

  @override
  State<CustomerDocumentsView> createState() => _CustomerDocumentsViewState();
}

class _CustomerDocumentsViewState extends State<CustomerDocumentsView> {
  bool _cnicFront = true;
  bool _cnicBack = true;
  bool _license = true;
  final _cnicController = TextEditingController(text: '35202-8819201-5');

  @override
  void dispose() {
    _cnicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const CustomCurvedHeader(
              height: 165,
              showProfileGreeting: true,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NADRA CNIC & Driving License KYC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'HMAC-SHA256 Encrypted cPanel Private Vault • شناختی کارڈ تصدیق',
                    style: TextStyle(
                      color: AppColors.textLavender,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            HeaderOverlapContainer(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '13-Digit NADRA CNIC Number',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.midnightNavy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _cnicController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DocumentSlotTile(
                          title: 'NADRA CNIC — Front Side',
                          subtitle: 'High-resolution scan with clear photo',
                          isUploaded: _cnicFront,
                          onTap: () => setState(() => _cnicFront = !_cnicFront),
                        ),
                        const SizedBox(height: 10),
                        DocumentSlotTile(
                          title: 'NADRA CNIC — Back Side',
                          subtitle: 'QR code & address clearly visible',
                          isUploaded: _cnicBack,
                          onTap: () => setState(() => _cnicBack = !_cnicBack),
                        ),
                        const SizedBox(height: 10),
                        DocumentSlotTile(
                          title: 'Valid Pakistan Driving License (LTV/HTV)',
                          subtitle: 'Required for Self-Drive rental packages',
                          isUploaded: _license,
                          onTap: () => setState(() => _license = !_license),
                        ),
                        const SizedBox(height: 18),
                        DebouncedButton(
                          text: 'Submit Encrypted KYC to cPanel Vault',
                          icon: Icons.cloud_upload_rounded,
                          onPressed: () async {
                            widget.onSubmitted?.call();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

