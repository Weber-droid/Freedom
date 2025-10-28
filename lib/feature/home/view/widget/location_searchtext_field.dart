import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:freedom/shared/widgets/custom_dropdown_button.dart';

class LocationSearchTextField extends StatefulWidget {
  const LocationSearchTextField({
    required this.onTap,
    required this.onSearch,
    super.key,
  });

  final VoidCallback onTap;
  final VoidCallback onSearch;

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
      onTap: widget.onSearch,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFFFFFF)),
        ),
        fillColor: const Color(0xfffffaf0),
        filled: true,
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
          child: SvgPicture.asset(
            'assets/images/search_field_icon.svg',
            height: 24,
            width: 24,
          ),
        ),
        hintText: 'Your Destination, Send item',
        hintStyle: GoogleFonts.poppins(
          color: Colors.black.withValues(alpha: 0.34),
          fontSize: 10.89,
          fontWeight: FontWeight.w500,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(top: 10, right: 12, bottom: 9),
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
