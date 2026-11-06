import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/whatsapp.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../widgets/customer_bottom_nav.dart';
import '../widgets/support_contact_card.dart';
import '../widgets/support_faq_list.dart';
import '../widgets/support_ticket_form.dart';

class CustomerSupportView extends StatefulWidget {
  final VoidCallback? onFileDispute;
  final VoidCallback? onBack;

  const CustomerSupportView({super.key, this.onFileDispute, this.onBack});

  @override
  State<CustomerSupportView> createState() => _CustomerSupportViewState();
}

class _CustomerSupportViewState extends State<CustomerSupportView> {
  final _searchController = TextEditingController();
  String? _shopName;
  String? _shopPhone;

  @override
  void initState() {
    super.initState();
    _loadShopContact();
  }

  // G1: the contact cards reach the customer's own showroom — the most
  // recent booking's shop — not an invented RentalHub helpline number.
  Future<void> _loadShopContact() async {
    try {
      String uid = 'cust-101';
      try {
        uid = FirebaseAuth.instance.currentUser?.uid ?? uid;
      } catch (_) {}
      final bookings =
          await sl<BookingRemoteDataSource>().getCustomerBookings(uid);
      if (bookings.isEmpty) return;
      final latest = bookings.first;
      String? phone = (latest.shopPhone ?? '').trim();
      String? name = latest.shopName;
      if (phone.isEmpty) {
        try {
          final snap = await FirebaseFirestore.instance
              .collection('shops')
              .doc(latest.shopId)
              .get();
          phone = (snap.data()?['phone_number'] as String? ?? '').trim();
          name = snap.data()?['shop_name'] as String? ?? name;
        } catch (_) {}
      }
      if (mounted && (phone ?? '').isNotEmpty) {
        setState(() {
          _shopName = name;
          _shopPhone = phone;
        });
      }
    } catch (_) {}
  }

  Future<void> _callShop() async {
    final phone = (_shopPhone ?? '').trim();
    if (phone.isEmpty) {
      AppFeedback.showInfo(
        context,
        'No booking yet — the showroom contact appears here once you have a booking.',
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      if (mounted) {
        AppFeedback.showError(context, 'Could not place the call.');
      }
    }
  }

  Future<void> _whatsAppShop() async {
    final uri = whatsappUri(
      phone: _shopPhone ?? '',
      message: 'Hi ${_shopName ?? 'there'}, I need help with my RentalHub booking.',
    );
    if (uri == null) {
      AppFeedback.showInfo(
        context,
        'No booking yet — the showroom contact appears here once you have a booking.',
      );
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        AppFeedback.showError(context, 'Could not open WhatsApp.');
      }
    }
  }
  final List<Map<String, String>> _faqs = [
    {
      'q': 'How does advance payment protect my booking?',
      'a': 'Your advance payment locks the vehicle exclusively for your scheduled time and guarantees showroom reservation. It is safely recorded and deducted from your final bill.',
    },
    {
      'q': 'When is my security deposit returned?',
      'a': 'The deposit is settled at return handover. Any deduction for excess kilometres, fuel or damage is shown on the settlement, and the rest is released to you.'
    },
    {
      'q': 'What happens if a vehicle breaks down?',
      'a': 'Roadside help depends on the showroom — ask yours when you pick up the car. For an emergency, use the Emergency SOS screen.',
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
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 3),
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
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                          child: SupportContactCard(
                            icon: Icons.phone_in_talk_rounded,
                            title: 'Call your showroom',
                            subtitle: _shopName ?? 'No booking yet',
                            color: AppColors.royalNavy,
                            onTap: _callShop,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SupportContactCard(
                            icon: Icons.chat_rounded,
                            title: 'WhatsApp your showroom',
                            subtitle: _shopName ?? 'No booking yet',
                            color: AppColors.emeraldGreen,
                            onTap: _whatsAppShop,
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
                    const SizedBox(height: 14),
                    const SupportTicketForm(),
                    const SizedBox(height: 20),
                    SupportFaqList(faqs: filtered),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
