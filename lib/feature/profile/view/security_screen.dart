import 'package:flutter/material.dart';
import 'package:freedom/feature/profile/view/profile_screen.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/verify_otp_screen.dart';
import 'package:freedom/shared/utilities.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});
  static const routeName = '/security-screen';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
          child: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 27),
                child: DecoratedBackButton(),
              ),
              HSpace(84.91),
              Expanded(
                child: Center(
                  child: Text(
                    'Security and Privacy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13.09,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Spacer()
            ],
          ),
          VSpace(14.91),
          SecurityAndPrivacy()
        ],
      )),
    );
  }
}

class SecurityAndPrivacy extends SectionFactory {
  const SecurityAndPrivacy({
    super.key,
    this.onTap2FA,
    this.onTapTrustedDevices,
    this.onTapManageLocation,
  }) : super();
  final VoidCallback? onTap2FA;
  final VoidCallback? onTapTrustedDevices;
  final VoidCallback? onTapManageLocation;
  @override
  List<SectionItem> get sectionItems => [
        SectionItem(
          title: '2FA',
          iconPath: 'assets/images/2fa_icon.svg',
          onTap: onTap2FA,
        ),
        SectionItem(
          title: 'Trusted Devices',
          iconPath: 'assets/images/trusted_devices_icon.svg',
          onTap: onTapTrustedDevices,
        ),
        SectionItem(
          title: 'Manage Location Settings',
          iconPath: 'assets/images/manage_location.svg',
          onTap: onTapManageLocation,
        ),
      ];

  @override
  String get sectionTitle => 'Secure your account';
}
