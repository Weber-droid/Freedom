part of 'profile_cubit.dart';

abstract class ProfileState{}

class ProfileInitial extends ProfileState{}
class ProfileLoading extends ProfileState{}
class ProfileLoaded extends ProfileState{
  ProfileLoaded(this.user);
  final ProfileModel user;
}
class ProfileError extends ProfileState{
  ProfileError(this.message);
  final String message;
}