import 'dart:developer' as dev;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());
  void addDestination() {
    emit(
      state.copyWith(
        locations: [...state.locations, generateNewDestinationString()],
      ),
    );
  }

  void removeLastDestination() {
    emit(state.copyWith(locations: List.from(state.locations)..removeLast()));
  }

  String generateNewDestinationString() {
    return 'Destination ${state.locations.length}';
  }

  set fieldIndex(int index) {
    dev.log('index: $index');
    emit(state.copyWith(fieldIndexSetter: index));
  }

  int get fieldIndex => state.fieldIndexSetter ?? 0;
}
