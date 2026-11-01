import 'package:equatable/equatable.dart';

class HandoverEntity extends Equatable {
  final String bookingId;
  final int initialOdometer;
  final String fuelLevel; // e.g., '6/8 (75%)'
  final List<String> damageNotes;
  final String customerSignatureSvg;
  final String ownerSignatureSvg;
  final String? agreementPdfUrl;
  final bool isSynced;

  const HandoverEntity({
    required this.bookingId,
    required this.initialOdometer,
    required this.fuelLevel,
    this.damageNotes = const [],
    required this.customerSignatureSvg,
    required this.ownerSignatureSvg,
    this.agreementPdfUrl,
    this.isSynced = false,
  });

  HandoverEntity copyWith({
    String? agreementPdfUrl,
    bool? isSynced,
  }) {
    return HandoverEntity(
      bookingId: bookingId,
      initialOdometer: initialOdometer,
      fuelLevel: fuelLevel,
      damageNotes: damageNotes,
      customerSignatureSvg: customerSignatureSvg,
      ownerSignatureSvg: ownerSignatureSvg,
      agreementPdfUrl: agreementPdfUrl ?? this.agreementPdfUrl,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        initialOdometer,
        fuelLevel,
        damageNotes,
        customerSignatureSvg,
        ownerSignatureSvg,
        agreementPdfUrl,
        isSynced,
      ];
}

