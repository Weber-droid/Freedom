part of 'history_cubit.dart';

enum RideHistoryStatus { initial, loading, success, failure }

class HistoryState extends Equatable {
  const HistoryState({
    this.historyDetails = const [],
    this.isLoading = false,
    this.rideTabEnum = RideTabEnum.logistics,
    this.historyStatus = RideHistoryStatus.initial,
    this.errorMessage = '',
  });
  final List<RideData> historyDetails;
  final bool isLoading;
  final RideTabEnum rideTabEnum;
  final RideHistoryStatus historyStatus;
  final String errorMessage;

  HistoryState copyWith({
    List<RideData>? historyModel,
    bool? isLoading,
    RideTabEnum? rideTabEnum,
    RideHistoryStatus? historyStatus,
    String? errorMessage,
    List<RideData>? historyDetails,
  }) {
    return HistoryState(
        isLoading: isLoading ?? false,
        rideTabEnum: rideTabEnum ?? this.rideTabEnum,
        historyStatus: historyStatus ?? this.historyStatus,
        errorMessage: errorMessage ?? this.errorMessage,
        historyDetails: historyDetails ?? this.historyDetails);
  }

  @override
  List<Object?> get props =>
      [historyDetails, isLoading, rideTabEnum, historyStatus, errorMessage];
}
