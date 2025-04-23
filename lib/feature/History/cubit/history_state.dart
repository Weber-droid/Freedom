part of 'history_cubit.dart';

class HistoryState {
  const HistoryState({
    this.historyDetails = const [],
    this.isLoading = false,
    this.rideTabEnum = RideTabEnum.logistics,
  });
  final List<HistoryModel> historyDetails;
  final bool isLoading;
  final RideTabEnum rideTabEnum;

  HistoryState copyWith({
    List<HistoryModel>? historyModel,
    bool? isLoading,
    RideTabEnum? rideTabEnum,
  }) {
    return HistoryState(
      historyDetails: historyModel ?? [],
      isLoading: isLoading ?? false,
      rideTabEnum: rideTabEnum ?? this.rideTabEnum,
    );
  }
}
