part of 'history_cubit.dart';

enum RideHistoryStatus { initial, loading, success, failure }

class HistoryState extends Equatable {
  const HistoryState({
    this.historyModel = const [],
    this.isLoading = false,
    this.rideTabEnum = RideTabEnum.logistics,
    this.historyStatus = RideHistoryStatus.initial,
    this.errorMessage = '',
  });
  final List<RideData> historyModel;
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
  }) {
    return HistoryState(
      isLoading: isLoading ?? false,
      rideTabEnum: rideTabEnum ?? this.rideTabEnum,
      historyStatus: historyStatus ?? this.historyStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      historyModel: historyModel ?? this.historyModel,
    );
  }

  @override
  List<Object?> get props => [
    historyModel,
    isLoading,
    rideTabEnum,
    historyStatus,
    errorMessage,
  ];
}
