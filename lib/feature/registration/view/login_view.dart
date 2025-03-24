import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/registration/cubit/forms_cubit.dart';
import 'package:freedom/feature/registration/view/personal_detail_screen.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/verify_otp_screen.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:freedom/shared/widgets/text_field_factory.dart';
import 'package:freedom/shared/widgets/toasts.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  static const routeName = '/login';

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final fromKey = GlobalKey<FormState>();
  TextEditingController phoneController = TextEditingController();

  String countryCode = '+233';
  @override
  void initState() {
    super.initState();
    phoneController
      ..text = countryCode
      ..addListener(() {
        if (!phoneController.text.startsWith(countryCode)) {
          phoneController
            ..text = countryCode +
                phoneController.text.replaceAll(RegExp(r'^\+\d+'), '')
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: phoneController.text.length),
            );
        }
      });
  }

  String getFullPhoneNumber() {
    return phoneController.text;
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<RegisterFormCubit, RegisterFormState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VSpace(67),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: SvgPicture.asset(
                    'assets/images/login_logo.svg',
                  ),
                ),
                const VSpace(20.37),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: Text(
                    'Enter your phone number',
                    style: GoogleFonts.poppins(
                        fontSize: 15.6, fontWeight: FontWeight.w500),
                  ),
                ),
                const VSpace(7),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: Form(
                    key: fromKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: TextFieldFactory.phone(
                      controller: phoneController,
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
                                  onChanged: (value) {
                                    setState(() {
                                      countryCode = value.dialCode ?? '+233';
                                      phoneController.text = countryCode;
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  initialSelection: 'GH',
                                  hideMainText: true,
                                ),
                                Positioned(
                                  top: MediaQuery.of(context).size.height *
                                      0.014,
                                  left:
                                      MediaQuery.of(context).size.width * 0.11,
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
                        final cleanedNumber = val.replaceAll(RegExp(r'\D'), '');

                        if (cleanedNumber.isEmpty) {
                          return 'Please enter digits only';
                        }

                        if (cleanedNumber.length < 10) {
                          return 'Phone number must be at least 10 digits long';
                        }

                        return null; // Valid input
                      },
                    ),
                  ),
                ),
                const VSpace(29),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: FreedomButton(
                    backGroundColor: Colors.black,
                    borderRadius: BorderRadius.circular(7),
                    width: double.infinity,
                    title: 'Continue',
                    buttonTitle: Text('Continue',
                        style: GoogleFonts.poppins(
                          fontSize: 17.4,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        )),
                    onPressed: () {
                      if (fromKey.currentState!.validate()) {
                        final phoneNumber = getFullPhoneNumber();
                        context
                            .read<RegisterFormCubit>()
                            .setPhoneNumber(phoneNumber);
                        Navigator.pushNamed(context, '/verify_otp');
                      }
                    },
                  ),
                ),
                const VSpace(26),
                Row(
                  children: [
                    Container(
                      height: 7,
                      width: 167,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: colorGrey,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Or',
                      style: GoogleFonts.poppins(
                          fontSize: 15.36, color: Colors.black),
                    ),
                    const Spacer(),
                    Container(
                      height: 7,
                      width: 167,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: colorGrey),
                    ),
                  ],
                ),
                const VSpace(28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: FreedomButton(
                    backGroundColor: socialLoginColor,
                    leadingIcon: 'apple_icon',
                    borderRadius: BorderRadius.circular(7),
                    title: 'Login with Apple',
                    buttonTitle: Text('Login with Apple',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black)),
                    titleColor: Colors.black,
                    width: double.infinity,
                    fontSize: 16,
                    onPressed: () {},
                  ),
                ),
                const VSpace(20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: BlocConsumer<RegisterFormCubit, RegisterFormState>(
                      listener: (context, state) {
                    if (state.formStatus == FormStatus.success) {
                      Navigator.pushNamed(context, VerifyOtpScreen.routeName);
                    }
                    if (state.formStatus == FormStatus.failure) {
                      context.showToast(
                          message: state.message, type: ToastType.error);
                    }
                  }, builder: (context, state) {
                    if (state.formStatus == FormStatus.submitting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return FreedomButton(
                      backGroundColor: socialLoginColor,
                      leadingIcon: 'google_icon',
                      borderRadius: BorderRadius.circular(7),
                      buttonTitle: Text('Login with Google',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black)),
                      titleColor: Colors.black,
                      fontSize: 16,
                      width: double.infinity,
                      onPressed: () {
                        context
                            .read<RegisterFormCubit>()
                            .registerOrLoginWithGoogle();
                      },
                    );
                  }),
                ),
                const VSpace(17),
                Center(
                  child: Text(
                    'Or',
                    style: GoogleFonts.poppins(
                        fontSize: 15.36,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                ),
                const VSpace(7),
                Center(
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => gradient.createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(PersonalDetailScreen.routeName);
                      },
                      child: Text(
                        "Don't have an account? Sign up",
                        style: GoogleFonts.poppins(
                            fontSize: 17.41,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
