import 'package:flutter/material.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:freedom/feature/wallet/cubit/wallet_cubit.dart';
import 'package:freedom/feature/wallet/remote_source/add_momo_card_model.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/widgets/text_field_factory.dart';
import 'package:google_fonts/google_fonts.dart';

class MomoBottomSheet extends StatefulWidget {
  const MomoBottomSheet({super.key});

  @override
  State<MomoBottomSheet> createState() => _MomoBottomSheetState();
}

class _MomoBottomSheetState extends State<MomoBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  String _selectedProvider = 'mtn';
  final _phoneController = TextEditingController();
  bool _isDefault = true;

  final List<String> _providers = ['mtn'];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm(BuildContext context) async{
    if (_formKey.currentState!.validate()) {
      final momoDetails = AddMomoCardModel(
        type: 'momo',
        momoProvider: _selectedProvider,
        momoNumber: _phoneController.text,
        isDefault: _isDefault,
      );
      await context.read<WalletCubit>().addMomoCard(momoDetails);
      if(context.mounted){
        Navigator.pop(context);
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: whiteAmberGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          border: Border.all(color: Colors.white),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Add mobile money',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            // Form
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Provider selection
                Text(
                  'Select Provider',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: glassyWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedProvider,
                      isExpanded: true,
                      dropdownColor: const Color(0xff8F5C06),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.black),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black,
                      ),
                      items: _providers.map((String provider) {
                        return DropdownMenuItem<String>(
                          value: provider,
                          child: Text(provider),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedProvider = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Phone number field
                Text(
                  'Phone Number',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Form(
                  key: _formKey,
                  child: TextFieldFactory.phone(
                    controller: _phoneController,
                    fillColor: glassyWhite,
                    hintText: 'e.g. +233201234567',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _isDefault,
                        onChanged: (bool? value) {
                          setState(() {
                            _isDefault = value ?? false;
                          });
                        },
                        fillColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return const Color(0xfff8c060);
                            }
                            return Colors.white.withOpacity(0.3);
                          },
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Set as default payment method',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                  FreedomButton(
                      onPressed: ()=>_submitForm(context),
                    gradient: redLinearGradient,
                    useGradient: true,
                    buttonTitle: Text(
                      'Add Mobile Money',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ) ,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Function to show the bottom sheet
Future<Map<String, dynamic>?> showMomoBottomSheet(BuildContext context) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const MomoBottomSheet(),
      );
    },
  );
}
