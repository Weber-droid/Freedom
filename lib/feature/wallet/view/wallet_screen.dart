import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/verify_otp_screen.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:freedom/feature/wallet/widgets/add_card_sheet.dart';
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
                const Spacer()
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
                  top: 30,
                  left: 25,
                  right: 25,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Account Balance',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Momo Pay',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 25,
                  right: 25,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        r'$0.00',
                        style: GoogleFonts.poppins(
                            fontSize: 27,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.only(
                            left: 10, right: 10, top: 3, bottom: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xfff8c060),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                                'assets/images/copy_button_icon.svg'),
                            Text(
                              '2627829012718',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Positioned(
                  top: 110,
                  left: 25,
                  right: 25,
                  child: DottedBorder(
                    radius: const Radius.circular(10),
                    borderType: BorderType.RRect,
                    color: Colors.white,
                    child: Container(
                      height: 80,
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xff8F5C06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 13,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                      'assets/images/arrow-left-down.svg'),
                                  const HSpace(2),
                                  Text(
                                    'Add Money',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white, fontSize: 16.9),
                                  )
                                ],
                              )),
                          const Spacer(),
                          TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 13,
                                ),
                              ),
                              onPressed: () {},
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                      'assets/images/transaction_icon.svg'),
                                  const HSpace(2),
                                  Text(
                                    'Transaction',
                                    style: GoogleFonts.poppins(
                                        color: Colors.black, fontSize: 16.9),
                                  )
                                ],
                              ))
                        ],
                      ),
                    ),
                  ),
                )
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
              message: (state as WalletCardAddError).message,
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
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              color: Theme.of(context).primaryColor.withOpacity(0.5),
              dashPattern: [6, 4],
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
            card: (id, userId, type, cardType, last4, expiryMonth, expiryYear,
                isDefault, createdAt, token) {
              return _buildCardItem(
                context,
                card: card,
                cardNumber: '•••• •••• •••• $last4',
                cardType: cardType,
                isDefault: isDefault,
                expiry: '$expiryMonth/$expiryYear',
              );
            },
            momo: (String id, String userId, String type, String momoProvider,
                String momoNumber, bool isDefault, DateTime createdAt) {
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
  final number =  card.when(
        card: (_, __, ___, ____, _____, _______, ________, ______,
            _________, ___________) =>
        cardNumber,
        momo: (id, userId, type, momoProvider, momoNumber, isDefault,
            createdAt) =>
        momoNumber);

  log('cardNumber based on card type: $number');
    final iconPath = cardType.toLowerCase() == 'visa'
        ? 'assets/images/visa_electron.svg'
        : 'assets/images/mastercard.svg';

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
            card: (_, __, ___, ____, _____, _______, ________, ______,
                    _________, ___________) =>
                cardNumber,
            momo: (id, userId, type, momoProvider, momoNumber, isDefault,
                    createdAt) =>
                momoNumber,
          ),
          style: GoogleFonts.poppins(
            fontSize: 16,
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
            const PopupMenuItem(
              value: 'set_default',
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline),
                  SizedBox(width: 8),
                  Text('Set as Default'),
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
