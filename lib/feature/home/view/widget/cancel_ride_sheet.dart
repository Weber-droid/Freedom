import 'package:flutter/material.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:google_fonts/google_fonts.dart';

class CancelRideSheet extends StatefulWidget {

  const CancelRideSheet({
    super.key,
    required this.onConfirmCancel,
  });
  final void Function(String reason, String? comment) onConfirmCancel;

  @override
  State<CancelRideSheet> createState() => _CancelRideSheetState();
}

class _CancelRideSheetState extends State<CancelRideSheet> {
  final TextEditingController _commentController = TextEditingController();
  String? selectedReason;

  final List<String> cancellationReasons = [
    'Driver is taking too long',
    'Changed my destination',
    'Found another ride',
    'Driver asked to cancel',
    'Ride fare too high',
    'Other reason'
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        width: constraints.maxWidth,
        decoration: BoxDecoration(
          gradient: whiteAmberGradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          )
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VSpace(13),
                Center(
                  child: Container(height: 5, width: 50, color: Colors.white),
                ),
                const VSpace(20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    'Why are you cancelling?',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const VSpace(8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    'Please select a reason',
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const VSpace(20),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: cancellationReasons.map((reason) {
                        final isSelected = selectedReason == reason;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedReason = reason;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.amber.withOpacity(0.2) : fillColor2,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? Colors.amber : Colors.white,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    reason,
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: fillColor2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white),
                    ),
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Additional comments (optional)',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.black38),
                      ),
                    ),
                  ),
                ),
                const VSpace(20),
                FreedomButton(
                  onPressed: selectedReason == null
                      ? null
                      : () {
                    widget.onConfirmCancel(
                      selectedReason!,
                      _commentController.text.isNotEmpty
                          ? _commentController.text
                          : null,
                    );
                  },
                  useGradient: true,
                  gradient: gradient,
                  title: 'Confirm',
                  buttonTitle: Text(
                    'Confirm',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const VSpace(15),
              ],
            ),
          ],
        ),
      );
    });
  }
}