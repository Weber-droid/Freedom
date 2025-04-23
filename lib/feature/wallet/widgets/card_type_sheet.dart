import 'package:flutter/material.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:freedom/feature/wallet/widgets/add_card_sheet.dart';
import 'package:freedom/feature/wallet/widgets/momo_sheet.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';

enum CardType { card, momo }

class CardTypeSheet extends StatelessWidget {
  const CardTypeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
       gradient: whiteAmberGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          _buildPaymentOption(
            context,
            title: 'Credit or Debit Card',
            subtitle: 'Pay with Visa, Mastercard, etc.',
            icon: Icons.credit_card,
            iconBackground: Colors.blue[50]!,
            iconColor: Colors.blue[700]!,
            onTap: () => _showAddCardBottomSheet(context)
          ),

          const SizedBox(height: 16),

          _buildPaymentOption(
            context,
            title: 'Mobile Money',
            subtitle: 'Pay with momo',
            icon: Icons.phone_android,
            iconBackground: Colors.orange[50]!,
            iconColor: Colors.orange[700]!,
            onTap: () => showMomoBottomSheet(context)
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color iconBackground,
        required Color iconColor,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: glassyWhite.withValues(alpha: 0.6),
          border: GradientBoxBorder(gradient: redLinearGradient),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12.13,
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}

void _showAddCardBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AddCardBottomSheet(),
  );
}