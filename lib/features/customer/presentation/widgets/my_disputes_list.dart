import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/datasources/dispute_remote_data_source.dart';

/// G4: the customer's own disputes with their statuses, newest first.
/// Extracted from [CustomerDisputeView] so the view stays under the
/// 250-line cap.
class MyDisputesList extends StatefulWidget {
  const MyDisputesList({super.key});

  @override
  State<MyDisputesList> createState() => _MyDisputesListState();
}

class _MyDisputesListState extends State<MyDisputesList> {
  List<DisputeRecord>? _disputes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<DisputeRecord> list = [];
    try {
      String uid = 'cust-101';
      try {
        uid = FirebaseAuth.instance.currentUser?.uid ?? uid;
      } catch (_) {}
      list = await sl<DisputeRemoteDataSource>().getCustomerDisputes(uid);
    } catch (_) {}
    if (mounted) setState(() => _disputes = list);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return AppColors.emeraldGreen;
      case 'in_review':
        return AppColors.amberGold;
      default:
        return AppColors.sunsetOrange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'resolved':
        return 'Resolved';
      case 'in_review':
        return 'In review';
      default:
        return 'Open';
    }
  }

  @override
  Widget build(BuildContext context) {
    final disputes = _disputes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Disputes',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.midnightNavy,
          ),
        ),
        const SizedBox(height: 10),
        if (disputes == null)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ))
        else if (disputes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'No disputes filed yet.',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          )
        else
          ...disputes.map((d) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            d.category,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.midnightNavy,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(d.status)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _statusLabel(d.status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _statusColor(d.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Booking ${d.bookingId}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.description,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.midnightNavy,
                          height: 1.4),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
