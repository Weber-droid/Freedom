import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:freedom/feature/main_activity/cubit/main_activity_cubit.dart';
import 'package:freedom/feature/onboarding/cubit/onboarding_cubit.dart';
import 'package:freedom/feature/registration/cubit/forms_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/cubit/verify_otp_cubit.dart';
import 'package:freedom/l10n/l10n.dart';
import 'package:freedom/router/router.dart';
import 'package:freedom/shared/theme/dark_theme.dart';
import 'package:freedom/shared/theme/light_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(402, 874),
      splitScreenMode: true,
      minTextAdapt: true,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => MainActivityCubit(),
          ),
          BlocProvider(
            create: (context) => OnboardingCubit(),
          ),
          BlocProvider(
            create: (context) => RegisterFormCubit(),
          ),
          BlocProvider(
            create: (context) => VerifyOtpCubit(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: getLightTheme,
          darkTheme: getDarkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateRoute: onGenerateRoute,
        ),
      ),
    );
  }
}
