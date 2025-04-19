import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/feature/home/audio_call_cubit/call_cubit.dart';
import 'package:freedom/feature/home/location_cubit/location_cubit.dart';
import 'package:freedom/feature/home/view/widgets.dart';
import 'package:freedom/feature/home/widgets/custom_drawer.dart';
import 'package:freedom/feature/home/widgets/stacked_bottom_sheet_component.dart';
import 'package:freedom/feature/profile/cubit/profile_cubit.dart';
import 'package:freedom/shared/enums/enums.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late GoogleMapController _mapController;

  String defaultValue = 'Now';
  List<String> dropdownItems = ['Now', 'Later'];

  bool isFirstSelected = false;
  bool isSecondSelected = false;
  int trackSelectedIndex = 0;

  bool hideStackedBottomSheet = false;

  @override
  void initState() {
    super.initState();
    context.read<LocationCubit>().checkPermissionStatus();
    context.read<ProfileCubit>().getUserProfile();
    context
        .read<CallCubit>()
        .initialize(userId: 'MWCHb02GD5m6', userName: 'USER1');
  }



  // void _showPhoneVerificationDialog() {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (BuildContext context) {
  //       return Dialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(20),
  //         ),
  //         insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
  //
  //         child: Container(
  //           decoration: BoxDecoration(
  //             gradient: const LinearGradient(
  //               colors: [Color(0xFFFFF2DD), Color(0xFFFCFCFC)],
  //               begin: Alignment.topCenter,
  //               end: Alignment.bottomCenter,
  //             ),
  //             borderRadius: BorderRadius.circular(20),
  //           ),
  //           padding: const EdgeInsets.all(20),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               // Phone icon in circular container with gradient
  //               Container(
  //                 width: 80,
  //                 height: 80,
  //                 decoration:  BoxDecoration(
  //                     shape: BoxShape.circle,
  //                     gradient: redLinearGradient
  //                 ),
  //                 child: const Icon(
  //                   Icons.phone,
  //                   color: Colors.white,
  //                   size: 40,
  //                 ),
  //               ),
  //               const SizedBox(height: 20),
  //               Text(
  //                 'Please verify your phone number',
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //                 textAlign: TextAlign.center,
  //               ),
  //               const SizedBox(height: 15),
  //               Text(
  //                 'Your phone number needs to be verified before you can use the app.',
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 14,
  //                   color: Colors.grey[700],
  //                 ),
  //                 textAlign: TextAlign.center,
  //               ),
  //               const SizedBox(height: 25),
  //               // Verify button with the same gradient as in StackedBottomSheet
  //               Container(
  //                 width: double.infinity,
  //                 height: 50,
  //                 decoration: BoxDecoration(
  //                     borderRadius: BorderRadius.circular(10),
  //                     gradient:redLinearGradient
  //                 ),
  //                 child: ElevatedButton(
  //                   onPressed: () {
  //                     Navigator.of(context).pop();
  //                     Navigator.pushNamed(context, PhoneNumberScreen.routeName);
  //                   },
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: Colors.transparent,
  //                     shadowColor: Colors.transparent,
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                   ),
  //                   child: Text(
  //                     'Verify Now',
  //                     style: GoogleFonts.poppins(
  //                       color: Colors.white,
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //               const SizedBox(height: 15),
  //               // Maybe Later button
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                   // Show again in a short while
  //                   Future.delayed(const Duration(minutes: 5), () {
  //                     if (mounted) {
  //                       _showPhoneVerificationDialog();
  //                     }
  //                   });
  //                 },
  //                 child: Text(
  //                   'Maybe Later',
  //                   style: GoogleFonts.poppins(
  //                     color: Colors.grey[800],
  //                     fontSize: 14,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      body: BlocConsumer<LocationCubit, LocationState>(
        listener: (context, state) {
          if (state.serviceStatus == LocationServiceStatus.located &&
              state.currentLocation != null) {
            _mapController.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: state.currentLocation!,
                  zoom: 15.5,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final Widget mapWidget = GoogleMap(
            initialCameraPosition: LocationState.initialCameraPosition,
            myLocationEnabled:
            state.serviceStatus == LocationServiceStatus.located,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          );

          return Stack(
            children: [
              mapWidget,
              UserFloatingAccessBar(scaffoldKey: _scaffoldKey, state: state),
              Visibility(
                visible: !hideStackedBottomSheet,
                child: StackedBottomSheetComponent(
                  onFindRider: () {
                    setState(() {
                      hideStackedBottomSheet = true;
                    });
                    _showRiderFoundBottomSheet(context).then((_) {
                      setState(() {
                        hideStackedBottomSheet = false;
                      });
                    });
                  },
                  onServiceSelected: (int index) {},
                ),
              ),
            ],
          );
        },
      ),
    );
  }


  Future<void> _showRiderFoundBottomSheet(BuildContext context) async {
    await showModalBottomSheet<dynamic>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const RiderFoundBottomSheet();
      },
    );
  }
}