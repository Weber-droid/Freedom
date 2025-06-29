import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/verify_otp_screen.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:freedom/feature/wallet/cubit/wallet_cubit.dart';
import 'package:freedom/feature/wallet/remote_source/payment_methods.dart';
import 'package:freedom/feature/wallet/widgets/card_type_sheet.dart';
import 'package:freedom/shared/sections_tiles.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  static const routeName = '/wallet';

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WalletCubit>().loadWallet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 27),
                  child: DecoratedBackButton(),
                ),
                const HSpace(84.91),
                Expanded(
                  child: Text(
                    'Wallet',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 13.09,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
            const VSpace(14.91),
            Stack(
              children: [
                const Image(
                  image: AssetImage('assets/images/decorated_more.png'),
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 0,
                  left: 25,
                  right: 25,
                  bottom: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BlocSelector<WalletCubit, WalletState, String>(
                        selector: (state) {
                          if (state is WalletLoaded) {
                            final defaultPaymentMethod = state.paymentMethods
                                .where((method) => method.isDefault == true)
                                .firstOrNull;

                            if (defaultPaymentMethod == null) {
                              return 'card';
                            }

                            return defaultPaymentMethod.maybeMap(
                              card: (cardMethod) => '****${cardMethod.type}',
                              momo: (momoMethod) => momoMethod.type,
                              orElse: () => 'card',
                            );
                          } else if (state is WalletLoading) {
                            return 'Loading...';
                          } else {
                            return 'card';
                          }
                        },
                        builder: (context, state) => Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: SvgPicture.asset(
                            state == 'visa'
                                ? 'assets/images/visa_electron.svg'
                                : state == 'momo'
                                    ? 'assets/images/momo_icon.svg'
                                    : 'assets/images/mastercard.svg',
                          ),
                        ),
                      ),
                      BlocSelector<WalletCubit, WalletState, String>(
                        selector: (state) {
                          if (state is WalletLoaded) {
                            final defaultPaymentMethod = state.paymentMethods
                                .where((method) => method.isDefault == true)
                                .firstOrNull;

                            if (defaultPaymentMethod == null) {
                              return 'card';
                            }

                            return defaultPaymentMethod.maybeMap(
                              card: (cardMethod) => '****${cardMethod.type}',
                              momo: (momoMethod) => momoMethod.type,
                              orElse: () => 'card',
                            );
                          } else if (state is WalletLoading) {
                            return 'Loading...';
                          } else {
                            return 'card';
                          }
                        },
                        builder: (context, state) => Text(
                          'Payment Method: $state',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 80,
                  left: 25,
                  right: 25,
                  bottom: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Card Number',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                          top: 3,
                          bottom: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xfff8c060),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            BlocSelector<WalletCubit, WalletState, String>(
                              selector: (state) {
                                if (state is WalletLoaded) {
                                  final defaultPaymentMethod = state.paymentMethods
                                      .where((method) => method.isDefault == true)
                                      .firstOrNull;

                                  if (defaultPaymentMethod == null) {
                                    return '**********';
                                  }

                                  return defaultPaymentMethod.maybeMap(
                                    card: (cardMethod) => '****${cardMethod.last4}',
                                    momo: (momoMethod) => momoMethod.momoNumber,
                                    orElse: () => 'Unknown payment method',
                                  );
                                } else if (state is WalletLoading) {
                                  return 'Loading...';
                                } else {
                                  return '**********';
                                }
                              },
                              builder: (context, paymentNumber) => Text(
                                ' $paymentNumber',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const VSpace(14.91),
            Container(
              height: 8,
              color: greyColor,
            ),
            const VSpace(14.91),
            const ManagePayment(),
          ],
        ),
      ),
    );
  }
}

class ManagePayment extends SectionFactory {
  const ManagePayment({
    super.key,
    super.backgroundColor,
    super.padding,
    super.titleStyle,
    super.onItemTap,
    super.paddingSection,
    super.sectionTextStyle,
    this.onMasterCardTap,
    this.onVisaCardTap,
  });
  final VoidCallback? onMasterCardTap;
  final VoidCallback? onVisaCardTap;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletCubit, WalletState>(
      listener: (context, state) {
        switch (state.runtimeType) {
          case WalletCardAddError:
            log('WalletCardAddError: ${(state as WalletCardAddError).message}');
            context.showToast(
              message: state.message,
              type: ToastType.error,
              position: ToastPosition.top,
            );
          case WalletError:
          context.showToast(
            message: (state as WalletError).message,
            type: ToastType.error,
            position: ToastPosition.top,
          );
          case DeleteCardError:
            context.showToast(
              message: (state as DeleteCardError).message,
              type: ToastType.error,
              position: ToastPosition.top,
            );
          case WalletCardAddSuccess:
            context.showToast(
              message: 'Card added successfully',
              type: ToastType.success,
              position: ToastPosition.top,
            );
          case DeleteCardSuccess:
            context.showToast(
              message: (state as DeleteCardSuccess).message,
              type: ToastType.success,
              position: ToastPosition.top,
            );
          default:
            break;
        }
      },
      builder: (context, state) {
        if (state is WalletLoading || state is DeleteCardInProgress) {
          return _buildLoadingState();
        } else if (state is WalletLoading || state is WalletAddingCard) {
          return _buildLoadingState();
        } else if (state is WalletLoaded) {
          return state.paymentMethods.isEmpty
              ? _buildEmptyState(context)
              : _buildCardsList(context, state.paymentMethods);
        } else if (state is WalletCardAddSuccess) {
          return state.updatedCards.isEmpty
              ? _buildEmptyState(context)
              : _buildCardsList(context, state.updatedCards);
        } else if (state is DeleteCardSuccess) {
          return state.remainingCards.isEmpty
              ? _buildEmptyState(context)
              : _buildCardsList(context, state.remainingCards);
        } else {
          return _buildEmptyState(context);
        }
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionTitle,
                style: sectionTextStyle ??
                    GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionTitle,
                style: sectionTextStyle ??
                    GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _showCardTypeBottomSheet(context),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              dashPattern: const [6, 4],
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Payment Method',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardsList(BuildContext context, List<PaymentMethod> cards) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionTitle,
                style: sectionTextStyle ??
                    GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _showCardTypeBottomSheet(context),
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
        ...cards.map((card) {
          return card.when(
            card: (
              id,
              userId,
              type,
              cardType,
              last4,
              expiryMonth,
              expiryYear,
              isDefault,
              createdAt,
              token,
            ) {
              return _buildCardItem(
                context,
                card: card,
                cardNumber: '•••• •••• •••• $last4',
                cardType: cardType,
                isDefault: isDefault,
                expiry: '$expiryMonth/$expiryYear',
              );
            },
            momo: (
              String id,
              String userId,
              String type,
              String momoProvider,
              String momoNumber,
              bool isDefault,
              DateTime createdAt,
            ) {
              return _buildCardItem(
                context,
                card: card,
                cardNumber: momoNumber,
                cardType: momoProvider,
                isDefault: isDefault,
                expiry: '',
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildCardItem(
    BuildContext context, {
    required PaymentMethod card,
    required String cardNumber,
    required String cardType,
    required bool isDefault,
    required String expiry,
  }) {

    String? iconPath;
    if(cardType.toLowerCase() == 'visa'){
      iconPath = 'assets/images/visa_electron.svg';
    } else if(cardType.toLowerCase() == 'mastercard'){
      iconPath = 'assets/images/mastercard.svg';
    } else{
     iconPath = 'assets/images/momo_icon.svg';
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        leading: SvgPicture.asset(
          iconPath,
          height: 32,
          width: 32,
        ),
        title: Text(
          card.when(
            card: (
              _,
              __,
              ___,
              ____,
              _____,
              _______,
              ________,
              ______,
              _________,
              ___________,
            ) =>
                cardNumber,
            momo: (
              id,
              userId,
              type,
              momoProvider,
              momoNumber,
              isDefault,
              createdAt,
            ) =>
                momoNumber,
          ),
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Expires: $expiry',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'set_default') {
              // context.read<WalletCubit>().setDefaultCard(card);
            } else if (value == 'delete') {
              context.read<WalletCubit>().deleteCard(card.id);
            }
          },
          itemBuilder: (context) => [
             PopupMenuItem(
              value: 'set_default',
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline),
                  const SizedBox(width: 8),
                  Text('Set as Default', style: GoogleFonts.poppins(color: Colors.black,),),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remove Card', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardTypeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CardTypeSheet(),
    );
  }

  @override
  String get sectionTitle => 'Manage Payment Method';

  @override
  List<SectionItem> get sectionItems => [];
}
