part of 'main_activity_cubit.dart';

final class MainActivityState extends Equatable {
  const MainActivityState({this.currentIndex = 0});
  final int currentIndex;

  MainActivityState copyWith({int? currentIndex}) {
    return MainActivityState(
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  List<Object?> get props => [currentIndex];
}
