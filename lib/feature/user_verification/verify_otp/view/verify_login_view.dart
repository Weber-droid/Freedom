import 'package:flutter/material.dart';
import 'package:freedom/feature/auth/auth_cubit/auth_cubit.dart';
import 'package:freedom/feature/auth/cubit/login_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/cubit/verify_login_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';

class VerifyLoginScreen extends StatefulWidget {
  const VerifyLoginScreen({super.key});
  static const routeName = '/verify-login';

  @override
  State<VerifyLoginScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyLoginScreen> {
  final _otpFormKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  Timer? _timer;
  int _start = 10;
  @override
  void initState() {
    super.initState();
    _otpController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNode.requestFocus();
    });
    _startTimer();
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

  @override
  Widget build(BuildContext context) {
    final loginCubit = BlocProvider.of<AuthCubit>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            context.showToast(
                message: 'Login successful', type: ToastType.success);
            Navigator.pushNamedAndRemoveUntil(
              context,
              MainActivityScreen.routeName,
              (route) => false,
            );
          } else if (state is AuthFailure){
            context.showToast(
                message: state.message,
                position: ToastPosition.top,
                type: ToastType.error);
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
                    'Enter OTP to login',
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
                    loginCubit.state.phoneNumber ?? '',
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
                      'Resend code in 0:$_start',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  else if (_start == 0)
                    InkWell(
                      onTap: () {
                        _start = 10;
                        _startTimer();
                      },
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
                    title: state is AuthLoading
                        ? 'Loading'
                        : 'Verify',
                    child: state is AuthLoading
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                          )
                        : null,
                    onPressed: () =>
                        _onVerifyPressed(context, state, loginCubit),
                  ),
                ],
              ),
            ),
          );
          if (state is AuthLoading) {
            return BlurredLoadingOverlay(
              isLoading: state is AuthLoading,
              child: mainContent,
            );
          }
          return mainContent;
        },
      ),
    );
  }

  void _onVerifyPressed(
      BuildContext context, AuthState state, AuthCubit authCubit) {
    if (_otpFormKey.currentState!.validate()) {
      context.read<AuthCubit>().setPhoneNumber(authCubit.state.phoneNumber ?? '');
      context.read<AuthCubit>().verifyOtp(_otpController.text);
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
