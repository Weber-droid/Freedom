import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/home/models/home_history_model.dart';
import 'package:freedom/feature/home/view/welcome_screen.dart';
import 'package:freedom/feature/home/view/widgets.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const LatLng sanFrancisco = LatLng(37.774546, -122.433523);
  final TextEditingController _pickUpLocationController =
      TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final List<TextEditingController> _destinationControllers =
      <TextEditingController>[];

  String defaultValue = 'Now';
  List<String> dropdownItems = ['Now', 'Later'];

  bool isFirstSelected = false;
  bool isSecondSelected = false;
  int trackSelectedIndex = 0;
  double _containerOpacity = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(),
      ),
      body: BlocConsumer<HomeCubit, HomeState>(
        listener: (context, state) => print(state.locations),
        builder: (context, state) {
          return Stack(
            children: [
              const GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: sanFrancisco,
                  zoom: 13,
                ),
              ),
              Positioned(
                top: 90,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 21),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        icon: SvgPicture.asset('assets/images/menu_icon.svg'),
                      ),
                      const HSpace(28.91),
                      Container(
                        width: 206,
                        padding:
                            const EdgeInsets.only(top: 5, left: 5, bottom: 5),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              strokeAlign: BorderSide.strokeAlignOutside,
                              color: Color(0x23B0B0B0),
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset('assets/images/map_user.svg'),
                            const HSpace(5),
                            SvgPicture.asset(
                                'assets/images/map_location_icon.svg'),
                            const HSpace(6),
                            Flexible(
                              child: Text(
                                'Kumasi ,Ghana Kuwama',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 10.89,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const HSpace(27),
                      Container(
                        width: 47,
                        height: 47,
                        padding: const EdgeInsets.fromLTRB(12, 13, 12, 10),
                        decoration: const ShapeDecoration(
                          color: Color(0xFFEBECEB),
                          shape: OvalBorder(
                            side: BorderSide(
                              strokeAlign: BorderSide.strokeAlignOutside,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        child:
                            SvgPicture.asset('assets/images/user_position.svg'),
                      ),
                    ],
                  ),
                ),
              ),
              stackedBottomSheet(
                context,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 21),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VSpace(17),
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const VSpace(13),
                      Text(
                        'Where would you like to go?',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 10.89,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const VSpace(8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xA3FFFCF8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFEBECEB),
                          ),
                        ),
                        child: LocationSearchTextField(
                          onTap: () {
                            _showCalenderPicker(context);
                          },
                        ),
                      ),
                      const VSpace(13),
                      AnimatedOpacity(
                        opacity: _containerOpacity,
                        duration: const Duration(milliseconds: 500),
                        child: InkWell(
                          onTap: () {},
                          child: const LogisticsDetailContainer(),
                        ),
                      ),
                      const VSpace(6),
                      Text(
                        'Select what you want?',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 10.89,
                          fontWeight: FontWeight.w600,
                          height: 0,
                        ),
                      ),
                      const VSpace(10),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              setState(() {
                                trackSelectedIndex =
                                    (trackSelectedIndex == 1) ? 0 : 1;
                              });
                              if (trackSelectedIndex == 1) {
                                await _showMotorCycleBottomSheet(
                                  context,
                                  destinationController: _destinationController,
                                  pickUpLocationController:
                                      _pickUpLocationController,
                                  destinationControllers:
                                      _destinationControllers,
                                );
                              }
                            },
                            child: ChooseServiceBox(
                              isSelected: trackSelectedIndex == 1,
                              child: const Padding(
                                padding: EdgeInsets.only(
                                  top: 7,
                                  left: 7,
                                  bottom: 12,
                                ),
                                child: ChooseServiceTextDetailsUi2(),
                              ),
                            ),
                          ),
                          const HSpace(10),
                          GestureDetector(
                            onTap: () async {
                              setState(() {
                                trackSelectedIndex =
                                    (trackSelectedIndex == 2) ? 0 : 2;
                                _containerOpacity =
                                    trackSelectedIndex == 2 ? 1 : 0;
                              });
                              if (trackSelectedIndex == 2) {
                                await _showLogisticsBottomSheet(
                                  context,
                                );
                              }
                            },
                            child: ChooseServiceBox(
                              isSelected: trackSelectedIndex == 2,
                              child: const Padding(
                                padding: EdgeInsets.only(
                                  top: 7,
                                  left: 7,
                                  bottom: 12,
                                ),
                                child: ChooseServiceTextDetailsUi(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const VSpace(13),
                      const ChoosePayMentMethod(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCalenderPicker(BuildContext context) async {
    if (Platform.isAndroid) {
      final selectedDate = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );
    } else {
      _showCuperTinoDialog(
        context,
        child: CupertinoDatePicker(
          initialDateTime: DateTime.now(),
          mode: CupertinoDatePickerMode.date,
          use24hFormat: true,
          showDayOfWeek: true,
          onDateTimeChanged: (DateTime newDate) {
            // setState(());
          },
        ),
      );
    }
  }
}

class LogisticsDetailContainer extends StatelessWidget {
  const LogisticsDetailContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 53,
      padding: const EdgeInsets.only(left: 15, right: 13),
      width: double.infinity,
      decoration: BoxDecoration(
        color: fillColor2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white,
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/logistics_filter_icon.svg',
          ),
          const HSpace(8),
          Text(
            'Delivery Details',
            style: GoogleFonts.poppins(
              color: hintTextColor,
              fontSize: 10.89,
              fontWeight: FontWeight.w500,
              height: 0,
            ),
          ),
          const Spacer(),
          SvgPicture.asset(
            'assets/images/right-triangle_icon.svg',
          )
        ],
      ),
    );
  }
}

