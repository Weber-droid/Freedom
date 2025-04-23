import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/History/enums.dart';
import 'package:freedom/feature/History/model/history_model.dart';
import 'package:freedom/feature/History/view/history_detailed_screen.dart';
import 'package:freedom/feature/History/widgets/ride_enum_tab.dart';
import 'package:freedom/feature/home/view/widgets.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late TabController tabController;
  RideTabEnum rideTabEnum = RideTabEnum.logistics;
  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            padding: const EdgeInsets.symmetric(horizontal: 27),
            decoration: const BoxDecoration(color: Colors.white),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Completed Ride',
                  style: GoogleFonts.poppins(
                    fontSize: 14.59,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 5,
            color: const Color(0x1ED9D9D9),
          ),
          const VSpace(30),
          RideTab(
            rideTabEnum: rideTabEnum,
            onPressLogistics: () {
              setState(() {
                rideTabEnum = RideTabEnum.logistics;
              });
            },
            onPressRider: () {
              setState(() {
                rideTabEnum = RideTabEnum.rider;
              });
            },
          ),
          Container(
            width: double.infinity,
            height: 5,
            color: const Color(0x1ED9D9D9),
          ),
          if (rideTabEnum == RideTabEnum.logistics)
            const MotorCycleTab()
          else
            const MotorCycleTab(),
        ],
      ),
    );
  }
}

class MotorCycleTab extends StatelessWidget {
  const MotorCycleTab({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: historyList.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute<dynamic>(
                builder: (context) => const HistoryDetailedScreen(),
              )),
          child: Container(
            width: 361,
            padding: const EdgeInsets.only(left: 13, right: 17),
            margin: const EdgeInsets.only(left: 20, right: 12, top: 10),
            decoration: ShapeDecoration(
              color: const Color(0xFFFCFCFC),
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  strokeAlign: BorderSide.strokeAlignOutside,
                  color: Color(0xFFF5F5F5),
                ),
                borderRadius: BorderRadius.circular(14.32),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image(
                            image: AssetImage(
                              historyList[index].riderImage!,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chale Emma',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  historyList[index].rideId!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const RideType(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<dynamic>(
                              builder: (context) =>
                                  const HistoryDetailedScreen(),
                            ),
                          );
                        },
                        child: const OrderRideAgainButton(),
                      ),
                    ],
                  ),
                  const VSpace(14.5),
                  Row(
                    children: [
                      const RiderTimeLine(
                        destinationDetails: 'Ghana, Kumasi',
                        pickUpDetails: 'Chale, Kumasi',
                      ),
                      const Spacer(),
                      if (historyList[index].rideStatus!)
                        SvgPicture.asset('assets/images/checked_icon.svg'),
                      const HSpace(4),
                      TextButton(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          onPressed: () {},
                          child: Text(
                            historyList[index].rideStatus!
                                ? 'Completed'
                                : 'Cancelled',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: historyList[index].rideStatus!
                                    ? const Color(0xFF0BF535)
                                    : const Color(0xFFF90000)),
                          ))
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RideType extends StatelessWidget {
  const RideType({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 1.85,
        left: 4.48,
        bottom: 1.85,
        right: 4.48,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2.51),
        color: const Color(0xFFE6FFF7),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/green_color_motorcycle.svg',
          ),
          Text(
            'Motorcycle Ride',
            style: GoogleFonts.poppins(
              color: const Color(0xFF0BF535),
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderRideAgainButton extends StatelessWidget {
  const OrderRideAgainButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.only(top: 9, left: 7, bottom: 7.5, right: 7),
      decoration: ShapeDecoration(
        color: const Color(0xFF120B00),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/images/reload_icon.svg'),
          const HSpace(3),
          Text(
            'Order Ride Again',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 10.89,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }
}
