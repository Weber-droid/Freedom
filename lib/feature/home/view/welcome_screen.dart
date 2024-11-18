import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  static const routeName = '/welcome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 33),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VSpace(164),
            Text(
              'Welcome to GoFreedom',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 35.80,
                fontWeight: FontWeight.w500,
              ),
            ),
            const VSpace(10),
            Text(
              'We are customising your Experience',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
            const VSpace(58),
            SvgPicture.asset('assets/images/location_icon.svg'),
          ],
        ),
      ),
    );
  }
}