int trackSelectedIndex = 0;
bool _isDestinationFieldVisible = false;

Future<void> _showMotorCycleBottomSheet(
  BuildContext context, {
  required TextEditingController destinationController,
  required TextEditingController pickUpLocationController,
  required List<TextEditingController> destinationControllers,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.only(top: 18),
            decoration: BoxDecoration(
              gradient: whiteAmberGradient,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(right: 11, bottom: 11),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            strokeAlign: BorderSide.strokeAlignOutside,
                            color: Colors.black.withOpacity(0.059),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const HSpace(6.4),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                    left: 12, bottom: 4.62, top: 6.38),
                                child: Text(
                                  'Pickup Location',
                                  style: TextStyle(
                                    fontSize: 10.13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          PickupLocationFieldWidget(
                            state: state,
                            pickupController: pickUpLocationController,
                            hintText: 'Pickup Location',
                            iconPath: 'assets/images/location_pointer_icon.svg',
                            iconBaseColor: Colors.orange,
                            isPickUpLocation: true,
                            isInitialDestinationField: false,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(
                                  left: 12,
                                ),
                                child: Text(
                                  'Destination',
                                  style: TextStyle(
                                    fontSize: 10.13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  right: 9,
                                  bottom: 1,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    destinationControllers.add(
                                      TextEditingController(),
                                    );
                                    context.read<HomeCubit>().addDestination();
                                    _isDestinationFieldVisible = true;
                                  },
                                  child: Container(
                                    width: 23,
                                    height: 23,
                                    decoration: ShapeDecoration(
                                      color: Colors.black,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(7)),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const VSpace(3),
                          DestinationLocationFieldWidget(
                            isPickUpLocation: false,
                            isInitialDestinationField: true,
                            state: state,
                            destinationController: destinationController,
                            hintText: 'Destination',
                            iconPath: 'assets/images/maps_icon.svg',
                            iconBaseColor: Colors.red,
                          ),
                          const VSpace(14),
                          if (_isDestinationFieldVisible)
                            Column(
                              children: List.generate(state.locations.length,
                                  (index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: DestinationLocationFieldWidget(
                                    isPickUpLocation: false,
                                    isInitialDestinationField: false,
                                    state: state,
                                    destinationController:
                                        destinationControllers[index],
                                    hintText: 'Destination ${index + 1}',
                                    iconPath: 'assets/images/maps_icon.svg',
                                    iconBaseColor: Colors.red,
                                  ),
                                );
                              }),
                            )
                          else
                            const SizedBox(),
                        ],
                      ),
                    ),
                    const VSpace(19.65),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your last Trip',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 11.68,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SvgPicture.asset('assets/images/history_icon.svg'),
                      ],
                    ),
                    ...homeHistoryList.map((e) {
                      return Column(
                        children: [
                          Divider(
                            thickness: 2,
                            color: Colors.black.withOpacity(0.019),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                width: 30,
                                height: 30,
                                decoration: ShapeDecoration(
                                  color: Colors.white.withOpacity(0.55),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      strokeAlign:
                                          BorderSide.strokeAlignOutside,
                                      color: Colors.black.withOpacity(0.05),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: e.image,
                              ),
                              SvgPicture.asset(
                                  'assets/images/top-right_icon.svg')
                            ],
                          ),
                        ],
                      );
                    }),
                    Divider(
                      thickness: 2,
                      color: Colors.black.withOpacity(0.019),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _showLogisticsBottomSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(gradient: whiteAmberGradient),
      );
    },
  );
}

class ChooseServiceTextDetailsUi2 extends StatelessWidget {
  const ChooseServiceTextDetailsUi2({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'assets/images/choose_bike.svg',
        ),
        const VSpace(9),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [gradient1, gradient2],
          ).createShader(
            Rect.fromLTWH(
              0,
              0,
              bounds.width,
              bounds.height,
            ),
          ),
          child: Text(
            'Motorcycle',
            style: GoogleFonts.poppins(
              fontSize: 10.89,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const VSpace(4),
        Text(
          'Ride with your favourite Motorcycle',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 10.89,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

class ChooseServiceTextDetailsUi extends StatelessWidget {
  const ChooseServiceTextDetailsUi({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'assets/images/choose_logistics.svg',
        ),
        const VSpace(9),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [gradient1, gradient2],
          ).createShader(
            Rect.fromLTWH(
              0,
              0,
              bounds.width,
              bounds.height,
            ),
          ),
          child: Text(
            'Logistic',
            style: GoogleFonts.poppins(
              fontSize: 10.89,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const VSpace(4),
        Text(
          'Ride with your favorite logistics',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 10.89,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

class ChooseServiceBox extends StatelessWidget {
  const ChooseServiceBox({super.key, this.isSelected = false, this.child});
  final bool isSelected;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        border: isSelected
            ? GradientBoxBorder(gradient: redLinearGradient)
            : Border.all(
                color: const Color(0xFFfeebca),
              ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

void _showCuperTinoDialog(BuildContext context, {required Widget child}) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (context) {
      return Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: child,
        ),
      );
    },
  );
}
