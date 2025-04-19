import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:freedom/feature/History/view/history_detailed_screen.dart';
import 'package:freedom/feature/auth/view/login_view.dart';
import 'package:freedom/feature/auth/view/personal_detail_screen.dart';
import 'package:freedom/feature/auth/view/phone_number_screen.dart';
import 'package:freedom/feature/auth/view/register_form_screen.dart';
import 'package:freedom/feature/emergency/view/emergency_activated.dart';
import 'package:freedom/feature/emergency/view/emergency_chat.dart';
import 'package:freedom/feature/emergency/view/location_sharing.dart';
import 'package:freedom/feature/home/view/home_screen.dart';
import 'package:freedom/feature/main_activity/main_activity_screen.dart';
import 'package:freedom/feature/onboarding/view/carousel_view.dart';
import 'package:freedom/feature/profile/view/address_screen.dart';
import 'package:freedom/feature/profile/view/phone_update_verification_screen.dart';
import 'package:freedom/feature/profile/view/profile_details_screen.dart';
import 'package:freedom/feature/profile/view/security_screen.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/complete_registration.dart';
import 'package:freedom/feature/wallet/view/wallet_screen.dart';
import 'package:freedom/feature/splash/splash_screen.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/verify_login_view.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/verify_otp_screen.dart';
import 'package:freedom/router/error_page.dart';

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  log('Requested route: ${settings.name}');

  switch (settings.name) {
    case SplashPage.routeName:
      return _pageBuilder(
        (context) => const SplashPage(),
        settings: settings,
      );
    case MainActivityScreen.routeName:
      return _pageBuilder(
        (context) => const MainActivityScreen(),
        settings: settings,
      );
    case CarouselViewer.routeName:
      return _pageBuilder(
        (context) => const CarouselViewer(),
        settings: settings,
      );
    case RegisterFormScreen.routeName:
      return _pageBuilder(
        (context) => const RegisterFormScreen(),
        settings: settings,
      );
    case VerifyOtpScreen.routeName:
      return _pageBuilder(
        (context) => const VerifyOtpScreen(),
        settings: settings,
      );
    case PersonalDetailScreen.routeName:
      return _pageBuilder(
        (context) => const PersonalDetailScreen(),
        settings: settings,
      );
    case HistoryDetailedScreen.routeName:
      return _pageBuilder(
        (context) => const HistoryDetailedScreen(),
        settings: settings,
      );
    case EmergencyActivated.routeName:
      return _pageBuilder(
        (context) => const EmergencyActivated(),
        settings: settings,
      );
    case LocationSharing.routeName:
      return _pageBuilder(
        (context) => const LocationSharing(),
        settings: settings,
      );
    case EmergencyChat.routeName:
      return _pageBuilder(
        (context) => const EmergencyChat(),
        settings: settings,
      );
    case ProfileDetailsScreen.routeName:
      return _pageBuilder(
        (context) => const ProfileDetailsScreen(),
        settings: settings,
      );
    case WalletScreen.routeName:
      return _pageBuilder(
        (context) => const WalletScreen(),
        settings: settings,
      );
    case AddressScreen.routeName:
      return _pageBuilder(
        (context) => const AddressScreen(),
        settings: settings,
      );
    case SecurityScreen.routeName:
      return _pageBuilder(
        (context) => const SecurityScreen(),
        settings: settings,
      );
    case LoginView.routeName:
      return _pageBuilder(
            (context) => const LoginView(),
        settings: settings,
      );
    case VerifyLoginScreen.routeName:
      return _pageBuilder(
            (context) => const VerifyLoginScreen(),
        settings: settings,
      );
    case PhoneNumberScreen.routeName:
      return _pageBuilder(
            (context) => const PhoneNumberScreen(),
        settings: settings,
      );
    case CompleteRegistration.routeName:
      return _pageBuilder(
            (context) => const CompleteRegistration(),
        settings: settings,
      );
    case PhoneUpdateVerificationScreen.routeName:
      return _pageBuilder(
            (context) => const PhoneUpdateVerificationScreen(),
        settings: settings,
      );
    default:
      return _pageBuilder(
        (context) => const ErrorPage(),
        settings: settings,
      );
  }
}

PageRouteBuilder<dynamic> _pageBuilder(
  Widget Function(BuildContext context) pageBuilder, {
  required RouteSettings settings,
}) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, _, __) => pageBuilder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}
