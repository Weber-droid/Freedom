import 'package:flutter/material.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';

class ChooseServiceTextDetailsUi2 extends StatelessWidget {
  const ChooseServiceTextDetailsUi2({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 27,
          width: 27,
          child: SvgPicture.asset('assets/images/choose_bike.svg'),
        ),
        const VSpace(9),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback:
              (bounds) => LinearGradient(
                colors: [gradient1, gradient2],
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: Text(
            'Okada (motor)',
            style: GoogleFonts.poppins(
              fontSize: 10.89,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const VSpace(4),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: Text(
            'Ride with your favourite Motorcycle',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 10.89,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    );
  }
}

class ChooseServiceTextDetailsUi extends StatelessWidget {
  const ChooseServiceTextDetailsUi({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 27,
          width: 27,
          child: SvgPicture.asset('assets/images/choose_logistics.svg'),
        ),
        const VSpace(9),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback:
              (bounds) => LinearGradient(
                colors: [gradient1, gradient2],
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: Text(
            'Delivery',
            style: GoogleFonts.poppins(
              fontSize: 10.89,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const VSpace(4),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: Text(
            'Deliver your goods and services nationwide',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 9.78,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    );
  }
}
