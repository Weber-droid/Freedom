import 'package:flutter/material.dart';
import 'package:freedom/feature/auth/login_cubit/login_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:freedom/shared/formatters/count_down_formatter.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});
  static const routeName = '/verify_otp';

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
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
    final loginCubit = BlocProvider.of<LoginCubit>(context);
    final registerCubit = BlocProvider.of<RegisterCubit>(context);

    var phoneNumber = '';
    if (loginCubit.state.phone.isNotEmpty) {
      phoneNumber = loginCubit.state.phone;
    } else if (registerCubit.state.phone.isNotEmpty) {
      phoneNumber = registerCubit.state.phone;
    } else {
      context.showToast(
          message: 'Phone number not found. Please go back and try again.',
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
    final formCubit = BlocProvider.of<RegisterCubit>(context);
    final loginCubit = BlocProvider.of<LoginCubit>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<VerifyOtpCubit, VerifyOtpState>(
        listener: (context, state) {
          if (state.isVerified!) {
            context.showToast(
                message: state.user!.message!, type: ToastType.success);
            Navigator.pushNamedAndRemoveUntil(
              context,
              MainActivityScreen.routeName,
              (route) => false,
            );
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
                    formCubit.state.phone.isEmpty
                        ? loginCubit.state.phone
                        : formCubit.state.phone,
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
                    title: state.status == VerifyOtpStatus.submitting
                        ? 'Loading'
                        : 'Verify',
                    child: state.status == VerifyOtpStatus.submitting
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                          )
                        : null,
                    onPressed: () =>
                        _onVerifyPressed(context, state, formCubit, loginCubit),
                  ),
                ],
              ),
            ),
          );
          if (state.status == VerifyOtpStatus.submitting) {
            return BlurredLoadingOverlay(
              isLoading: state.status == VerifyOtpStatus.submitting,
              child: mainContent,
            );
          }
          return mainContent;
        },
      ),
    );
  }

  void _onVerifyPressed(BuildContext context, VerifyOtpState state,
      RegisterCubit formCubit, LoginCubit loginCubit) {
    log('Loading state: ${state.status}');

    if (_otpFormKey.currentState!.validate()) {
      if (loginCubit.state.phone.isNotEmpty) {
        context
            .read<VerifyOtpCubit>()
            .verifyOtp(loginCubit.state.phone, _otpController.text);
      } else {
        context
            .read<VerifyOtpCubit>()
            .verifyOtp(formCubit.state.phone, _otpController.text);
      }

      // Log states after the verify action
      log('Verification in progress...');
      log('isVerified: ${state.isVerified}, isLoading: ${state.status}');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController
      ..removeListener(() {
        setState(() {});
      });
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
