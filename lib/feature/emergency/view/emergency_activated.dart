import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/emergency/view/emergency_screen.dart';
import 'package:freedom/feature/emergency/view/location_sharing.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:google_fonts/google_fonts.dart';

class EmergencyActivated extends StatefulWidget {
  const EmergencyActivated({super.key});
  static const routeName = '/emergency-activated';

  @override
  State<EmergencyActivated> createState() => _EmergencyActivatedState();
}

class _EmergencyActivatedState extends State<EmergencyActivated> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EmergencyAppBar(
              title: 'Emergency Assistance Activated',
              decoratedImageSource: 'assets/images/decorated_image_source2.png',
              useNetworkImage: false,
              imageSource: 'assets/images/emergency_9.svg',
              positionLeft: 153,
              positionRight: 116,
              positionBottom: 42,
            ),
            const VSpace(13),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help is on the way',
                    style: GoogleFonts.poppins(
                      fontSize: 14.24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const VSpace(12),
                  Text(
                    'Emergency assistance has been activated. Stay on the line; help is on the way. Share your location with emergency services for a faster response.',
                    style: GoogleFonts.poppins(
                      color: Colors.black.withOpacity(0.5),
                      fontSize: 14.24,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const VSpace(21),
                  Container(
                    padding: const EdgeInsets.only(
                        left: 11, top: 17, right: 11, bottom: 17),
                    width: screenWidth * 0.9,
                    decoration: BoxDecoration(
                      color: greyColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 17,
                                height: 17,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: const Color(0x87D9D9D9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: SvgPicture.asset(
                                  'assets/images/checked.svg',
                                ),
                              ),
                              const HSpace(9),
                              Text(
                                'Emergency Assistance Complete',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const VSpace(10),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            decoration: BoxDecoration(
                                gradient: gradient,
                                borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.only(top: 11, bottom: 11),
                            child: Center(
                              child: Text(
                                'Contact Support',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const VSpace(12),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              LocationSharing.routeName,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                gradient: gradient,
                                borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.only(top: 11, bottom: 11),
                            child: Center(
                              child: Text(
                                'Share Location',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const VSpace(12),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.only(top: 11, bottom: 11),
                            child: Center(
                              child: Text(
                                'Continue',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
