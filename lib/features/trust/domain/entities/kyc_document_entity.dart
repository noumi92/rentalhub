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
  final String status; // 'pending' | 'submitted' | 'verified' | 'rejected'

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

