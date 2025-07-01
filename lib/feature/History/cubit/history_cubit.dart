import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freedom/feature/History/enums.dart';
import 'package:freedom/feature/History/model/history_model.dart';
import 'package:freedom/feature/home/repository/ride_request_repository.dart';

part 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({required this.rideRequestRepository})
    : super(const HistoryState());
  final RideRequestRepository rideRequestRepository;
  void setActiveTab(RideTabEnum tab) {
    emit(state.copyWith(rideTabEnum: tab));
  }

  Future<void> getRides(String status, int page, int limit) async {
    emit(state.copyWith(historyStatus: RideHistoryStatus.loading));
    final response = await rideRequestRepository.getRideHistory(
      status,
      page,
      limit,
    );
    response.fold(
      (failure) {
        emit(
          state.copyWith(
            historyStatus: RideHistoryStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (success) {
        
        emit(
          state.copyWith(
            historyStatus: RideHistoryStatus.success,
            historyModel: success.data,
          ),
        );
      },
    );
  }
}
