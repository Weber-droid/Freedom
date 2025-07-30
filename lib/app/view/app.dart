import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/History/cubit/history_cubit.dart';
import 'package:freedom/feature/auth/cubit/registration_cubit.dart';
import 'package:freedom/feature/auth/local_data_source/local_user.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/auth/login_cubit/login_cubit.dart';
import 'package:freedom/feature/auth/repository/register_repository.dart';
import 'package:freedom/feature/auth/social_auth_cubit/google_auth_cubit.dart';
import 'package:freedom/feature/emergency/cubit/emergency_cubit.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/home/delivery_cubit/delivery_cubit.dart';
import 'package:freedom/feature/home/ride_cubit/ride_cubit.dart';
import 'package:freedom/feature/main_activity/cubit/main_activity_cubit.dart';
import 'package:freedom/feature/message_driver/cache/in_app_message_cache.dart';
import 'package:freedom/feature/message_driver/cubit/in_app_message_cubit.dart';
import 'package:freedom/feature/message_driver/models/message_models.dart';
import 'package:freedom/feature/onboarding/cubit/onboarding_cubit.dart';
import 'package:freedom/feature/profile/cubit/profile_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/cubit/verify_login_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/cubit/verify_otp_cubit.dart';
import 'package:freedom/feature/wallet/cubit/wallet_cubit.dart';
import 'package:freedom/feature/wallet/repository/repository.dart';
import 'package:freedom/router/router.dart';
import 'package:freedom/shared/theme/dark_theme.dart';
import 'package:freedom/shared/theme/light_theme.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(402, 874),
      splitScreenMode: true,
      minTextAdapt: true,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => MainActivityCubit()),
          BlocProvider(create: (context) => OnboardingCubit()),
          BlocProvider(
            create: (context) => RegisterCubit(RegisterRepository()),
          ),
          BlocProvider(
            create: (context) => VerifyOtpCubit(RegisterRepository()),
          ),
          BlocProvider(create: (context) => EmergencyCubit()),
          BlocProvider(create: (context) => getIt<HomeCubit>()),
          BlocProvider(create: (context) => getIt<RideCubit>()),
          BlocProvider(
            create: (context) => HistoryCubit(rideRequestRepository: getIt()),
          ),
          BlocProvider(create: (context) => ProfileCubit()),
          BlocProvider(
            create:
                (context) =>
                    LoginCubit(registerRepository: RegisterRepository()),
          ),
          BlocProvider(
            create: (context) => VerifyLoginCubit(RegisterRepository()),
          ),
          BlocProvider(create: (context) => WalletCubit(WalletRepository())),
          BlocProvider(
            create: (context) => GoogleAuthCubit(RegisterRepository()),
          ),
          BlocProvider(create: (context) => getIt<DeliveryCubit>()),
          BlocProvider(create: (context) => getIt<InAppMessageCubit>()),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: getLightTheme,
          darkTheme: getDarkTheme,
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
    ..registerAdapter(UserAdapter())
    ..registerAdapter(ConversationAdapter())
    ..registerAdapter(MessageModelsAdapter())
    ..registerAdapter(MessageStatusAdapter());

  // Ensure boxes are open
  await RegisterLocalDataSource.ensureBoxesAreOpen();
  await InAppMessageCache.init();
}
