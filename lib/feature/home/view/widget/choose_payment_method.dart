import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:freedom/feature/wallet/cubit/wallet_cubit.dart';
import 'package:freedom/feature/wallet/remote_source/payment_methods.dart';
import 'package:freedom/feature/wallet/view/wallet_screen.dart';

class ChoosePayMentMethod extends StatefulWidget {
  const ChoosePayMentMethod({super.key});

  @override
  State<ChoosePayMentMethod> createState() => ChoosePayMentMethodState();
}

class ChoosePayMentMethodState extends State<ChoosePayMentMethod> {
  String defaultValue = 'cash';
  String selectedPaymentMethodId = 'cash';

  @override
  Widget build(BuildContext context) {
    final paymentMethods = context.select<WalletCubit, List<PaymentMethod>>((
      WalletCubit c,
    ) {
      final state = c.state;
      if (state is WalletLoaded) {
        return state.paymentMethods;
      }
      return [];
    });

    log('paymentMethods: ${paymentMethods.map((e) => e.toJson()).toList()}');

    // Find selected payment method for display
    PaymentMethod? selectedMethod;
    String displayText = 'Cash';

    if (selectedPaymentMethodId != 'cash') {
      selectedMethod = paymentMethods.firstWhereOrNull(
        (method) => method.when(
          card:
              (
                id,
                _,
                __,
                ___,
                ____,
                _____,
                ______,
                _______,
                ________,
                _________,
              ) => id == selectedPaymentMethodId,
          momo:
              (id, _, __, ___, ____, _____, ______) =>
                  id == selectedPaymentMethodId,
        ),
      );

      if (selectedMethod != null) {
        displayText = selectedMethod.when(
          card:
              (
                _,
                __,
                ___,
                cardType,
                last4,
                ____,
                _____,
                ______,
                _______,
                ________,
              ) => '${cardType.toUpperCase()} •••• $last4',
          momo:
              (_, __, ___, momoProvider, momoNumber, ____, _____) =>
                  'Mobile Money (${momoNumber.substring(6)})',
        );
      }
    }

    return GestureDetector(
      onTap: () => _showPaymentMethodBottomSheet(context, paymentMethods),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.08,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.only(left: 5),
        decoration: ShapeDecoration(
          color: const Color(0xA3FFFCF8),
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              strokeAlign: BorderSide.strokeAlignOutside,
              color: Colors.white,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 49.39,
              height: 47.62,
              padding: const EdgeInsets.only(
                top: 8.98,
                left: 9.88,
                bottom: 9.01,
                right: 9.88,
              ),
              decoration: ShapeDecoration(
                color: const Color(0x38F4950D),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1.76, color: Colors.white),
                  borderRadius: BorderRadius.circular(12.35),
                ),
              ),
              child: SvgPicture.asset('assets/images/pay_with_cash.svg'),
            ),
            const HSpace(8.98),
            Expanded(
              child: Text(
                displayText,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethodBottomSheet(
    BuildContext context,
    List<PaymentMethod> paymentMethods,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => PaymentMethodBottomSheet(
            paymentMethods: paymentMethods,
            selectedPaymentMethodId: selectedPaymentMethodId,
            onPaymentMethodSelected: (id, type) {
              setState(() {
                selectedPaymentMethodId = id;
                defaultValue = type;
              });
              context.read<RideCubit>().setPayMentMethod(type);
              Navigator.pop(context);
            },
          ),
    );
  }
}

class PaymentMethodBottomSheet extends StatelessWidget {
  final List<PaymentMethod> paymentMethods;
  final String selectedPaymentMethodId;
  final Function(String id, String type) onPaymentMethodSelected;

  const PaymentMethodBottomSheet({
    super.key,
    required this.paymentMethods,
    required this.selectedPaymentMethodId,
    required this.onPaymentMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Payment Method',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            _PaymentMethodTile(
              icon: Icons.money,
              title: 'Cash',
              subtitle: 'Pay with cash',
              isSelected: selectedPaymentMethodId == 'cash',
              onTap: () => onPaymentMethodSelected('cash', 'cash'),
            ),
            const Divider(height: 1),
            ...paymentMethods.map((method) {
              return method.when(
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
                  return _PaymentMethodTile(
                    icon: _getCardIcon(cardType),
                    title: '${cardType.toUpperCase()} •••• $last4',
                    subtitle: 'Expires $expiryMonth/$expiryYear',
                    isSelected: selectedPaymentMethodId == id,
                    isDefault: isDefault,
                    onTap: () => onPaymentMethodSelected(id, 'card'),
                  );
                },
                momo: (
                  id,
                  userId,
                  type,
                  momoProvider,
                  momoNumber,
                  isDefault,
                  createdAt,
                ) {
                  return _PaymentMethodTile(
                    icon: Icons.phone_android,
                    title: momoProvider.toUpperCase(),
                    subtitle: momoNumber,
                    isSelected: selectedPaymentMethodId == id,
                    isDefault: isDefault,
                    onTap: () => onPaymentMethodSelected(id, 'momo'),
                  );
                },
              );
            }),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(WalletScreen.routeName);
              },
              icon: const Icon(Icons.add_circle_outline),
              label: Text(
                'Add New Payment Method',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCardIcon(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isDefault;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    this.isDefault = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x38F4950D) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFF4950D) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFFF4950D) : Colors.grey[600],
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isDefault) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Default',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing:
          isSelected
              ? const Icon(Icons.check_circle, color: Color(0xFFF4950D))
              : null,
      onTap: onTap,
    );
  }
}
