import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomDropDown extends StatefulWidget {
  const CustomDropDown({
    required this.items,
    required this.initialValue,
    required this.onChanged,
    super.key,
  });
  final List<String> items;
  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<CustomDropDown> createState() => _CustomDropDownState();
}

class _CustomDropDownState extends State<CustomDropDown> {
  late String selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  Future<void> _showDropdownMenu(BuildContext context) async {
    final renderBox = context.findRenderObject()! as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + renderBox.size.height,
        offset.dx + renderBox.size.width,
        0,
      ),
      items: widget.items.map((item) {
        return PopupMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.poppins(
              fontSize: 10.89,
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      }).toList(),
    );

    if (result != null && result != selectedValue) {
      setState(() {
        selectedValue = result;
      });
      widget.onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDropdownMenu(context),
      child: Container(
        width: 83,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              strokeAlign: BorderSide.strokeAlignOutside,
              color: Colors.black.withOpacity(0.03),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset('assets/images/scheduler_icon.svg'),
            Text(
              selectedValue,
              style: GoogleFonts.poppins(
                color: Colors.black.withOpacity(0.35),
                fontSize: 10.89,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Image(
              image: AssetImage('assets/images/down_arrow.png'),
            ),
          ],
        ),
      ),
    );
  }
}
