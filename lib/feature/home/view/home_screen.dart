import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/home/view/widgets.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _itemDestinationController =
      TextEditingController();
  final TextEditingController _itemDestinationHomeNumberController =
      TextEditingController();

  String defaultValue = 'Now';
  List<String> dropdownItems = ['Now', 'Later'];

  bool isFirstSelected = false;
  bool isSecondSelected = false;
  int trackSelectedIndex = 0;
  double _containerOpacity = 0;
  double _containerHeight = 100;
  double _spacing = 13;

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
              Positioned(
                top: MediaQuery.of(context).size.height * 0.47,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: stackedBottomSheet(
                    context,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
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
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    height: _spacing,
                                  ),
                                  AnimatedContainer(
                                    height: _containerHeight,
                                    duration: const Duration(milliseconds: 500),
                                    child: InkWell(
                                      onTap: () async {
                                        if (trackSelectedIndex == 2) {
                                          await showLogisticsBottomSheet(
                                            context,
                                            pickUpController:
                                                _pickUpLocationController,
                                            destinationController:
                                                _destinationController,
                                            houseNumberController:
                                                _houseNumberController,
                                            phoneNumberController:
                                                _phoneNumberController,
                                            itemDestinationController:
                                                _itemDestinationController,
                                            itemDestinationHomeNumberController:
                                                _itemDestinationHomeNumberController,
                                          );
                                        }
                                      },
                                      child: const LogisticsDetailContainer(),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    height: trackSelectedIndex == 2 ? 4.0 : 6.0,
                                  ),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          setState(() {
                                            trackSelectedIndex =
                                                (trackSelectedIndex == 1)
                                                    ? 1
                                                    : 1;
                                            _containerHeight =
                                                trackSelectedIndex == 1
                                                    ? 0
                                                    : _containerHeight;
                                            _spacing = trackSelectedIndex == 1
                                                ? 4.0
                                                : 13.0;
                                          });
                                          if (trackSelectedIndex == 1) {
                                            await showMotorCycleBottomSheet(
                                              context,
                                              destinationController:
                                                  _destinationController,
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
                                            child:
                                                ChooseServiceTextDetailsUi2(),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          setState(() {
                                            trackSelectedIndex =
                                                (trackSelectedIndex == 2)
                                                    ? 0
                                                    : 2;
                                            _containerHeight =
                                                trackSelectedIndex == 2
                                                    ? 53.0
                                                    : 0;
                                            _spacing = trackSelectedIndex == 2
                                                ? 13
                                                : 4.0;
                                          });
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
                          )
                        ],
                      ),
                    ),
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
      showCuperTinoDialog(
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
