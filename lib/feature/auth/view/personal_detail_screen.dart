import 'dart:developer';
import 'dart:ui';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/auth/cubit/registration_cubit.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/verify_otp_screen.dart';
import 'package:freedom/shared/enums/enums.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:freedom/shared/widgets/loading_overlay.dart';
import 'package:freedom/shared/widgets/text_field_factory.dart';
import 'package:freedom/shared/widgets/toasts.dart';
import 'package:google_fonts/google_fonts.dart';

class PersonalDetailScreen extends StatefulWidget {
  const PersonalDetailScreen({super.key});
  static const routeName = '/personal_details';

  @override
  State<PersonalDetailScreen> createState() => _PersonalDetailScreenState();
}

class _PersonalDetailScreenState extends State<PersonalDetailScreen> {
  final firstNameController = TextEditingController();
  final surNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameKey = GlobalKey<FormState>();
  final surnameKey = GlobalKey<FormState>();
  final emailKey = GlobalKey<FormState>();
  final phoneNumberKey = GlobalKey<FormState>();
  final passwordKey = GlobalKey<FormState>();
  bool termAccepted = false;
  String countryCode = '+233';

  @override
  void initState() {
    super.initState();
    phoneNumberController
      ..text = countryCode
      ..addListener(() {
        if (!phoneNumberController.text.startsWith(countryCode)) {
          phoneNumberController
            ..text = countryCode +
                phoneNumberController.text.replaceAll(RegExp(r'^\+\d+'), '')
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: phoneNumberController.text.length),
            );
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    log(RegisterLocalDataSource.getJwtToken());
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<RegisterCubit, RegisterState>(
        listener: (context, state) {
          if (state.formStatus == FormStatus.failure) {
            context.showToast(
                type: ToastType.error,
                position: ToastPosition.top,
                message: state.message);
          } else if (state.formStatus == FormStatus.success) {
            context.showToast(
                type: ToastType.success,
                message: state.message,
                position: ToastPosition.top);
            Navigator.pushNamed(context, VerifyOtpScreen.routeName);
          }
        },
        builder: (context, state) {
          Widget mainContent;

          mainContent = SafeArea(
            child: SingleChildScrollView(
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const DecoratedBackButton(),
                          ),
                          const HSpace(13.9),
                          Text(
                            'Personal Details',
                            style: GoogleFonts.poppins(
                                fontSize: 20.59,
                                fontWeight: FontWeight.w500,
                                color: Colors.black),
                          ),
                        ],
                      ),
                      const VSpace(20.45),
                      Text(
                        'Almost Done! Let’s Get to Know You',
                        style: GoogleFonts.poppins(
                          fontSize: 17.86,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Please provide a few details so we can\n complete your profile.',
                        textAlign: TextAlign.left,
                        style: GoogleFonts.poppins(
                          fontSize: 10.41,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      const VSpace(26.85),
                      Text(
                        'Name',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 15.06,
                          fontWeight: FontWeight.w500,
                          height: 0,
                        ),
                      ),
                      const VSpace(6.82),
                      Form(
                        key: firstNameKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: TextFieldFactory.name(
                          hinText: 'name',
                          hintTextStyle: GoogleFonts.poppins(
                            fontSize: 15.06,
                            fontWeight: FontWeight.w400,
                            color: const Color(0x42F59E0B),
                          ),
                          contentPadding: const EdgeInsets.only(
                            top: 21.06,
                            left: 8.06,
                            bottom: 21.06,
                          ),
                          controller: firstNameController,
                          prefixText: Padding(
                            padding: const EdgeInsets.only(
                                top: 21, left: 8.06, bottom: 21),
                            child: SvgPicture.asset(
                              'assets/images/user_icon.svg',
                              colorFilter: ColorFilter.mode(
                                  thickFillColor, BlendMode.srcIn),
                            ),
                          ),
                          validator: (val) {
                            if (val!.isEmpty) {
                              return 'Please enter your name';
                            }
                            if (val.contains(' ')) {
                              return 'Spaces are not allowed';
                            }
                            final regX = RegExp(r'^[a-zA-Z\s]+$');
                            if (!regX.hasMatch(val)) {
                              return 'Please enter a valid name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const VSpace(9),
                      Text(
                        'Surname',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 15.06,
                          fontWeight: FontWeight.w500,
                          height: 0,
                        ),
                      ),
                      const VSpace(6.82),
                      Form(
                        key: surnameKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: TextFieldFactory.name(
                          hinText: 'surname',
                          hintTextStyle: GoogleFonts.poppins(
                            fontSize: 15.06,
                            fontWeight: FontWeight.w400,
                            color: const Color(0x42F59E0B),
                          ),
                          contentPadding: const EdgeInsets.only(
                            top: 21.06,
                            left: 8.06,
                            bottom: 21.06,
                          ),
                          controller: surNameController,
                          prefixText: Padding(
                            padding: const EdgeInsets.only(
                                top: 21, left: 8.06, bottom: 21),
                            child: SvgPicture.asset(
                              'assets/images/user_icon.svg',
                              colorFilter: ColorFilter.mode(
                                  thickFillColor, BlendMode.srcIn),
                            ),
                          ),
                          validator: (val) {
                            if (val!.isEmpty) {
                              return 'Please enter your name';
                            }

                            if (val.contains(' ')) {
                              return 'Spaces are not allowed';
                            }
                            final regX = RegExp(r'^[a-zA-Z\s]+$');
                            if (!regX.hasMatch(val)) {
                              return 'Please enter a valid name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const VSpace(9),
                      Text(
                        'Email',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 15.06,
                          fontWeight: FontWeight.w500,
                          height: 0,
                        ),
                      ),
                      const VSpace(6.82),
                      Form(
                        key: emailKey,
                        child: TextFieldFactory.email(
                          controller: emailController,
                          hintTextStyle: GoogleFonts.poppins(
                            fontSize: 15.06,
                            fontWeight: FontWeight.w400,
                            color: const Color(0x42F59E0B),
                          ),
                          prefixText: Padding(
                            padding: const EdgeInsets.only(
                                top: 21, left: 8.06, bottom: 21),
                            child: SvgPicture.asset(
                                'assets/images/email_icon.svg'),
                          ),
                          hinText: 'Your email',
                          validator: (email) {
                            if (email!.isEmpty) {
                              return 'Please enter your email';
                            }
                            final regX = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                            if (!regX.hasMatch(email)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                      ),
                      const VSpace(9),
                      Text(
                        'Phone number',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 15.06,
                          fontWeight: FontWeight.w500,
                          height: 0,
                        ),
                      ),
                      const VSpace(6.82),
                      Form(
                        key: phoneNumberKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: TextFieldFactory.phone(
                          controller: phoneNumberController,
                          fontStyle: const TextStyle(
                            fontSize: 19.58,
                            color: Colors.black,
                          ),
                          prefixText: Transform.translate(
                            offset: const Offset(0, -5),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 10,
                                top: 18,
                                bottom: 7,
                                right: 17,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: const Color(0x4FF59E0B),
                                ),
                                child: Stack(
                                  children: [
                                    CountryCodePicker(
                                      textStyle: GoogleFonts.poppins(
                                          fontSize: 12, color: Colors.black),
                                      dialogTextStyle: GoogleFonts.poppins(
                                          fontSize: 12, color: Colors.black),
                                      countryFilter: const ['GH', 'NG'],
                                      dialogSize: const Size(300, 200),
                                      hideSearch: true,
                                      onChanged: (value) {
                                        setState(() {
                                          countryCode =
                                              value.dialCode ?? '+233';
                                          phoneNumberController.text =
                                              countryCode;
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      initialSelection: 'GH',
                                      hideMainText: true,
                                    ),
                                    Positioned(
                                      top: MediaQuery.of(context).size.height *
                                          0.014,
                                      left: MediaQuery.of(context).size.width *
                                          0.11,
                                      child: SvgPicture.asset(
                                          'assets/images/drop_down.svg'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            final cleanedNumber =
                                val.replaceAll(RegExp(r'\D'), '');

                            if (cleanedNumber.isEmpty) {
                              return 'Please enter digits only';
                            }

                            if (cleanedNumber.length < 10) {
                              return 'Phone number must be at least 10 digits long';
                            }

                            return null;
                          },
                        ),
                      ),
                      const VSpace(25.46),
                      Row(
                        children: [
                          Checkbox.adaptive(
                            activeColor: thickFillColor,
                            side: BorderSide(color: thickFillColor),
                            value: termAccepted,
                            onChanged: (val) {
                              setState(() {
                                termAccepted = val ?? false;
                              });
                            },
                          ),
                          Text(
                            'Read Terms and Condition',
                            style: GoogleFonts.poppins(
                              fontSize: 11.49,
                              color: thickFillColor,
                            ),
                          ),
                        ],
                      ),
                      const VSpace(16.03),
                      FreedomButton(
                        // ignore: use_if_null_to_convert_nulls_to_bools
                        onPressed: termAccepted == true
                            ? () {
                                if (firstNameKey.currentState!.validate() &&
                                    surnameKey.currentState!.validate() &&
                                    emailKey.currentState!.validate() &&
                                    phoneNumberKey.currentState!.validate()) {
                                  context.read<RegisterCubit>().setUserDetails(
                                      firstName: firstNameController.text,
                                      surName: surNameController.text,
                                      password: passwordController.text,
                                      email: emailController.text,
                                      phone: phoneNumberController.text);
                                  Future.delayed(
                                      const Duration(milliseconds: 500),
                                      () async {
                                    await context
                                        .read<RegisterCubit>()
                                        .registerUser();
                                  });
                                }
                              }
                            : null,
                        backGroundColor: Colors.black,
                        title: 'Complete Registration',
                        buttonTitle: Text('Complete Registration',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 17.92,
                              fontWeight: FontWeight.w500,
                            )),
                        fontSize: 17.92,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          if (state.formStatus == FormStatus.submitting) {
            return BlurredLoadingOverlay(
              isLoading: state.formStatus == FormStatus.submitting,
              child: mainContent,
            );
          }
          return mainContent;
        },
      ),
    );
  }
}
