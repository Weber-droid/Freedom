// import 'package:equatable/equatable.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:freedom/shared/enums/enums.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:permission_handler/permission_handler.dart';

// part 'location_state.dart';

// class LocationCubit extends Cubit<LocationState> {
//   LocationCubit()
//       : super(
//           const LocationState(
//             currentLocation: LocationState.defaultInitialPosition,
//           ),
//         );

//   Future<void> getCurrentLocation() async {
//     emit(state.copyWith(serviceStatus: LocationServiceStatus.loading));

//     try {
//       final serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         emit(
//           state.copyWith(
//             serviceStatus: LocationServiceStatus.serviceDisabled,
//             errorMessage: 'Location services are disabled',
//           ),
//         );
//         return;
//       }

//       final permissionStatus = await Permission.location.request();

//       if (!permissionStatus.isGranted) {
//         emit(
//           state.copyWith(
//             serviceStatus: LocationServiceStatus.permissionDenied,
//             errorMessage: 'Location permissions are required',
//           ),
//         );
//         return;
//       }

//       final position = await Geolocator.getCurrentPosition(
//         locationSettings:
//             const LocationSettings(accuracy: LocationAccuracy.high),
//       );

//       final currentLocation = LatLng(position.latitude, position.longitude);
//       emit(
//         state.copyWith(
//           currentLocation: currentLocation,
//           serviceStatus: LocationServiceStatus.located,
//         ),
//       );
//     } catch (e) {
//       emit(
//         state.copyWith(
//           serviceStatus: LocationServiceStatus.error,
//           errorMessage: 'Unable to retrieve location: ${e.toString()}',
//         ),
//       );
//     }
//   }

//   Future<void> getUserAddressFromLatLng(LatLng? latLng) async {
//     try {
//       double latitude;
//       double longitude;

//       if (latLng != null) {
//         latitude = latLng.latitude;
//         longitude = latLng.longitude;
//       } else {
//         latitude = 6.6667;
//         longitude = -1.616;
//       }

//       final placeMarks = await placemarkFromCoordinates(latitude, longitude);

//       final country = placeMarks.first.country ?? '';
//       final subLocality = placeMarks.first.subLocality ?? '';
//       final thoroughfare = placeMarks.first.thoroughfare ?? '';
//       final locality = placeMarks.first.locality ?? '';

//       final formattedAddress = [
//         thoroughfare,
//         subLocality,
//         locality,
//         country,
//       ].where((element) => element.isNotEmpty).join(', ');

//       emit(state.copyWith(userAddress: formattedAddress));
//     } catch (e) {
//       emit(state.copyWith(errorMessage: 'Failed to get user address: $e'));
//     }
//   }

//   Future<void> checkPermissionStatus({bool requestPermissions = false}) async {
//     try {
//       final permissionStatus = await Permission.location.status;

//       if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
//         emit(
//           state.copyWith(
//             serviceStatus: LocationServiceStatus.permissionDenied,
//             errorMessage:
//                 'Location permissions are required for accurate location',
//           ),
//         );

//         await getUserAddressFromLatLng(LocationState.defaultInitialPosition);

//         if (requestPermissions && permissionStatus.isDenied) {
//           final requestResult = await Permission.location.request();
//           if (requestResult.isGranted) {
//             await getCurrentLocation();
//             await getUserAddressFromLatLng(state.currentLocation);
//           }
//         }
//       } else if (permissionStatus.isGranted) {
//         final serviceEnabled = await Geolocator.isLocationServiceEnabled();
//         if (!serviceEnabled) {
//           emit(
//             state.copyWith(
//               serviceStatus: LocationServiceStatus.serviceDisabled,
//               errorMessage: 'Location services are disabled',
//             ),
//           );
//           await getUserAddressFromLatLng(LocationState.defaultInitialPosition);
//           return;
//         }

//         await getCurrentLocation();
//         await getUserAddressFromLatLng(state.currentLocation);

//         emit(
//           state.copyWith(
//             serviceStatus: LocationServiceStatus.permissionGranted,
//             errorMessage: '',
//           ),
//         );
//       }
//     } catch (e) {
//       emit(
//         state.copyWith(
//           errorMessage: 'Error checking location permissions: $e',
//         ),
//       );
//       await getUserAddressFromLatLng(LocationState.defaultInitialPosition);
//     }
//   }
// }
