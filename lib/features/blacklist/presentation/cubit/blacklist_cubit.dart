import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/blacklist_remote_data_source.dart';
import '../../domain/entities/blacklist_entity.dart';

abstract class BlacklistState extends Equatable {
  const BlacklistState();
  @override
  List<Object?> get props => [];
}

class BlacklistInitial extends BlacklistState {
  const BlacklistInitial();
}

class BlacklistFlagged extends BlacklistState {
  final BlacklistEntity record;
  const BlacklistFlagged(this.record);
  @override
  List<Object?> get props => [record];
}

class BlacklistReverted extends BlacklistState {
  final BlacklistEntity record;
  const BlacklistReverted(this.record);
  @override
  List<Object?> get props => [record];
}

class BlacklistCubit extends Cubit<BlacklistState> {
  final BlacklistRemoteDataSource dataSource;

  BlacklistCubit({required this.dataSource}) : super(const BlacklistInitial());

  Future<BlacklistEntity> reportFraud({
    required String reportedByShopId,
    required String cnicNumber,
    required String phoneNumber,
    required String reasonCategory,
    required String description,
  }) async {
    final record = await dataSource.reportCustomerToBlacklist(
      reportedByShopId: reportedByShopId,
      cnicNumber: cnicNumber,
      phoneNumber: phoneNumber,
      reasonCategory: reasonCategory,
      description: description,
    );
    emit(BlacklistFlagged(record));
    return record;
  }

  Future<BlacklistEntity> revertBySuperAdmin({
    required String blacklistId,
    required String adminUid,
    required String justification,
  }) async {
    final record = await dataSource.revertBlacklistRecord(
      blacklistId: blacklistId,
      adminUid: adminUid,
      justification: justification,
    );
    emit(BlacklistReverted(record));
    return record;
  }
}

