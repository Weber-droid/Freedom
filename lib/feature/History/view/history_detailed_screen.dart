import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/History/view/history_screen.dart';
import 'package:freedom/feature/home/view/home_screen.dart';
import 'package:freedom/feature/home/view/widgets.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:freedom/shared/widgets/stacked_bottom_sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HistoryDetailedScreen extends StatefulWidget {
  const HistoryDetailedScreen({super.key});
  static const routeName = '/history_detailed_screen';

  @override
  State<HistoryDetailedScreen> createState() => _HistoryDetailedScreenState();
}

class _HistoryDetailedScreenState extends State<HistoryDetailedScreen> {
  static const LatLng sanFrancisco = LatLng(37.774546, -122.433523);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const GoogleMap(
            initialCameraPosition: CameraPosition(
              target: sanFrancisco,
              zoom: 13,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.58,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Stack(
                children: [
                  stackedBottomSheet(
                    context,
                    useOnlyBackgroundColor: true,
                    topLeftRadius: 0,
                    topRightRadius: 0,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 23),
                      child: Column(
                        children: [
                          const VSpace(41),
                          Row(
                            children: [
                              const SizedBox(
                                height: 44,
                                width: 44,
                                child: Image(
                                  image: AssetImage(
                                      'assets/images/rider_profile_image.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const HSpace(7.01),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chale Emma',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontSize: 7.95,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    'XRFSGT2D',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontSize: 14.83,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const RideType()
                                ],
                              ),
                              const Spacer(),
                              SvgPicture.asset(
                                  'assets/images/checked_icon.svg'),
                              const HSpace(4),
                              TextButton(
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero),
                                onPressed: () {},
                                child: Text(
                                  'Completed',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF0BF535),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const VSpace(10.4),
                          Container(
                            height: 85,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFFCFCFC),
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  width: 0.98,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                  color: Color(0xFFF5F5F5),
                                ),
                                borderRadius: BorderRadius.circular(14.01),
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                VSpace(16),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 7),
                                  child: Row(
                                    children: [
                                      RiderTimeLine(
                                        destinationDetails: 'Ghana, Kumasi',
                                        pickUpDetails: 'Chale, Kumasi',
                                      ),
                                      Spacer(),
                                      OrderRideAgainButton()
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          const VSpace(25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Fare Paid',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 9.65,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return darkGoldGradient.createShader(bounds);
                                },
                                child: Text(
                                  r'$12.50',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFF59E0B),
                                    fontSize: 9.97,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            ],
                          ),
                          const VSpace(8),
                          FreedomButton(
                            width: double.infinity,
                            onPressed: () {},
                            title: 'Rate Rider',
                            buttonTitle: Text(
                              'Rate Rider',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backGroundColor: Colors.black,
                          ),
                          const VSpace(16),
                          FreedomButton(
                            width: double.infinity,
                            onPressed: () {},
                            useOnlBorderGradient: true,
                            useGradient: true,
                            buttonTitle: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return darkGoldGradient.createShader(bounds);
                              },
                              child: Text(
                                'Support',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const VSpace(34)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.54,
            child: Container(
              height: 72,
              padding: const EdgeInsets.only(top: 18, bottom: 18, left: 15),
              margin: const EdgeInsets.symmetric(horizontal: 23),
              width: MediaQuery.of(context).size.width - 46,
              decoration: ShapeDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Color(0xFFF4F4F4), Color(0xFF51C01A)],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(8),
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                        side: const BorderSide(
                          width: 0.98,
                          strokeAlign: BorderSide.strokeAlignOutside,
                          color: Color(0xFFF5F5F5),
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: ShapeDecoration(
                        color: const Color(0xffe5efe0).withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.5),
                          side: const BorderSide(
                            width: 0.98,
                            strokeAlign: BorderSide.strokeAlignOutside,
                            color: Color(0xFFF5F5F5),
                          ),
                        ),
                      ),
                      child: SvgPicture.asset(
                        'assets/images/motorcycle_outline.svg',
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const HSpace(11),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Text(
                        'Ride Completed',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12.96,
                          fontWeight: FontWeight.w600,
                        ),
                      )),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              'Ghana ,Kumasi',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10.85,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              'Jan 10, 4:45',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10.85,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
