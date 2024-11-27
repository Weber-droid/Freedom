import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/custom_dropdown_button.dart';
import 'package:google_fonts/google_fonts.dart';

class ChoosePayMentMethod extends StatefulWidget {
  const ChoosePayMentMethod({
    super.key,
  });

  @override
  State<ChoosePayMentMethod> createState() => ChoosePayMentMethodState();
}

class ChoosePayMentMethodState extends State<ChoosePayMentMethod> {
  String defaultValue = 'Personal Cash';

  final items = <String>[
    'Personal Cash',
    'Personal Card',
    'Company Cash',
    'Company Card',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 359,
      height: 70,
      decoration: ShapeDecoration(
        color: const Color(0xA3FFFCF8),
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            strokeAlign: BorderSide.strokeAlignOutside,
            color: Colors.white,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 49.39,
            height: 47.62,
            padding: const EdgeInsets.only(
              top: 8.98,
              left: 9.88,
              bottom: 9.01,
              right: 9.88,
            ),
            decoration: ShapeDecoration(
              color: const Color(0x38F4950D),
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1.76, color: Colors.white),
                borderRadius: BorderRadius.circular(12.35),
              ),
            ),
            child: SvgPicture.asset('assets/images/pay_with_cash.svg'),
          ),
          const HSpace(8.98),
          DropdownButton<String>(
            elevation: 0,
            underline: const SizedBox(),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black,
            ),
            value: defaultValue,
            items: items.map((e) {
              return DropdownMenuItem(
                value: e,
                child: Text(e, style: GoogleFonts.poppins(color: Colors.black)),
              );
            }).toList(),
            onChanged: (val) {
              log(val.toString());
              if (val != null) {
                setState(() {
                  defaultValue = val;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

Widget stackedBottomSheet(
  BuildContext context,
  Widget child,
) {
  return DraggableScrollableSheet(
    initialChildSize: 0.47,
    minChildSize: 0.47,
    maxChildSize: 0.8,
    builder: (context, scrollController) {
      return SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const ShapeDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF2DD), Color(0xFFFCFCFC)],
            ),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 0.60,
                strokeAlign: BorderSide.strokeAlignOutside,
                color: Colors.white,
              ),
            ),
          ),
          child: child,
        ),
      );
    },
  );
}

class LocationSearchTextField extends StatefulWidget {
  const LocationSearchTextField({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  State<LocationSearchTextField> createState() =>
      _LocationSearchTextFieldState();
}

class _LocationSearchTextFieldState extends State<LocationSearchTextField> {
  String defaultValue = 'Now';
  List<String> dropdownItems = ['Now', 'Later'];

  bool isFirstSelected = false;
  bool isSecondSelected = false;
  int trackSelectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorColor: Colors.black,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFFFFFFF),
          ),
        ),
        fillColor: const Color(0xfffffaf0),
        filled: true,
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.white,
          ),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: 10,
            top: 10,
            bottom: 10,
          ),
          child: SvgPicture.asset(
            'assets/images/search_field_icon.svg',
            height: 24,
            width: 24,
          ),
        ),
        hintText: 'Your Destination, Send item',
        hintStyle: GoogleFonts.poppins(
          color: Colors.black.withOpacity(0.3499999940395355),
          fontSize: 10.89,
          fontWeight: FontWeight.w500,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(
            top: 10,
            right: 12,
            bottom: 9,
          ),
          child: CustomDropDown(
            items: dropdownItems,
            initialValue: defaultValue,
            onChanged: (value) {
              setState(() {
                defaultValue = value;
              });
              if (value == 'Later') {
                widget.onTap();
              }
            },
          ),
        ),
      ),
    );
  }
}
