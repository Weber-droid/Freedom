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
