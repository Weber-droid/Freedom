part of 'home_cubit.dart';

class HomeState extends Equatable {
  const HomeState({
    this.locations = const [],
    this.fieldIndexSetter,
  });

  final List<String> locations;
  final int? fieldIndexSetter;

  HomeState copyWith({List<String>? locations, int? fieldIndexSetter}) {
    return HomeState(
      locations: locations ?? this.locations,
      fieldIndexSetter: fieldIndexSetter ?? this.fieldIndexSetter,
    );
  }

  @override
  List<Object?> get props => [locations, fieldIndexSetter];
}
