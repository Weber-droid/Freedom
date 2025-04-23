import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeHistoryModel {
  HomeHistoryModel({
    required this.image,
    required this.destinationName,
    required this.destinationLocation,
  });
  final Widget image;
  final String destinationName;
  final LatLng destinationLocation;
}

List<HomeHistoryModel> homeHistoryList = [
  HomeHistoryModel(
    image: SvgPicture.asset(
      'assets/images/maps_icon.svg',
      colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn),
    ),
    destinationName: 'New York',
    destinationLocation: const LatLng(40.7128, -74.0060),
  ),
  HomeHistoryModel(
    image: SvgPicture.asset(
      'assets/images/maps_icon.svg',
      colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn),
    ),
    destinationName: 'London',
    destinationLocation: const LatLng(51.5074, -0.1278),
  ),
  HomeHistoryModel(
    image: SvgPicture.asset(
      'assets/images/maps_icon.svg',
      colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn),
    ),
    destinationName: 'Paris',
    destinationLocation: const LatLng(48.8566, 2.3522),
  ),
  HomeHistoryModel(
    image: SvgPicture.asset(
      'assets/images/maps_icon.svg',
      colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn),
    ),
    destinationName: 'Tokyo',
    destinationLocation: const LatLng(35.6895, 139.6917),
  ),
  HomeHistoryModel(
    image: SvgPicture.asset(
      'assets/images/maps_icon.svg',
      colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn),
    ),
    destinationName: 'Sydney',
    destinationLocation: const LatLng(-33.8688, 151.2093),
  ),
  HomeHistoryModel(
    image: SvgPicture.asset(
      'assets/images/maps_icon.svg',
      colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn),
    ),
    destinationName: 'Dubai',
    destinationLocation: const LatLng(25.2048, 55.2708),
  ),
];
