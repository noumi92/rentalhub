import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_curved_header.dart';

class CustomerSupportView extends StatefulWidget {
  final VoidCallback? onFileDispute;
  final VoidCallback? onBack;

  const CustomerSupportView({super.key, this.onFileDispute, this.onBack});

  @override
  State<CustomerSupportView> createState() => _CustomerSupportViewState();
}

class _CustomerSupportViewState extends State<CustomerSupportView> {
  final _searchController = TextEditingController();
  final List<Map<String, String>> _faqs = [
    {
      'q': 'How does advance payment protect my booking?',
      'a': 'Your advance payment locks the vehicle exclusively for your scheduled time and guarantees showroom reservation. It is safely recorded and deducted from your final bill.',
    },
    {
      'q': 'When is my security deposit returned?',
      'a': 'For self-drive rentals, the security deposit is inspected and released immediately upon digital return handover if there is no traffic fine or damage.',
    },
    {
      'q': 'What happens if a vehicle breaks down?',
      'a': 'All registered showrooms provide 24/7 roadside assistance or immediate vehicle replacement within city limits. You can also trigger the Emergency SOS.',
    },
    {
      'q': 'Can I take the rental car out of city?',
      'a': 'Yes, out-of-city packages are available. Select the "Out of City" tier or inform the showroom beforehand to ensure tracker clearance.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final filtered = _faqs
        .where((f) =>
            f['q']!.toLowerCase().contains(query) ||
            f['a']!.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: const Text(
                'Help & Support Center',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search questions, payments, safety...',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.royalNavy),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.phone_in_talk_rounded,
                            title: 'Call Helpline',
                            subtitle: '042-111-RENTAL',
                            color: AppColors.royalNavy,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Calling RentalHub helpline...')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.chat_rounded,
                            title: 'WhatsApp Desk',
                            subtitle: '24/7 Live Agent',
                            color: AppColors.emeraldGreen,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Connecting to WhatsApp support...')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      tileColor: AppColors.softOrangeTint,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color:
                                AppColors.sunsetOrange.withValues(alpha: 0.3)),
                      ),
                      leading: const Icon(Icons.gavel_rounded,
                          color: AppColors.sunsetOrange),
                      title: const Text('File a Formal Complaint / Dispute',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.sunsetOrange)),
                      subtitle: const Text(
                          'Overcharged or deposit withheld? File an arbitration claim.',
                          style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.sunsetOrange),
                      onTap: widget.onFileDispute,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.midnightNavy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...filtered.map((faq) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ExpansionTile(
                            shape: const Border(),
                            title: Text(
                              faq['q']!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.midnightNavy,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Text(
                                  faq['a']!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.45,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.midnightNavy)),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
