import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/whatsapp.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../widgets/support_contact_card.dart';
import '../widgets/support_faq_list.dart';
import '../widgets/support_sos_tile.dart';
import '../widgets/support_ticket_form.dart';
import '../../../../l10n/app_localizations.dart';

class CustomerSupportView extends StatefulWidget {
  final VoidCallback? onFileDispute;
  final VoidCallback? onOpenSos;

  const CustomerSupportView(
      {super.key, this.onFileDispute, this.onOpenSos});

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
      // CU-m3: signed out — there is no booking to look the shop
      // up from, and the old 'cust-101' fallback read another
      // user's bookings. The contact cards simply stay empty.
      String? uid;
      try {
        uid = FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {}
      if (uid == null) return;
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
    final l10n = AppLocalizations.of(context)!;
    final phone = (_shopPhone ?? '').trim();
    if (phone.isEmpty) {
      AppFeedback.showInfo(
        context,
        l10n.supportNoBookingHint,
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      if (mounted) {
        AppFeedback.showError(context, l10n.couldNotCall);
      }
    }
  }

  Future<void> _whatsAppShop() async {
    final l10n = AppLocalizations.of(context)!;
    final uri = whatsappUri(
      phone: _shopPhone ?? '',
      message: l10n.supportWhatsappMessage(_shopName ?? 'there'),
    );
    if (uri == null) {
      AppFeedback.showInfo(
        context,
        l10n.supportNoBookingHint,
      );
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        AppFeedback.showError(context, l10n.couldNotOpenWhatsapp);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = _searchController.text.toLowerCase();
    final faqs = <Map<String, String>>[
      {'q': l10n.supportFaqQ1, 'a': l10n.supportFaqA1},
      {'q': l10n.supportFaqQ2, 'a': l10n.supportFaqA2},
      {'q': l10n.supportFaqQ3, 'a': l10n.supportFaqA3},
      {'q': l10n.supportFaqQ4, 'a': l10n.supportFaqA4},
    ];
    final filtered = faqs
        .where((f) =>
            f['q']!.toLowerCase().contains(query) ||
            f['a']!.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.supportTitle,
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
                        hintText: l10n.supportSearchHint,
                        // No hintStyle override: the theme's input hint
                        // style (onSurfaceVariant) drives both modes.
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
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
                            title: l10n.supportCallShop,
                            subtitle: _shopName ?? l10n.supportNoBooking,
                            color: Theme.of(context).colorScheme.primary,
                            onTap: _callShop,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SupportContactCard(
                            icon: Icons.chat_rounded,
                            title: l10n.supportWhatsappShop,
                            subtitle: _shopName ?? l10n.supportNoBooking,
                            color: AppColors.accentSuccess,
                            onTap: _whatsAppShop,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      tileColor: AppColors.secondaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color:
                                AppColors.secondary.withValues(alpha: 0.3)),
                      ),
                      leading: const Icon(Icons.gavel_rounded,
                          color: AppColors.secondary),
                      title: Text(l10n.supportFileDispute,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.secondary)),
                      subtitle: Text(
                          l10n.supportDisputeHint,
                          style: Theme.of(context).textTheme.labelSmall),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.secondary),
                      onTap: widget.onFileDispute,
                    ),
                    const SizedBox(height: 14),
                    // Phase C (C3): the Emergency SOS entry point. The
                    // orphaned customer dashboard was the screen's only
                    // entry point; with the dashboard deleted, Support
                    // is its home — the FAQ already tells users to use
                    // the SOS screen for emergencies.
                    SupportSosTile(onTap: widget.onOpenSos),
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
