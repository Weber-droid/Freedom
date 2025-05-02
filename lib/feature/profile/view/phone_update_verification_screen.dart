import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/main_activity/main_activity_screen.dart';
import 'package:freedom/feature/profile/cubit/profile_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/cubit/verify_otp_cubit.dart';
import 'package:freedom/shared/formatters/count_down_formatter.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:freedom/shared/widgets/loading_overlay.dart';
import 'package:freedom/shared/widgets/toasts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PhoneUpdateVerificationScreen extends StatefulWidget {
  const PhoneUpdateVerificationScreen({super.key});
  static const routeName = '/phone_update_verification_screen';

  @override
  State<PhoneUpdateVerificationScreen> createState() =>
      _PhoneUpdateVerificationScreenState();
}

class _PhoneUpdateVerificationScreenState
    extends State<PhoneUpdateVerificationScreen> {
  final _otpFormKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  Timer? _timer;
  int _start = 600;
  @override
  void initState() {
    super.initState();
    _otpController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNode.requestFocus();
      _startTimer();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_start > 0) {
          _start--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _resendOtp() {
    final profileCubit = BlocProvider.of<ProfileCubit>(context);

    String? phoneNumber;
    if (profileCubit.state is NumberUpdated) {
      phoneNumber = (profileCubit.state as NumberUpdated).phoneNumber;
    }

    if (phoneNumber == null || phoneNumber.isEmpty) {
      context.showToast(
          message: 'Phone number not found in profile. Please try again.',
          position: ToastPosition.top,
          type: ToastType.error);
      return;
    }

    context
        .read<VerifyOtpCubit>()
        .resendOtp(phoneNumber, 'registration')
        .then((_) {
      _start = 600;
      _startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileCubit = BlocProvider.of<ProfileCubit>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is OtpVerified) {
            context.showToast(
                message: state.isVerified ? 'Verified' : 'Not verified',
                type: ToastType.success,
                position: ToastPosition.top);
            Navigator.pushNamedAndRemoveUntil(
              context,
              MainActivityScreen.routeName,
              (route) => false,
            );
          }

          if (state is OtpVerificationError) {
            context.showToast(
                message: state.message,
                type: ToastType.error,
                position: ToastPosition.top);
          }
        },
        builder: (context, state) {
          Widget mainContent;

          mainContent = SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  InkWell(
                    onTap: () {
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const DecoratedBackButton(),
                  ),
                  const VSpace(35.45),
                  Text(
                    'Enter Code',
                    style: GoogleFonts.poppins(
                        fontSize: 29.02, color: Colors.black),
                  ),
                  const VSpace(5),
                  Text(
                    'An SMS code was sent to',
                    style: GoogleFonts.poppins(
                      fontSize: 17.67,
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ),
                  const VSpace(5.3),
                  Text(
                    profileCubit.phoneNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 19.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const VSpace(17),
                  Form(
                    key: _otpFormKey,
                    child: PinCodeTextField(
                      focusNode: _otpFocusNode,
                      appContext: context,
                      textStyle: GoogleFonts.poppins(
                        fontSize: 19.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      pastedTextStyle: TextStyle(
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                      onCompleted: (val) {
                        if (mounted) {}
                      },
                      length: 6,
                      obscureText: true,
                      obscuringCharacter: '*',
                      blinkWhenObscuring: true,
                      animationType: AnimationType.fade,
                      autoDisposeControllers: false,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(5).w,
                        fieldHeight: 45.h,
                        fieldWidth: 40.w,
                        activeFillColor: Colors.white,
                        inactiveFillColor: fillColor,
                        activeColor: thickFillColor,
                        inactiveColor: const Color(0x21F59E0B),
                        selectedColor: thickFillColor,
                        selectedFillColor: fillColor,
                        borderWidth: 1,
                        activeBorderWidth: 1,
                      ),
                      cursorColor: Colors.black,
                      animationDuration: const Duration(milliseconds: 300),
                      enableActiveFill: true,
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      boxShadows: const [
                        BoxShadow(
                          offset: Offset(0, 1),
                          color: Colors.black12,
                          blurRadius: 10,
                        )
                      ],
                      onChanged: (value) {
                        if (mounted) {
                          log(value);
                        }
                      },
                      beforeTextPaste: (text) {
                        return true;
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 21,
                  ),
                  if (_start != 0)
                    Text(
                      'Resend code in 0:${formatTimeLeft(_start)}',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  else if (_start == 0)
                    InkWell(
                      onTap: _resendOtp,
                      child: Text(
                        'Resend Code',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  const VSpace(21),
                  FreedomButton(
                    backGroundColor: Colors.black,
                    useLoader: true,
                    borderRadius: BorderRadius.circular(10),
                    width: double.infinity,
                    title: state is VerifyingOtp ? 'Loading' : 'Verify',
                    onPressed: () => _onVerifyPressed(context),
                  ),
                ],
              ),
            ),
          );
          if (state is VerifyingOtp) {
            return BlurredLoadingOverlay(
              isLoading: true,
              child: mainContent,
            );
          }
          return mainContent;
        },
      ),
    );
  }

  void _onVerifyPressed(
    BuildContext context,
  ) {
    if (_otpFormKey.currentState!.validate()) {
      log('caller here');
      context.read<ProfileCubit>().verifyPhoneNumberUpdate(_otpController.text);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController
      ..removeListener(() {
        setState(() {});
      })
      ..dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }
}

class DecoratedBackButton extends StatelessWidget {
  const DecoratedBackButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        height: 38.09,
        width: 38.09,
        decoration:
            const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8.86, 8.86, 9.74, 9.74),
          child: SvgPicture.asset('assets/images/back_button.svg'),
        ),
      ),
      onTap: () => Navigator.pop(context),
    );
  }
}
