import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:freedom/feature/auth/cubit/login_cubit.dart';
import 'package:freedom/feature/auth/cubit/registration_cubit.dart';
import 'package:freedom/feature/auth/local_data_source/local_user.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/auth/repository/register_repository.dart';
import 'package:freedom/feature/emergency/cubit/emergency_cubit.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/main_activity/cubit/main_activity_cubit.dart';
import 'package:freedom/feature/onboarding/cubit/onboarding_cubit.dart';
import 'package:freedom/feature/profile/cubit/profile_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/cubit/verify_login_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/cubit/verify_otp_cubit.dart';
import 'package:freedom/l10n/l10n.dart';
import 'package:freedom/router/router.dart';
import 'package:freedom/shared/theme/dark_theme.dart';
import 'package:freedom/shared/theme/light_theme.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

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
            create: (context) => RegisterCubit(RegisterRepository()),
          ),
          BlocProvider(
            create: (context) => VerifyOtpCubit(RegisterRepository()),
          ),
          BlocProvider(
            create: (context) => HomeCubit(),
          ),
          BlocProvider(
            create: (context) => EmergencyCubit(),
          ),
          BlocProvider(create: (context) => ProfileCubit()),
          BlocProvider(
              create: (context) => LoginCubit(
                    registerRepository: RegisterRepository(),
                  )),
          BlocProvider(
              create: (context) => VerifyLoginCubit(
                    RegisterRepository(),
                  )),
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

Future<void> initializeStorage() async {
  final appDocumentDirectory =
      await path_provider.getApplicationDocumentsDirectory();
  Hive
    ..init(appDocumentDirectory.path)

    // Register adapters
    ..registerAdapter(UserAdapter());

  // Ensure boxes are open
  await RegisterLocalDataSource.ensureBoxesAreOpen();
}
