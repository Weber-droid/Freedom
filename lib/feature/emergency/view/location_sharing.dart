import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:freedom/feature/emergency/view/emergency_chat.dart';
import 'package:freedom/feature/emergency/view/emergency_screen.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationSharing extends StatefulWidget {
  const LocationSharing({super.key});
  static const routeName = '/location-sharing';

  @override
  State<LocationSharing> createState() => _LocationSharingState();
}

class _LocationSharingState extends State<LocationSharing> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EmergencyAppBar(
            title: 'Location Sharing',
            decoratedImageSource: 'assets/images/decorated_image3.png',
            gifUrl:
                'https://s3-alpha-sig.figma.com/img/7bb9/14a6/16a0544f0bfd59219d4d4ad65836cdec?Expires=1735516800&Key-Pair-Id=APKAQ4GOSFWCVNEHN3O4&Signature=oboMvIrZotKckTB~IsT0BUKVZf-QiC2zAEmb~OO6vMTyNsJLxdNvPU6IzIrrB9Ie3O--sdI8nm3O4qLLz-wOguCvE6ZNs-lb0c~DiLEAYBX-qRG4mmwCaX3031PT-MbAozDlDJFwHALzRcE6drXpp6HMIfmenHwEReCzqUh3XXv~5IkAx~ulNVMfz6RwNlrxtrtwSYbCTu5k-759ODoRO7fwygx57MBU57dh5oC6Hu1iTqbDkVqzoLAgheAn-d5XlVf1ohFL22XTtGN10S5xdj0ZLkf5KsFjL4D1fl26xn9IuMS6FLt11MPDgVd5V~OXK6WNb~VIZ-iXckqGwtqbQQ__',
          ),
          const VSpace(23),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help is closer when they know where you are',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 14.24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const VSpace(12),
                SizedBox(
                  width: 378,
                  child: Text(
                    'To ensure a swift response, share your real-time location with emergency services. Your location will only be shared during this emergency session.',
                    style: GoogleFonts.poppins(
                      color: Colors.black.withOpacity(0.5),
                      fontSize: 14.24,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                const VSpace(14),
                Container(
                  padding: const EdgeInsets.only(
                      left: 11, top: 17, right: 11, bottom: 17),
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                      color: greyColor, borderRadius: BorderRadius.circular(5)),
                  child: Column(
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
                                'assets/images/nav_icon.svg',
                              ),
                            ),
                            const HSpace(9),
                            Text(
                              'Share Your Location',
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const VSpace(31),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context)
                              .pushNamed(EmergencyChat.routeName);
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
                              borderRadius: BorderRadius.circular(6)),
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
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
