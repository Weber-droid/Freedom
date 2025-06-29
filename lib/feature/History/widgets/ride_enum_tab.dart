import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:freedom/feature/History/enums.dart';

class RideTab extends StatelessWidget {
  const RideTab({
    required this.rideTabEnum,
    required this.onPressLogistics,
    required this.onPressRider,
    super.key,
  });

  final RideTabEnum rideTabEnum;
  final void Function() onPressLogistics;
  final void Function() onPressRider;

  @override
  Widget build(BuildContext context) {
    log('rideTabEnum: $rideTabEnum');
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPressLogistics,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
              decoration: BoxDecoration(
                color: rideTabEnum == RideTabEnum.logistics
                    ? const Color(0xFFFBC976)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFBC976),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/delivery_cart.svg',
                    colorFilter: ColorFilter.mode(
                        rideTabEnum == RideTabEnum.logistics
                            ? Colors.white
                            : const Color(0xFFFBC976),
                        BlendMode.srcIn),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Logistics',
                    style: TextStyle(
                      color: rideTabEnum == RideTabEnum.logistics
                          ? Colors.white
                          : const Color(0xFFFBC976),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onPressRider,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
              decoration: BoxDecoration(
                  color: rideTabEnum == RideTabEnum.rider
                      ? const Color(0xFFFBC976)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFBC976),
                    width: 2,
                  )),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/motorcycle_outline.svg',
                    colorFilter: ColorFilter.mode(
                        rideTabEnum == RideTabEnum.rider
                            ? Colors.white
                            : const Color(0xFFFBC976),
                        BlendMode.srcIn),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Motorcycle Ride',
                    style: TextStyle(
                      color: rideTabEnum == RideTabEnum.rider
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
