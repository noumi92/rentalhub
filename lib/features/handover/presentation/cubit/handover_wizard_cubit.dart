import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signature/signature.dart';

import '../../../../core/widgets/vehicle_damage_schematic_widget.dart';
import '../../domain/entities/handover_entity.dart';

/// Item 9 (O26–O30): the shared draft for the 5-step handover
/// wizard. One cubit owns every step's data, so the shell can gate
/// "Continue" per step and the final step can hand the whole draft
/// to [HandoverCubit.completeHandoverOfflineFirst] in one call.
///
/// The two fresh-signature pads live here too (their controllers),
/// so the shell's finalize can export the PNG bytes even though
/// the pads render inside the agreement step.
///
/// Validation returns a short error code (`'face'`, `'payment'`,
/// `'deposit'`, `'checklist'`, `'signatures'`); the view maps it
/// to a localized message — the cubit never touches l10n.
class HandoverWizardState extends Equatable {
  final int step;
  final String bookingId;

  // O26 — manual face check (confirmed flag + timestamp only;
  // never a match percentage).
  final bool faceCheckConfirmed;
  final DateTime? faceCheckedAt;

  // O27 — money.
  final String? balanceMethod;
  final bool balanceReceived;
  final int cashReceivedAtHandover;
  final int? securityDepositOverride;
  final String? depositMethod;
  final bool depositReceived;
  final DateTime? depositReceivedAt;
  final String receiptId;

  // O28 — checklist.
  final int odometer;
  final String fuelLevel;
  final bool? acWorking;
  final bool? lightsWorking;
  final Set<String> documentsGiven;
  final Set<String> accessories;
  final bool keysHandedOver;
  final List<String> damageNotes;

  // O29 — photos + damage pins.
  final Map<String, String?> photos;
  final Map<String, String> photoTakenAt;
  final List<DamagePin> damagePins;

  // O30 — signatures: 'saved' (on file) or 'fresh' (pad).
  final String? customerSavedSignatureUrl;
  final Uint8List? customerSavedSignaturePng;
  final bool useCustomerSaved;
  final String? ownerSavedSignatureUrl;
  final Uint8List? ownerSavedSignaturePng;
  final bool useOwnerSaved;

  final bool isFinalizing;
  final HandoverEntity? completed;
  final Uint8List? completedPdfBytes;
  final String? error;
  final int errorTick;

  const HandoverWizardState({
    required this.step,
    required this.bookingId,
    this.faceCheckConfirmed = false,
    this.faceCheckedAt,
    this.balanceMethod,
    this.balanceReceived = false,
    this.cashReceivedAtHandover = 0,
    this.securityDepositOverride,
    this.depositMethod,
    this.depositReceived = false,
    this.depositReceivedAt,
    required this.receiptId,
    this.odometer = 0,
    this.fuelLevel = '',
    this.acWorking,
    this.lightsWorking,
    this.documentsGiven = const {},
    this.accessories = const {},
    this.keysHandedOver = false,
    this.damageNotes = const [],
    this.photos = const {
      'front': null,
      'back': null,
      'left': null,
      'right': null,
      'interior': null,
      'dashboard': null,
    },
    this.photoTakenAt = const {},
    this.damagePins = const [],
    this.customerSavedSignatureUrl,
    this.customerSavedSignaturePng,
    this.useCustomerSaved = true,
    this.ownerSavedSignatureUrl,
    this.ownerSavedSignaturePng,
    this.useOwnerSaved = true,
    this.isFinalizing = false,
    this.completed,
    this.completedPdfBytes,
    this.error,
    this.errorTick = 0,
  });

  static String receiptIdFor(String bookingId) => 'RH-RCT-$bookingId';

