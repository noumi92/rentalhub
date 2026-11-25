import 'package:equatable/equatable.dart';

class KycDocumentEntity extends Equatable {
  final String userUid;
  final String cnicNumber;
  final String cnicFrontKey;
  final String cnicBackKey;
  final String licenseKey;
  final String licenseBackKey;
  final String licenseNumber;
  final String licenseExpiry;
  // 'pending' | 'submitted' | 'verified' | 'rejected' |
  // 'resubmitted' — a verified record with a newer submission (or a
  // changed CNIC) waiting for re-review. The admin queue treats it
  // like 'submitted'; the trust score does too.
  final String status;

  const KycDocumentEntity({
    required this.userUid,
    required this.cnicNumber,
    required this.cnicFrontKey,
    required this.cnicBackKey,
    required this.licenseKey,
    this.licenseBackKey = '',
    this.licenseNumber = '',
    this.licenseExpiry = '',
    this.status = 'submitted',
  });

  @override
  List<Object?> get props => [
        userUid,
        cnicNumber,
        cnicFrontKey,
        cnicBackKey,
        licenseKey,
        licenseBackKey,
        licenseNumber,
        licenseExpiry,
        status,
      ];
}

