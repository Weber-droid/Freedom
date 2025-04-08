part of 'wallet_cubit.dart';

abstract class WalletState {
  const WalletState();
}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {

  const WalletLoaded(this.paymentMethods, {this.isAddingCard = false});
  final List<PaymentMethod> paymentMethods;
  final bool isAddingCard;
}

class WalletError extends WalletState {

  const WalletError(this.message, {this.addCardModel = const []});
  final String message;
  final List<AddCardModel> addCardModel;
}

class WalletAddingCard extends WalletState {

  const WalletAddingCard(this.currentCards);
  final List<PaymentMethod> currentCards;
}

class WalletCardAddSuccess extends WalletState {

  const WalletCardAddSuccess(this.updatedCards, this.addedCard);
  final List<PaymentMethod> updatedCards;
  final AddCardResponse addedCard;
}

class WalletCardAddError extends WalletState {

  const WalletCardAddError(this.message, this.currentCards);
  final String message;
  final List<PaymentMethod> currentCards;
}

class DeleteCardInProgress extends WalletState {
  const DeleteCardInProgress(this.currentCards);
  final List<PaymentMethod> currentCards;
}

class DeleteCardSuccess extends WalletState {
  const DeleteCardSuccess(this.message, this.remainingCards, {this.success});
  final List<PaymentMethod> remainingCards;
  final String message;
  final bool? success;
}

class DeleteCardError extends WalletState {

  const DeleteCardError(this.message, this.currentCards);
  final String message;
  final List<PaymentMethod> currentCards;

}