  HandoverWizardState copyWith({
    int? step,
    bool? faceCheckConfirmed,
    DateTime? faceCheckedAt,
    String? balanceMethod,
    bool? balanceReceived,
    int? cashReceivedAtHandover,
    int? securityDepositOverride,
    String? depositMethod,
    bool? depositReceived,
    DateTime? depositReceivedAt,
    int? odometer,
    String? fuelLevel,
    bool? acWorking,
    bool? lightsWorking,
    Set<String>? documentsGiven,
    Set<String>? accessories,
    bool? keysHandedOver,
    List<String>? damageNotes,
    Map<String, String?>? photos,
    Map<String, String>? photoTakenAt,
    List<DamagePin>? damagePins,
    String? customerSavedSignatureUrl,
    Uint8List? customerSavedSignaturePng,
    bool? useCustomerSaved,
    String? ownerSavedSignatureUrl,
    Uint8List? ownerSavedSignaturePng,
    bool? useOwnerSaved,
    bool? isFinalizing,
    HandoverEntity? completed,
    Uint8List? completedPdfBytes,
    String? error,
    int? errorTick,
    bool clearError = false,
    bool clearDepositReceivedAt = false,
  }) {
    return HandoverWizardState(
      step: step ?? this.step,
      bookingId: bookingId,
      faceCheckConfirmed: faceCheckConfirmed ?? this.faceCheckConfirmed,
      faceCheckedAt: faceCheckedAt ?? this.faceCheckedAt,
      balanceMethod: balanceMethod ?? this.balanceMethod,
      balanceReceived: balanceReceived ?? this.balanceReceived,
      cashReceivedAtHandover:
          cashReceivedAtHandover ?? this.cashReceivedAtHandover,
      securityDepositOverride:
          securityDepositOverride ?? this.securityDepositOverride,
      depositMethod: depositMethod ?? this.depositMethod,
      depositReceived: depositReceived ?? this.depositReceived,
      depositReceivedAt: clearDepositReceivedAt
          ? null
          : (depositReceivedAt ?? this.depositReceivedAt),
      receiptId: receiptId,
      odometer: odometer ?? this.odometer,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      acWorking: acWorking ?? this.acWorking,
      lightsWorking: lightsWorking ?? this.lightsWorking,
      documentsGiven: documentsGiven ?? this.documentsGiven,
      accessories: accessories ?? this.accessories,
      keysHandedOver: keysHandedOver ?? this.keysHandedOver,
      damageNotes: damageNotes ?? this.damageNotes,
      photos: photos ?? this.photos,
      photoTakenAt: photoTakenAt ?? this.photoTakenAt,
      damagePins: damagePins ?? this.damagePins,
      customerSavedSignatureUrl:
          customerSavedSignatureUrl ?? this.customerSavedSignatureUrl,
      customerSavedSignaturePng:
          customerSavedSignaturePng ?? this.customerSavedSignaturePng,
      useCustomerSaved: useCustomerSaved ?? this.useCustomerSaved,
      ownerSavedSignatureUrl:
          ownerSavedSignatureUrl ?? this.ownerSavedSignatureUrl,
      ownerSavedSignaturePng:
          ownerSavedSignaturePng ?? this.ownerSavedSignaturePng,
      useOwnerSaved: useOwnerSaved ?? this.useOwnerSaved,
      isFinalizing: isFinalizing ?? this.isFinalizing,
      completed: completed ?? this.completed,
      completedPdfBytes: completedPdfBytes ?? this.completedPdfBytes,
      error: clearError ? null : (error ?? this.error),
      errorTick: errorTick ?? this.errorTick,
    );
  }

  /// Effective security deposit: owner's edited value if set, else the
  /// vehicle's default deposit.
  int effectiveDeposit(int vehicleDeposit) =>
      (securityDepositOverride ?? vehicleDeposit).clamp(0, 1 << 30);

  /// The step gate: null when the step may be left, otherwise the
  /// error code the view turns into a message.
  String? stepError(
    int step, {
    int balanceDue = 0,
    int securityDeposit = 0,
  }) {
    final deposit = effectiveDeposit(securityDeposit);
    switch (step) {
      case 0:
        return faceCheckConfirmed ? null : 'face';
      case 1:
        if (cashReceivedAtHandover > 0 &&
            (balanceMethod == null || balanceMethod == 'not_yet')) {
          return 'payment';
        }
        if (balanceDue > 0 && balanceMethod == null) return 'payment';
        if (deposit > 0 && depositMethod == null) return 'deposit';
        if (deposit > 0 && !depositReceived) return 'deposit_confirm';
        return null;
      case 2:
        return odometer > 0 && fuelLevel.isNotEmpty ? null : 'checklist';
      case 3:
        return null;
      default:
        return null;
    }
  }

