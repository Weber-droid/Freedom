import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/feature/home/location_cubit/location_cubit.dart';
import 'package:freedom/shared/enums/enums.dart';
import 'package:permission_handler/permission_handler.dart';

// class PermissionResetButton extends StatelessWidget {
//   final VoidCallback? onPermissionReset;
//
//   const PermissionResetButton({
//     Key? key,
//     this.onPermissionReset,
//   }) : super(key: key);
//
//   Future<void> resetLocationPermissions(BuildContext context) async {
//     try {
//       // Revoke location permissions
//       await Permission.location.revoke();
//       await Permission.locationAlways.revoke();
//       await Permission.locationWhenInUse.revoke();
//
//       // Reset the location cubit state
//       context.read<LocationCubit>().resetLocationState();
//
//       // Optional: Show a confirmation dialog
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Location permissions have been reset'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//
//       // Call any additional reset callback
//       onPermissionReset?.call();
//     } catch (e) {
//       // Handle any errors during permission reset
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error resetting permissions: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: () => resetLocationPermissions(context),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.red.shade400,
//         foregroundColor: Colors.white,
//       ),
//       child: const Text('Reset Location Permissions'),
//     );
//   }
// }
//
// // Update your LocationCubit to include a reset method
// extension on LocationCubit {
//   void resetLocationState() {
//     emit(LocationState(
//       currentLocation: LocationState.defaultInitialPosition,
//       serviceStatus: LocationServiceStatus.initial,
//     ));
//   }
// }
