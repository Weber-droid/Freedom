import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:google_fonts/google_fonts.dart';

class FreedomButton extends StatelessWidget {
  final BorderRadiusGeometry? borderRadius;
  final double? width;
  final double height;
  final Gradient gradient;
  final VoidCallback? onPressed;
  final String title;
  final bool useGradient;
  final String leadingIcon;
  final IconData? icon;
  final Color? backGroundColor;
  final Color? titleColor;
  final double? fontSize;
  final bool? useLoader;
  final Widget? child;

  const FreedomButton({
    Key? key,
    required this.onPressed,
    this.borderRadius,
    this.width,
    this.height = 57.0,
    this.title = '',
    this.useGradient = false,
    this.gradient = const LinearGradient(colors: [Colors.cyan, Colors.indigo]),
    this.leadingIcon = '',
    this.icon,
    this.backGroundColor,
    this.titleColor,
    this.fontSize,
    this.useLoader,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderRadius = this.borderRadius ?? BorderRadius.circular(13);
    return Container(
      width: width,
      height: height,
      decoration: useGradient == true
          ? BoxDecoration(
              gradient: gradient,
              borderRadius: borderRadius,
            )
          : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              useGradient == true ? Colors.transparent : backGroundColor,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
        child: useLoader == null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingIcon.isNotEmpty)
                    SvgPicture.asset('assets/images/$leadingIcon.svg')
                  else
                    Icon(
                      icon,
                      color: Colors.white,
                    ),
                  const HSpace(6),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: fontSize ?? 17.41.sp,
                      color: titleColor ?? Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: fontSize ?? 17.41.sp,
                      color: titleColor ?? Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const HSpace(6),
                  SizedBox(height: 20, width: 20, child: child)
                ],
              ),
      ),
    );
  }
}