  @override
  List<Object?> get props => [
        step,
        bookingId,
        faceCheckConfirmed,
        faceCheckedAt,
        balanceMethod,
        balanceReceived,
        cashReceivedAtHandover,
        securityDepositOverride,
        depositMethod,
        depositReceived,
        depositReceivedAt,
        receiptId,
        odometer,
        fuelLevel,
        acWorking,
        lightsWorking,
        documentsGiven,
        accessories,
        keysHandedOver,
        damageNotes,
        photos,
        photoTakenAt,
        damagePins,
        customerSavedSignatureUrl,
        customerSavedSignaturePng,
        useCustomerSaved,
        ownerSavedSignatureUrl,
        ownerSavedSignaturePng,
        useOwnerSaved,
        isFinalizing,
        completed,
        completedPdfBytes,
        error,
        errorTick,
      ];
}

class HandoverWizardCubit extends Cubit<HandoverWizardState> {
  HandoverWizardCubit({
    required String bookingId,
    int initialStep = 0,
    bool faceCheckConfirmed = false,
  }) : super(HandoverWizardState(
          step: initialStep.clamp(0, 4),
          bookingId: bookingId,
          faceCheckConfirmed: faceCheckConfirmed,
          faceCheckedAt: faceCheckConfirmed ? DateTime.now() : null,
          receiptId: HandoverWizardState.receiptIdFor(bookingId),
        ));

  /// The fresh-signature pads. Owned here so finalize can export
  /// them; the agreement step only renders them.
  final customerSigController = SignatureController(
    penStrokeWidth: 3,
    penColor: const Color(0xFF000000),
    exportBackgroundColor: const Color(0xFFFFFFFF),
  );
  final ownerSigController = SignatureController(
    penStrokeWidth: 3,
    penColor: const Color(0xFF000000),
    exportBackgroundColor: const Color(0xFFFFFFFF),
  );

  @override
  Future<void> close() {
    customerSigController.dispose();
    ownerSigController.dispose();
    return super.close();
  }

  void goToStep(int step) =>
      emit(state.copyWith(step: step.clamp(0, 4), clearError: true));

  void nextStep({int balanceDue = 0, int securityDeposit = 0}) {
    final error = state.stepError(state.step,
        balanceDue: balanceDue, securityDeposit: securityDeposit);
    if (error != null) {
      emit(state.copyWith(error: error, errorTick: state.errorTick + 1));
      return;
    }
    goToStep(state.step + 1);
  }

  void setSecurityDeposit(int amount) => emit(state.copyWith(
        securityDepositOverride: amount.clamp(0, 1 << 30),
        clearError: true,
      ));

  void previousStep() => goToStep(state.step - 1);

  void setFaceChecked(bool confirmed) => emit(state.copyWith(
        faceCheckConfirmed: confirmed,
        faceCheckedAt: confirmed ? DateTime.now() : state.faceCheckedAt,
        clearError: true,
      ));

  void setBalanceMethod(String method) => emit(state.copyWith(
        balanceMethod: method,
        clearError: true,
      ));

  void setBalanceReceived(bool received) =>
      emit(state.copyWith(balanceReceived: received));

  void setCashReceivedAtHandover(int amount) {
    final clamped = amount.clamp(0, 1 << 30);
    emit(state.copyWith(
      cashReceivedAtHandover: clamped,
      balanceReceived: clamped > 0,
      clearError: true,
    ));
  }

  void setDepositMethod(String method) => emit(state.copyWith(
        depositMethod: method,
        clearError: true,
      ));

  void setDepositReceived(bool received) => emit(state.copyWith(
        depositReceived: received,
        depositReceivedAt: received ? DateTime.now() : null,
        clearDepositReceivedAt: !received,
      ));

  void setOdometer(int value) =>
      emit(state.copyWith(odometer: value, clearError: true));

  void setFuel(String level) =>
      emit(state.copyWith(fuelLevel: level, clearError: true));

  void setAcWorking(bool value) => emit(state.copyWith(acWorking: value));

  void setLightsWorking(bool value) =>
      emit(state.copyWith(lightsWorking: value));

  void setDocuments(Set<String> value) =>
      emit(state.copyWith(documentsGiven: value));

  void setAccessories(Set<String> value) =>
      emit(state.copyWith(accessories: value));

  void setKeysHandedOver(bool value) =>
      emit(state.copyWith(keysHandedOver: value));

  void setDamageNotes(List<String> value) =>
      emit(state.copyWith(damageNotes: value));

