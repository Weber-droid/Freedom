import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/core/services/map_services.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/home/audio_call_cubit/call_cubit.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
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

  String defaultValue = 'Now';
  List<String> dropdownItems = ['Now', 'Later'];

  bool isFirstSelected = false;
  bool isSecondSelected = false;
  int trackSelectedIndex = 0;

  bool hideStackedBottomSheet = false;

  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().checkPermissionStatus();
    context.read<ProfileCubit>().getUserProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initCallCubit();
    });
  }

  Future<void> initCallCubit() async {
    final user = await RegisterLocalDataSource().getUser();
    log('user: ${user!.token}');
    if (mounted) {
      await context
          .read<CallCubit>()
          .initialize(userId: user.id!, userName: user.firstName!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      body: BlocConsumer<HomeCubit, HomeState>(
        listener: (context, state) {
          final mapServices = getIt<MapService>();
          if (state.serviceStatus == LocationServiceStatus.located &&
              state.currentLocation != null) {
            mapServices.controller?.animateCamera(
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
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: HomeState.initialCameraPosition,
                myLocationEnabled:
                    state.serviceStatus == LocationServiceStatus.located,
                compassEnabled: false,
                mapToolbarEnabled: false,
                markers: context.select((HomeCubit c) => c.state.markers),
                onMapCreated: (GoogleMapController controller) {
                  getIt.registerSingleton<GoogleMapController>(controller);
                  getIt<MapService>().setController(controller);
                },
              ),
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
