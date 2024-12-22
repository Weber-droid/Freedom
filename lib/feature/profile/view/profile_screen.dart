import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:freedom/feature/profile/view/address_screen.dart';
import 'package:freedom/feature/profile/view/profile_details_screen.dart';
import 'package:freedom/feature/profile/view/security_screen.dart';
import 'package:freedom/feature/profile/view/wallet_screen.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: Text(
                'Profile',
                style: GoogleFonts.poppins(),
              ),
            ),
            const VSpace(35),
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  height: 215,
                  width: 348,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15, top: 9, right: 13),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '10 Ride Completed',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11.23,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Reward',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11.23,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SvgPicture.asset('assets/images/arrow_right_icon.svg'),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 28,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    height: 187,
                    width: 372,
                    child: Column(
                      children: [
                        const VSpace(13),
                        Container(
                          width: 67,
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Image(
                                image: AssetImage(
                                  'assets/images/user_profile.png',
                                ),
                                fit: BoxFit.fill,
                              ),
                              Positioned(
                                bottom: -2,
                                right: -8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                        color: Colors.black, width: 2),
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/images/edit_profile.svg',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Chale Kumasi',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const VSpace(10),
                        Container(
                          width: 132,
                          height: 24,
                          padding: const EdgeInsets.only(left: 10),
                          decoration: ShapeDecoration(
                            color: Colors.white.withOpacity(0.34),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(34),
                            ),
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                  'assets/images/copy_button_icon.svg'),
                              const HSpace(7),
                              Text(
                                '08012345678',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Business Suite',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const VSpace(10),
            const Divider(
              thickness: 5,
              color: Color(0xFFF1F1F1),
            ),
            const VSpace(22.49),
            PersonalDataSection(
              onProfileTap: () {
                Navigator.pushNamed(context, ProfileDetailsScreen.routeName);
              },
              onWalletTap: () {
                Navigator.pushNamed(context, WalletScreen.routeName);
              },
              paddingSection: const EdgeInsets.all(5),
            ),
            const VSpace(10.49),
            MoreSection(
              onTapAddress: () => Navigator.pushNamed(
                context,
                AddressScreen.routeName,
              ),
              onTapLogout: () {},
              onTapSecurity: () {
                Navigator.pushNamed(
                  context,
                  SecurityScreen.routeName,
                );
              },
              paddingSection: const EdgeInsets.all(5),
            ),
          ],
        ),
      ),
    );
  }
}

abstract class SectionFactory extends StatelessWidget {
  const SectionFactory({
    super.key,
    this.onItemTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 22),
    this.backgroundColor = const Color(0xFFFBFAFA),
    this.titleStyle,
    this.sectionTextStyle,
    this.paddingSection,
  });
  final VoidCallback? onItemTap;
  final EdgeInsets? padding;
  final Color backgroundColor;
  final TextStyle? titleStyle;
  final TextStyle? sectionTextStyle;
  final EdgeInsetsGeometry? paddingSection;

  String get sectionTitle;
  List<SectionItem> get sectionItems;

  Widget _buildSectionItem(SectionItem item) {
    return InkWell(
      onTap: item.onTap ?? onItemTap,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            padding: paddingSection,
            margin: const EdgeInsets.only(left: 16),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            child: SvgPicture.asset(item.iconPath ?? ''),
          ),
          const SizedBox(width: 16),
          Text(
            item.title,
            style: sectionTextStyle ??
                GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Spacer(),
          if (item.subtitle != null)
            Text(
              item.subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 8.27,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w200,
              ),
            ),
          const SizedBox(width: 22),
          if (item.showArrow)
            Padding(
              padding: const EdgeInsets.only(right: 22),
              child: SvgPicture.asset(
                'assets/images/arrow_right_icon.svg',
                colorFilter:
                    const ColorFilter.mode(Colors.black, BlendMode.srcIn),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding!,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sectionTitle,
              textAlign: TextAlign.center,
              style: titleStyle ??
                  GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 10.94,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 6.5),
            Container(
              decoration: ShapeDecoration(
                color: backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < sectionItems.length; i++) ...[
                    if (i == 0) const SizedBox(height: 20),
                    _buildSectionItem(sectionItems[i]),
                    if (i < sectionItems.length - 1) ...[
                      const SizedBox(height: 19),
                      Container(
                        height: 1,
                        color: greyColor,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 19),
                    ] else
                      const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Model class for section items
class SectionItem {
  final String title;
  final String? iconPath;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showArrow;

  const SectionItem({
    required this.title,
    this.iconPath,
    this.subtitle,
    this.onTap,
    this.showArrow = true,
  });
}

// Personal Data Section Implementation
class PersonalDataSection extends SectionFactory {
  const PersonalDataSection(
      {super.key,
      super.onItemTap,
      super.padding,
      super.backgroundColor,
      super.titleStyle,
      super.sectionTextStyle,
      super.paddingSection,
      this.onProfileTap,
      this.onWalletTap});
  final VoidCallback? onProfileTap;

  final VoidCallback? onWalletTap;

  @override
  String get sectionTitle => 'Personal';

  @override
  List<SectionItem> get sectionItems => [
        SectionItem(
          title: 'Profile Details',
          iconPath: 'assets/images/hamburg_icon.svg',
          onTap: () => onProfileTap!(),
        ),
        SectionItem(
          title: 'Wallet',
          iconPath: 'assets/images/gradient_wallet_icon.svg',
          subtitle: 'Coming Soon',
          onTap: () => onWalletTap!(),
        ),
      ];
}

// More Section Implementation
class MoreSection extends SectionFactory {
  const MoreSection({
    super.key,
    super.onItemTap,
    super.padding,
    super.backgroundColor,
    super.titleStyle,
    super.sectionTextStyle,
    super.paddingSection,
    this.onTapAddress,
    this.onTapLogout,
    this.onTapSecurity,
  });
  final VoidCallback? onTapAddress;
  final VoidCallback? onTapSecurity;
  final VoidCallback? onTapLogout;
  @override
  String get sectionTitle => 'More';

  @override
  List<SectionItem> get sectionItems => [
        SectionItem(
            title: 'Address',
            iconPath: 'assets/images/address_icon.svg',
            onTap: onTapAddress),
        SectionItem(
            title: 'Security and Privacy',
            iconPath: 'assets/images/security_icon.svg',
            onTap: onTapSecurity),
        SectionItem(
            title: 'Logout',
            iconPath: 'assets/images/free_logout.svg',
            onTap: onTapLogout),
      ];
}
