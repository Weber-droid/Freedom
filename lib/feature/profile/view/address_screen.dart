import 'package:flutter/material.dart';
import 'package:freedom/feature/profile/view/profile_screen.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/verify_otp_screen.dart';
import 'package:freedom/shared/sections_tiles.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/text_field_factory.dart';
import 'package:google_fonts/google_fonts.dart';

class AddressScreen extends StatelessWidget {
  const AddressScreen({super.key});
  static const routeName = '/address';

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
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
                    'Address',
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
            Container(
              height: 8,
              color: greyColor,
            ),
            const VSpace(10.91),
            Padding(
              padding: const EdgeInsets.only(left: 27, right: 27),
              child: TextFieldFactory.name(
                controller: controller,
                fillColor: greyColor,
                hinText: 'Search',
                suffixIcon: Icon(Icons.search),
                hintTextStyle: GoogleFonts.poppins(),
              ),
            ),
            const VSpace(10.91),
            const AddressSearchWidget()
          ],
        ),
      ),
    );
  }
}

class AddressSearchWidget extends SectionFactory {
  const AddressSearchWidget(
      {super.key,
      super.padding,
      super.backgroundColor,
      super.onItemTap,
      super.paddingSection,
      super.sectionTextStyle,
      super.titleStyle});

  @override
  List<SectionItem> get sectionItems => [
        const SectionItem(
          title: 'Home',
        ),
      ];

  @override
  String get sectionTitle => '';
}
