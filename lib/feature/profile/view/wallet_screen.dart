import 'package:dotted_border/dotted_border.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/profile/view/profile_screen.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/verify_otp_screen.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:google_fonts/google_fonts.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  static const routeName = '/wallet';

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 27),
                  child: DecoratedBackButton(),
                ),
                const HSpace(84.91),
                Expanded(
                  child: Text(
                    'Wallet',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 13.09,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer()
              ],
            ),
            const VSpace(14.91),
            Stack(
              children: [
                const Image(
                  image: AssetImage('assets/images/decorated_more.png'),
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 30,
                  left: 25,
                  right: 25,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Account Balance',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Momo Pay',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 25,
                  right: 25,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        r'$0.00',
                        style: GoogleFonts.poppins(
                            fontSize: 27,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.only(
                            left: 10, right: 10, top: 3, bottom: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xfff8c060),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                                'assets/images/copy_button_icon.svg'),
                            Text(
                              '2627829012718',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Positioned(
                  top: 110,
                  left: 25,
                  right: 25,
                  child: DottedBorder(
                    radius: const Radius.circular(10),
                    borderType: BorderType.RRect,
                    color: Colors.white,
                    child: Container(
                      height: 80,
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xff8F5C06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 13,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                      'assets/images/arrow-left-down.svg'),
                                  const HSpace(2),
                                  Text(
                                    'Add Money',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white, fontSize: 16.9),
                                  )
                                ],
                              )),
                          const Spacer(),
                          TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 13,
                                ),
                              ),
                              onPressed: () {},
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                      'assets/images/transaction_icon.svg'),
                                  const HSpace(2),
                                  Text(
                                    'Transaction',
                                    style: GoogleFonts.poppins(
                                        color: Colors.black, fontSize: 16.9),
                                  )
                                ],
                              ))
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
            const VSpace(14.91),
            Container(
              height: 8,
              color: greyColor,
            ),
            VSpace(14.91),
            ManagePayment(),
          ],
        ),
      ),
    );
  }
}

class ManagePayment extends SectionFactory {
  ManagePayment(
      {super.key,
      super.backgroundColor,
      super.padding,
      super.titleStyle,
      super.onItemTap,
      super.paddingSection,
      super.sectionTextStyle,
      this.onMasterCardTap,
      this.onVisaCardTap});
  final VoidCallback? onMasterCardTap;
  final VoidCallback? onVisaCardTap;
  @override
  List<SectionItem> get sectionItems => [
        SectionItem(
          title: '*** **** 1234',
          iconPath: 'assets/images/mastercard.svg',
          onTap: onMasterCardTap,
        ),
        SectionItem(
          title: '*** **** 1234',
          iconPath: 'assets/images/visa_electron.svg',
          onTap: () => onVisaCardTap,
        )
      ];

  @override
  String get sectionTitle => 'Manage Payment Method';
}
