import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:freedom/feature/wallet/cubit/wallet_cubit.dart';
import 'package:freedom/feature/wallet/remote_source/add_card_model.dart';
import 'package:freedom/shared/formatters/date_formatter.dart';
import 'package:freedom/shared/widgets/text_field_factory.dart';

class AddCardBottomSheet extends StatefulWidget {
  const AddCardBottomSheet({super.key});

  @override
  _AddCardBottomSheetState createState() => _AddCardBottomSheetState();
}

class _AddCardBottomSheetState extends State<AddCardBottomSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<double> _animation;

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  String _cardNumber = '';
  String _cardHolderName = '';
  String _expiryDate = '';
  String _cvv = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuad,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String getCardType(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');

    // Check Visa
    if (cleanNumber.startsWith('4')) {
      return 'mastercard';
    }

    // Check Mastercard
    if (RegExp('^5[1-5]').hasMatch(cleanNumber) ||
        (RegExp('^2[2-7]').hasMatch(cleanNumber) &&
            cleanNumber.length >= 4 &&
            int.parse(cleanNumber.substring(0, 4)) >= 2221 &&
            int.parse(cleanNumber.substring(0, 4)) <= 2720)) {
      return 'visa';
    }

    // Check Verve
    if ((RegExp('^506(0(9[9])|1([0-8][0-9]|9[0-8]))').hasMatch(cleanNumber)) ||
        (RegExp('^507(8(6[5-9]|[7-9][0-9])|9([0-5][0-9]|6[0-4]))')
            .hasMatch(cleanNumber)) ||
        (RegExp('^6500(0[2-9]|[1-2][0-7])').hasMatch(cleanNumber))) {
      return 'verve';
    }

    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _animation.value) * 400),
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration:  BoxDecoration(
         gradient: whiteAmberGradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      height: 5,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add New Card',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Virtual Card Display
                  VirtualCardDisplay(
                    cardNumber: _cardNumber,
                    cardHolderName: _cardHolderName,
                    expiryDate: _expiryDate,
                    cardType: getCardType(_cardNumber),
                  ),
                  const SizedBox(height: 20),

                  // Card Number
                  Text(
                    'Card Number',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFieldFactory.itemField(
                      controller: _cardNumberController,
                    hinText: '0000 0000 0000 0000',
                    prefixText: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.asset(
                        getCardType(_cardNumber) == 'visa'
                            ? 'assets/images/visa_electron.svg'
                            : 'assets/images/mastercard.svg',
                        height: 24,
                        width: 24,
                      ),
                    ) ,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      CardNumberInputFormatter(),
                    ],
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter card number';
                      }
                      final cleanNumber = value.replaceAll(' ', '');
                      if (cleanNumber.length < 16) {
                        return 'Please enter a valid 16-digit card number';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _cardNumber = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Card Holder Name
                  Text(
                    'Card Holder Name',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextFieldFactory.itemField(
                    textCapitalization: TextCapitalization.words,
                    controller:_nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter cardholder name';
                      }
                      return null;
                    },
                    onChanged: (value){
                      setState(() {
                        _cardHolderName = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expiry Date',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFieldFactory.itemField(
                              controller: _expiryDateController,
                              hinText:'02/2006' ,
                              prefixText:  const Icon(Icons.calendar_today_outlined),
                              contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter expiry date';
                                }

                                if (!value.contains('/') || value.length < 7) {
                                  return 'Invalid format (MM/YYYY)';
                                }
                                final parts = value.split('/');
                                final month = int.tryParse(parts[0]);
                                final year = int.tryParse(parts[1]);

                                if (month == null ||
                                    year == null ||
                                    month < 1 ||
                                    month > 12) {
                                  return 'Invalid expiry date';
                                }
                                final now = DateTime.now();
                                if (year < now.year ||
                                    (year == now.year && month < now.month)) {
                                  return 'Card has expired';
                                }

                                return null;
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                                ExpiryDateInputFormatter(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _expiryDate = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // CVV
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CVV',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFieldFactory.itemField(
                                controller: _cvvController,
                              hinText: 'XXX',
                              prefixText: const Icon(Icons.lock_outline),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter CVV';
                                }

                                if (value.length < 3) {
                                  return 'CVV must be 3 digits';
                                }

                                return null;
                              },
                              onChanged: (value) {
                                setState(() {
                                  _cvv = value;
                                });
                              },
                              obscureText: true,

                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Add Card Button
                  FreedomButton(
                      onPressed: _isProcessing ? null : () => _addCard(context),
                    useGradient: true,
                    gradient: redLinearGradient,
                    title: 'Add Card',
                    buttonTitle: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'Add Card',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ) ,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addCard(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });
      try {
        final parts = _expiryDate.split('/');
        final expiryMonth = parts[0];
        final expiryYear = parts[1];

        final cleanCardNumber = _cardNumber.replaceAll(' ', '');

        final cardDetails = CardDetails(
          cardNumber: cleanCardNumber,
          cvv: _cvv,
          expiryMonth: expiryMonth,
          expiryYear: expiryYear.substring(2),
          currency: 'GHS',
        );

        final payStackModel = AddCardModel(
          type: 'card',
          cardType: getCardType(cardDetails.cardNumber),
          last4: cleanCardNumber.substring(cleanCardNumber.length - 4),
          expiryMonth: expiryMonth,
          expiryYear: expiryYear,
          isDefault: true,
          cardDetails: cardDetails,
        );

        await context.read<WalletCubit>().addNewCard(payStackModel);

        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adding Card'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add card: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final value = newValue.text.replaceAll(RegExp(r'\D'), '');

    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      buffer.write(value[i]);
      if ((i + 1) % 4 == 0 && i != value.length - 1) {
        buffer.write(' ');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class VirtualCardDisplay extends StatelessWidget {
  const VirtualCardDisplay({
    super.key,
    this.cardNumber = '',
    this.cardHolderName = '',
    this.expiryDate = '',
    this.cardType = 'visa',
  });
  final String cardNumber;
  final String cardHolderName;
  final String expiryDate;
  final String cardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardType.toLowerCase() == 'visa'
              ? [const Color(0xFF1A1F71), const Color(0xFF2B32B2)]
              : [const Color(0xFFFF5F00), const Color(0xFFEB001B)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            bottom: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            left: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // Card Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Type Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FREEDOM',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SvgPicture.asset(
                      cardType.toLowerCase() == 'visa'
                          ? 'assets/images/visa_electron.svg'
                          : 'assets/images/mastercard.svg',
                      height: 32,
                      width: 32,
                      colorFilter:
                          const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ],
                ),

                const Spacer(),

                // Card Number
                Text(
                  cardNumber.isEmpty ? '•••• •••• •••• ••••' : cardNumber,
                  style: GoogleFonts.sourceCodePro(
                    fontSize: 18,
                    letterSpacing: 2,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(),

                // Card Holder and Expiry
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARD HOLDER',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cardHolderName.isEmpty
                              ? 'YOUR NAME'
                              : cardHolderName.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'EXPIRES',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expiryDate.isEmpty ? 'MM/YY' : expiryDate,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Chip (positioned at the bottom)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade300,
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.amber.shade200,
                              Colors.amber.shade400,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Network icons - small circular icons at the bottom right
          Positioned(
            bottom: 15,
            right: 15,
            child: Row(
              children: [
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
