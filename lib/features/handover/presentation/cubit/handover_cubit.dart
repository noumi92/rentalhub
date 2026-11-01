import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/handover_local_data_source.dart';
import '../../data/datasources/pdf_contract_generator.dart';
import '../../domain/entities/handover_entity.dart';

abstract class HandoverState extends Equatable {
  const HandoverState();
  @override
  List<Object?> get props => [];
}

class HandoverInitial extends HandoverState {
  const HandoverInitial();
}

class HandoverSavedOffline extends HandoverState {
  final HandoverEntity handover;
  const HandoverSavedOffline(this.handover);
  @override
  List<Object?> get props => [handover];
}

class HandoverSynced extends HandoverState {
  final HandoverEntity handover;
  final int syncedCount;
  const HandoverSynced({required this.handover, required this.syncedCount});
  @override
  List<Object?> get props => [handover, syncedCount];
}

class HandoverCubit extends Cubit<HandoverState> {
  final HandoverLocalDataSource localDataSource;

  HandoverCubit({required this.localDataSource})
      : super(const HandoverInitial());

  Future<void> completeHandoverOfflineFirst({
    required String bookingId,
    required String shopName,
    required String customerName,
    required String cnicNumber,
    required String vehicleDetails,
    required int initialOdometer,
    required String fuelLevel,
    required List<String> damageNotes,
    required String customerSignatureSvg,
    required String ownerSignatureSvg,
    bool isOnline = false,
  }) async {
    final pdfBytes = await PdfContractGenerator.generateA4Agreement(
      agreementId: bookingId,
      shopName: shopName,
      customerName: customerName,
      cnicNumber: cnicNumber,
      vehicleDetails: vehicleDetails,
      initialOdometer: initialOdometer,
      fuelLevel: fuelLevel,
      customerSignatureSvg: customerSignatureSvg,
      ownerSignatureSvg: ownerSignatureSvg,
    );

    final entity = HandoverEntity(
      bookingId: bookingId,
      initialOdometer: initialOdometer,
      fuelLevel: fuelLevel,
      damageNotes: damageNotes,
      customerSignatureSvg: customerSignatureSvg,
      ownerSignatureSvg: ownerSignatureSvg,
      agreementPdfUrl:
          'https://media.rentalhub.pk/agreements/$bookingId-${pdfBytes.length}.pdf',
      isSynced: isOnline,
    );

    await localDataSource.saveHandoverOffline(entity);

    if (isOnline) {
      await syncPendingHandovers();
    } else {
      emit(HandoverSavedOffline(entity));
    }
  }

  Future<int> syncPendingHandovers() async {
    final pending = await localDataSource.getPendingSyncHandovers();
    for (final item in pending) {
      final url =
          item.agreementPdfUrl ?? 'https://media.rentalhub.pk/agreements/${item.bookingId}.pdf';
      await localDataSource.markSynced(item.bookingId, url);
      emit(
        HandoverSynced(
          handover: item.copyWith(agreementPdfUrl: url, isSynced: true),
          syncedCount: pending.length,
        ),
      );
    }
    return pending.length;
  }
}