  void setPhotos(Map<String, String?> value) =>
      emit(state.copyWith(photos: value));

  void setPhotoTakenAt(Map<String, String> value) =>
      emit(state.copyWith(photoTakenAt: value));

  void setDamagePins(List<DamagePin> value) =>
      emit(state.copyWith(damagePins: value));

  void setCustomerSavedSignature({String? url, Uint8List? pngBytes}) =>
      emit(state.copyWith(
        customerSavedSignatureUrl: url,
        customerSavedSignaturePng: pngBytes,
      ));

  void setOwnerSavedSignature({String? url, Uint8List? pngBytes}) =>
      emit(state.copyWith(
        ownerSavedSignatureUrl: url,
        ownerSavedSignaturePng: pngBytes,
      ));

  void setUseCustomerSaved(bool value) =>
      emit(state.copyWith(useCustomerSaved: value, clearError: true));

  void setUseOwnerSaved(bool value) =>
      emit(state.copyWith(useOwnerSaved: value, clearError: true));

  /// The pad drew something — called by the agreement step so the
  /// step-4 gate ([signaturesReady]) re-evaluates. The controllers
  /// themselves are the source of truth (see [signaturesReady]);
  /// this only forces a rebuild.
  void markCustomerSigDrawn() => emit(state.copyWith(clearError: true));

  void markOwnerSigDrawn() => emit(state.copyWith(clearError: true));

  void setFinalizing(bool value) =>
      emit(state.copyWith(isFinalizing: value));

  void markCompleted(HandoverEntity entity, Uint8List? pdfBytes) =>
      emit(state.copyWith(
        completed: entity,
        completedPdfBytes: pdfBytes,
        isFinalizing: false,
        clearError: true,
      ));

  void setError(String error) => emit(state.copyWith(error: error));

  /// The signatures to embed in the agreement PDF: the saved PNG
  /// bytes when the on-file signature is chosen, otherwise the
  /// fresh pad export. Returns nulls when a side has no signature
  /// (finalize is blocked upstream by [signaturesReady]).
  Future<({Uint8List? customer, Uint8List? owner})>
      exportSignatures() async {
    Uint8List? customer;
    Uint8List? owner;
    if (state.useCustomerSaved && state.customerSavedSignaturePng != null) {
      customer = state.customerSavedSignaturePng;
    } else if (customerSigController.isNotEmpty) {
      customer = await customerSigController.toPngBytes();
    }
    if (state.useOwnerSaved && state.ownerSavedSignaturePng != null) {
      owner = state.ownerSavedSignaturePng;
    } else if (ownerSigController.isNotEmpty) {
      owner = await ownerSigController.toPngBytes();
    }
    return (customer: customer, owner: owner);
  }

  /// Finalize gate for step 4: a customer signature and an owner
  /// signature, saved or fresh. Guarantor is NOT signed here — it
  /// moves to the O47 wizard step; O30 shows it as pending.
  ///
  /// A side is satisfied by its saved PNG when one is on file and
  /// chosen, OR by ink on its fresh pad. The pad branch must not
  /// depend on `useSaved` being false: the flags default to true
  /// and nothing flips them when no saved signature exists (the
  /// loader only sets them when one is found, and the signature
  /// block only offers "Sign fresh instead" when a saved signature
  /// is shown) — so gating the pad on `!useSaved` left the wizard
  /// stuck at step 4 whenever the customer/owner had no signature
  /// on file, no matter how much they signed on the pads.
  bool get signaturesReady {
    final customerOk = (state.useCustomerSaved &&
            state.customerSavedSignaturePng != null) ||
        customerSigController.isNotEmpty;
    final ownerOk = (state.useOwnerSaved &&
            state.ownerSavedSignaturePng != null) ||
        ownerSigController.isNotEmpty;
    return customerOk && ownerOk;
  }

  /// The source actually used: 'saved' only when a saved PNG is on
  /// file and chosen — a fresh pad signature is 'fresh' even though
  /// `useSaved` still holds its `true` default when no saved
  /// signature exists.
  String get customerSignatureSource =>
      (state.useCustomerSaved &&
              state.customerSavedSignaturePng != null)
          ? 'saved'
          : 'fresh';
  String get ownerSignatureSource =>
      (state.useOwnerSaved && state.ownerSavedSignaturePng != null)
          ? 'saved'
          : 'fresh';
}
