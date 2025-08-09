import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/auth/login_cubit/login_cubit.dart';
import 'package:freedom/feature/auth/social_auth_cubit/cubit/apple_auth_cubit.dart';
import 'package:freedom/feature/auth/social_auth_cubit/google_auth_cubit.dart';
import 'package:freedom/feature/auth/view/personal_detail_screen.dart';
import 'package:freedom/feature/main_activity/main_activity_screen.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/complete_registration.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/verify_login_view.dart';
import 'package:freedom/shared/enums/enums.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:freedom/shared/widgets/loading_overlay.dart';
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

  @override
  void initState() {
    super.initState();
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
      body: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state.formStatus == FormStatus.success) {
            context.showToast(
              message: state.message,
              position: ToastPosition.top,
              type: ToastType.success,
            );
            Navigator.of(context).pushNamed(VerifyLoginScreen.routeName);
          } else if (state.formStatus == FormStatus.failure) {
            if (state.message.contains('Complete registration first.')) {
              context.showToast(
                message: 'Please verify your phone number',
                position: ToastPosition.top,
                type: ToastType.warning,
              );
              Future.delayed(const Duration(milliseconds: 1000), () {
                Navigator.of(context).pushNamed(CompleteRegistration.routeName);
              });
            } else {
              context.showToast(
                message: state.message,
                position: ToastPosition.top,
                type: ToastType.error,
              );
            }
          }
        },
        builder: (context, state) {
          Widget mainContent;
          mainContent = SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VSpace(67),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: SvgPicture.asset('assets/images/login_logo.svg'),
                ),
                const VSpace(20.37),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  child: Text(
                    'Enter your phone number',
                    style: GoogleFonts.poppins(
                      fontSize: 15.6,
                      fontWeight: FontWeight.w500,
                    ),
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
                                  textStyle: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                  dialogTextStyle: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                  dialogSize: const Size(300, 200),
                                  onChanged: (value) {},
                                  padding: EdgeInsets.zero,
                                  initialSelection: 'GH',
                                  hideMainText: true,
                                ),
                                Positioned(
                                  top:
                                      MediaQuery.of(context).size.height *
                                      0.014,
                                  left:
                                      MediaQuery.of(context).size.width * 0.11,
                                  child: SvgPicture.asset(
                                    'assets/images/drop_down.svg',
                                  ),
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

                        return null;
                      },
                    ),
                  ),
                ),
                const VSpace(29),
                _buildLoginButton(context),
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
                        fontSize: 15.36,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 7,
                      width: 167,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: colorGrey,
                      ),
                    ),
                  ],
                ),
                const VSpace(28),
                if (Platform.isIOS) ...[_buildAppleLoginButton()],
                if (Platform.isAndroid) ...[
                  const VSpace(20),
                  _buildGoogleLoginButton(),
                ],
                const VSpace(17),
                Center(
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback:
                        (bounds) => gradient.createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed(PersonalDetailScreen.routeName);
                      },
                      child: Text(
                        "Don't have an account? Sign up",
                        style: GoogleFonts.poppins(
                          fontSize: 17.41,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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

  Widget _buildLoginButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: FreedomButton(
        backGroundColor: Colors.black,
        borderRadius: BorderRadius.circular(7),
        width: double.infinity,
        title: 'Continue',
        buttonTitle: Text(
          'Continue',
          style: GoogleFonts.poppins(
            fontSize: 17.4,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        onPressed: () {
          if (fromKey.currentState!.validate()) {
            final phoneNumber = getFullPhoneNumber();
            context.read<LoginCubit>().setPhoneNumber(phoneNumber);
            context.read<LoginCubit>().loginUserWithPhoneNumber();
          }
        },
      ),
    );
  }

  Widget _buildGoogleLoginButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: BlocConsumer<GoogleAuthCubit, GoogleAuthState>(
        listener: (context, state) {
          if (state.formStatus == FormStatus.failure) {
            context.showToast(
              message: state.message,
              type: ToastType.error,
              position: ToastPosition.top,
            );
          }

          if (state.phoneStatus == PhoneStatus.failure) {
            context.showToast(
              message: state.message,
              type: ToastType.error,
              position: ToastPosition.top,
            );
          }

          if (state.formStatus == FormStatus.success) {
            context.showToast(
              message: state.message,
              type: ToastType.success,
              position: ToastPosition.top,
            );
            Future.delayed(const Duration(milliseconds: 300), () {
              Navigator.pushReplacementNamed(
                context,
                MainActivityScreen.routeName,
              );
            });
          }
        },
        builder: (context, state) {
          if (state.formStatus == FormStatus.submitting) {
            return const Center(child: CircularProgressIndicator());
          }

          return FreedomButton(
            backGroundColor: socialLoginColor,
            leadingIcon: 'google_icon',
            borderRadius: BorderRadius.circular(7),
            buttonTitle: Text(
              'Login with Google',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            titleColor: Colors.black,
            fontSize: 16,
            width: double.infinity,
            onPressed: () {
              context.read<GoogleAuthCubit>().registerOrLoginWithGoogle();
            },
          );
        },
      ),
    );
  }

  Widget _buildAppleLoginButton() {
    return BlocConsumer<AppleAuthCubit, AppleAuthState>(
      listener: (context, state) {
        if (state.formStatus == FormStatus.failure) {
          context.showToast(
            message: state.message,
            type: ToastType.error,
            position: ToastPosition.top,
          );
        }

        if (state.phoneStatus == PhoneStatus.failure) {
          context.showToast(
            message: state.message,
            type: ToastType.error,
            position: ToastPosition.top,
          );
        }

        if (state.formStatus == FormStatus.success) {
          context.showToast(
            message: state.message,
            type: ToastType.success,
            position: ToastPosition.top,
          );
          Future.delayed(const Duration(milliseconds: 300), () {
            Navigator.pushReplacementNamed(
              context,
              MainActivityScreen.routeName,
            );
          });
        }
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17),
          child: FreedomButton(
            backGroundColor: socialLoginColor,
            leadingIcon: 'apple_icon',
            borderRadius: BorderRadius.circular(7),
            title: 'Login with Apple',
            buttonTitle: Text(
              'Login with Apple',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            titleColor: Colors.black,
            width: double.infinity,
            fontSize: 16,
            onPressed: () {
              context.read<AppleAuthCubit>().registerOrLoginWithApple();
            },
          ),
        );
      },
    );
  }
}
