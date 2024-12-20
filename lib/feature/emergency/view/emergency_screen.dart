import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/emergency/view/emergency_activated.dart';
import 'package:freedom/feature/home/view/widgets.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:google_fonts/google_fonts.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const EmergencyAppBar(),
          const VSpace(32),
          SizedBox(
            width: 378,
            child: Text(
              'Your safety is our top priority',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 14.24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const VSpace(12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Text(
              // ignore: lines_longer_than_80_chars
              'In case of an emergency, tap the  red Panic Button below  to alert our emergency response team and local authorities.',
              style: GoogleFonts.poppins(
                color: Colors.black.withOpacity(0.5),
                fontSize: 14.24,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          const VSpace(125),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: FreedomButton(
              onPressed: () {
                showAlertDialog(
                  context,
                  title: 'Emergency Activation',
                  message:
                      'Confirm that you want to activate the emergency assistance feature.',
                  cancelText: 'Cancel',
                  confirmText: 'Activate Emergency',
                  confirm: () {
                    Navigator.pushNamed(context, EmergencyActivated.routeName);
                  },
                  cancel: () {
                    Navigator.pop(context);
                  },
                );
              },
              title: 'Tap to Activate',
              useGradient: true,
              titleColor: Colors.white,
              borderRadius: BorderRadius.circular(6),
              gradient: gradient,
              width: double.infinity,
            ),
          )
        ],
      ),
    );
  }
}

class EmergencyAppBar extends StatelessWidget {
  const EmergencyAppBar(
      {super.key,
      this.title = 'Emergency Assistance',
      this.gifUrl,
      this.decoratedImageSource,
      this.useNetworkImage = true,
      this.imageSource,
      this.positionRight,
      this.positionLeft,
      this.positionBottom,
      this.titleHorizontalSpace = 70});

  final String title;
  final String? gifUrl;
  final String? decoratedImageSource;
  final bool useNetworkImage;
  final String? imageSource;
  final double? positionRight;
  final double? positionLeft;
  final double? positionBottom;
  final double titleHorizontalSpace;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 266,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                decoratedImageSource ?? 'assets/images/decoration_image.png',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 72,
          right: 0,
          left: 25,
          child: Row(
            children: [
              Container(
                width: 42,
                height: 40,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: Colors.black.withOpacity(0.079),
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              HSpace(titleHorizontalSpace),
              Center(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 120,
          left: positionLeft ?? 116,
          right: positionRight ?? 109,
          bottom: positionBottom ?? 0,
          child: useNetworkImage
              ? Image.network(
                  gifUrl ??
                      'https://s3-alpha-sig.figma.com/img/1d74/2335/075adf1fea030f83898ee3b748ef6968?Expires=1734912000&Key-Pair-Id=APKAQ4GOSFWCVNEHN3O4&Signature=cUFTHuQA7NHc1KtfH0DaZxL~dFPCnQOY00F2ho1I9oSLj~uIWA21NtkzqWAesrJoj2eIUAo3TkaCPsOIEhppgxTTZ0k8VtShax2fLWswPhh8t4YM8ERE-LL-Gn47LKy69xCD3~NLn48i04Clf5odvQXGbCf0uHwHdP1KqzW0L8ReV5-b2DXIzl-xDLmxflP4Atirs9UeL9joVlil9fWkGaZvHnhDWxcLGxVk1Gv-ViLBNDtjqCex8Vpdb2vhSG2gAEWaVZpeNhcdReCZjfR90aE5FwFAhGCyMLB8C94suOeyc1MGs2rFKyc-COv4pl67c6pgXsAE-qwJyOX0N6VHaQ__',
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error);
                  },
                )
              : SvgPicture.asset(imageSource ?? ''),
        )
      ],
    );
  }
}
