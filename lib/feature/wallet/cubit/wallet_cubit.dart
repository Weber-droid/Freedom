import 'package:bloc/bloc.dart';
import 'package:freedom/feature/wallet/remote_source/add_card_model.dart';
import 'package:freedom/feature/wallet/remote_source/add_card_response.dart';
import 'package:freedom/feature/wallet/remote_source/add_momo_card_model.dart';
import 'package:freedom/feature/wallet/remote_source/payment_methods.dart';
import 'package:freedom/feature/wallet/repository/repository.dart';

part 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  WalletCubit(this._repository) : super(WalletInitial());
  final Repository _repository;

  Future<void> loadWallet() async {
    emit(WalletLoading());
    try {
      final cards = await _repository.getPaymentMethods();
      if (cards.isEmpty) {
        emit(const WalletLoaded([]));
      } else {
        emit(WalletLoaded(cards));
      }
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  Future<void> addNewCard(AddCardModel newCard) async {
    var currentCards = <PaymentMethod>[];
    if (state is WalletLoaded) {
      currentCards = (state as WalletLoaded).paymentMethods;
    } else if (state is WalletCardAddSuccess) {
      currentCards = (state as WalletCardAddSuccess).updatedCards;
    } else if (state is WalletCardAddError) {
      currentCards = (state as WalletCardAddError).currentCards;
    }

    emit(WalletAddingCard(currentCards));

    try {
      if (newCard.isDefault) {
        currentCards = currentCards
            .map(
              (card) => card.copyWith(isDefault: false),
            )
            .toList();
      }

      final result = await _repository.addNewCard(newCard);
      result.fold((failure) {
        return emit(WalletCardAddError(failure.message, currentCards));
      }, (success) {
        final PaymentMethod newPaymentMethod;
        if (success.data.type == 'card') {
          newPaymentMethod = PaymentMethod.card(
            id: success.data.id,
            userId: success.data.userId,
            type: success.data.type,
            cardType: success.data.cardType ?? '',
            last4: success.data.last4 ?? '',
            expiryMonth: success.data.expiryMonth ?? '',
            expiryYear: success.data.expiryYear ?? '',
            isDefault: true,
            createdAt: success.data.createdAt,
            token: success.data.token,
          );
        } else {
          newPaymentMethod = PaymentMethod.momo(
            id: success.data.id,
            userId: success.data.userId,
            type: success.data.type,
            isDefault: success.data.isDefault ?? false,
            createdAt: success.data.createdAt,
            momoProvider: '',
            momoNumber: '',
          );
        }
        final updatedCards = [...currentCards, newPaymentMethod];
        return emit(WalletCardAddSuccess(updatedCards, success));
      });
    } catch (e) {
      emit(WalletCardAddError(e.toString(), currentCards));
    }
  }

  Future<void> addMomoCard(AddMomoCardModel addMomoCard) async {
    var currentCards = <PaymentMethod>[];
    if (state is WalletLoaded) {
      currentCards = (state as WalletLoaded).paymentMethods;
    } else if (state is WalletCardAddSuccess) {
      currentCards = (state as WalletCardAddSuccess).updatedCards;
    } else if (state is WalletCardAddError) {
      currentCards = (state as WalletCardAddError).currentCards;
    }

    emit(WalletAddingCard(currentCards));

    try {
      if (addMomoCard.isDefault) {
        currentCards = currentCards
            .map(
              (card) => card.copyWith(isDefault: false),
        )
            .toList();
      }
      final result = await _repository.addMomoCard(addMomoCard);
      result.fold((failure) {
        return emit(WalletCardAddError(failure.message, currentCards));
      }, (success) {
        final newPaymentMethod = PaymentMethod.momo(
          id: success.data.id,
          userId: success.data.userId,
          type: success.data.type,
          isDefault: true,
          createdAt: success.data.createdAt,
          momoProvider: success.data.momoProvider ?? '',
          momoNumber: success.data.momoNumber ?? '',
        );
        final updatedCards = [...currentCards, newPaymentMethod];
        return emit(WalletCardAddSuccess(updatedCards, success));
      });
    } catch (e) {
      emit(WalletCardAddError(e.toString(), currentCards));
    }
  }

  Future<void> deleteCard(String cardId) async {
    var currentCards = <PaymentMethod>[];
    if (state is WalletLoaded) {
      currentCards = (state as WalletLoaded).paymentMethods;
    } else if (state is WalletCardAddSuccess) {
      currentCards = (state as WalletCardAddSuccess).updatedCards;
    } else if (state is WalletCardAddError) {
      currentCards = (state as WalletCardAddError).currentCards;
    }

    emit(DeleteCardInProgress(currentCards));
    try {
      final result = await _repository.removeCard(cardId);

      result.fold((failure) {
        emit(DeleteCardError(failure.message, currentCards));
      }, (success) {
        final updatedCards =
            currentCards.where((card) => card.id != cardId).toList();
        emit(
          DeleteCardSuccess(
              success.message ?? 'Card deleted successfully', updatedCards),
        );
      });
    } catch (e) {
      emit(DeleteCardError(e.toString(), currentCards));
    }
  }
}
