import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freedom/feature/home/view/widgets.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:freedom/shared/widgets/stacked_bottom_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

class StackedBottomSheetComponent extends StatefulWidget {
  const StackedBottomSheetComponent({
    required this.onFindRider,
    required this.onServiceSelected,
    super.key,
  });
  final VoidCallback onFindRider;
  final void Function(int) onServiceSelected;

  @override
  State<StackedBottomSheetComponent> createState() =>
      _StackedBottomSheetComponentState();
}

class _StackedBottomSheetComponentState
    extends State<StackedBottomSheetComponent> {
  double _containerHeight = 53;
  double _spacing = 13;
  int trackSelectedIndex = 0;

  final TextEditingController _pickUpLocationController =
      TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final List<TextEditingController> _destinationControllers =
      <TextEditingController>[];
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _itemDestinationController =
      TextEditingController();
  final TextEditingController _itemDestinationHomeNumberController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.49,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.45,
        child: stackedBottomSheet(
          context,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VSpace(17),
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const VSpace(13),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Where would you like to go?',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 10.89,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const VSpace(8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xA3FFFCF8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFEBECEB),
                            ),
                          ),
                          child: LocationSearchTextField(
                            onTap: () {
                              _showCalenderPicker(context);
                            },
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: _spacing,
                        ),
                        Visibility(
                          visible: trackSelectedIndex == 2,
                          child: AnimatedContainer(
                            height: _containerHeight,
                            duration: const Duration(milliseconds: 500),
                            child: InkWell(
                              onTap: () async {
                                if (trackSelectedIndex == 2) {
                                  await showLogisticsBottomSheet(
                                    context,
                                    pickUpController: _pickUpLocationController,
                                    destinationController:
                                        _destinationController,
                                    houseNumberController:
                                        _houseNumberController,
                                    phoneNumberController:
                                        _phoneNumberController,
                                    itemDestinationController:
                                        _itemDestinationController,
                                    itemDestinationHomeNumberController:
                                        _itemDestinationHomeNumberController,
                                  );
                                }
                              },
                              child: const LogisticsDetailContainer(),
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: trackSelectedIndex == 2 ? 4.0 : 6.0,
                        ),
                        Text(
                          'Select what you want?',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 10.89,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const VSpace(10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    trackSelectedIndex =
                                        (trackSelectedIndex == 1) ? 1 : 1;
                                    _containerHeight = trackSelectedIndex == 1
                                        ? 0
                                        : _containerHeight;
                                    _spacing =
                                        trackSelectedIndex == 1 ? 4.0 : 13.0;
                                  });
                                  if (trackSelectedIndex == 1) {
                                    await showMotorCycleBottomSheet(
                                      context,
                                      destinationController:
                                          _destinationController,
                                      pickUpLocationController:
                                          _pickUpLocationController,
                                      destinationControllers:
                                          _destinationControllers,
                                    );
                                  }
                                },
                                child: ChooseServiceBox(
                                  isSelected: trackSelectedIndex == 1,
                                  child: const Padding(
                                    padding: EdgeInsets.only(
                                      top: 7,
                                      left: 7,
                                      bottom: 12,
                                    ),
                                    child: ChooseServiceTextDetailsUi2(),
                                  ),
                                ),
                              ),
                            ),
                            const HSpace(20),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    trackSelectedIndex =
                                        (trackSelectedIndex == 2) ? 0 : 2;
                                    _containerHeight =
                                        trackSelectedIndex == 2 ? 53.0 : 0;
                                    _spacing =
                                        trackSelectedIndex == 2 ? 13 : 4.0;
                                  });
                                  // Call the onServiceSelected callback
                                  widget.onServiceSelected(trackSelectedIndex);
                                },
                                child: ChooseServiceBox(
                                  isSelected: trackSelectedIndex == 2,
                                  child: const Padding(
                                    padding: EdgeInsets.only(
                                      top: 7,
                                      left: 7,
                                      bottom: 12,
                                    ),
                                    child: ChooseServiceTextDetailsUi(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const VSpace(13),
                        const ChoosePayMentMethod(),
                        const VSpace(14),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: FreedomButton(
                            onPressed: widget.onFindRider,
                            title: 'Find Rider',
                            buttonTitle: Text(
                              'Find Rider',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            useGradient: true,
                            gradient: gradient,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCalenderPicker(BuildContext context) async {
    if (Platform.isAndroid) {
      await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );
    } else {
      showCuperTinoDialog(
        context,
        child: CupertinoDatePicker(
          initialDateTime: DateTime.now(),
          mode: CupertinoDatePickerMode.date,
          use24hFormat: true,
          showDayOfWeek: true,
          onDateTimeChanged: (DateTime newDate) {
            // setState(());
          },
        ),
      );
    }
  }
}
