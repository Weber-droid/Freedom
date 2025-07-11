import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/home/view/widgets.dart';
import 'package:freedom/shared/responsive_helpers.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:google_fonts/google_fonts.dart';

class RiderFoundBottomSheet<T extends StateStreamable<S>, S>
    extends StatelessWidget {
  const RiderFoundBottomSheet({
    super.key,
    required this.isMultiDestinationSelector,
    required this.stateBuilder,
    required this.onCancelPressed,
    this.timerText = 'The rider will arrive in ....',
    this.timerValue = '08:12 Mins',
    this.cancelButtonText = 'Cancel Ride',
  });

  final bool Function(S state) isMultiDestinationSelector;
  final Widget Function(BuildContext context, S state, bool isMuliStop)
  stateBuilder;
  final VoidCallback onCancelPressed;
  final String timerText;
  final String timerValue;
  final String cancelButtonText;

  @override
  Widget build(BuildContext context) {
    final isMuliStop = context.select<T, bool>(
      (cubit) => isMultiDestinationSelector(cubit.state),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final baseHeight = getBaseHeight(constraints);
        final horizontalPadding = getHorizontalPadding(constraints);
        final borderRadius = isTablet ? 24.0 : 20.0;

        return Container(
          width: constraints.maxWidth,
          constraints: BoxConstraints(
            maxHeight: constraints.maxHeight * 0.85,
            minHeight: getMinHeight(constraints),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: baseHeight,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(borderRadius),
                    topRight: Radius.circular(borderRadius),
                  ),
                ),
              ),
              Positioned(
                top: getContentTopOffset(constraints),
                left: 0,
                right: 0,
                child: Container(
                  height: baseHeight - getContentTopOffset(constraints),
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    gradient: whiteAmberGradient,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      topRight: Radius.circular(borderRadius),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: getSpacing(constraints, 13)),

                        Container(
                          height: 5,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),

                        SizedBox(height: getSpacing(constraints, 15)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: const RiderContainerAndRideActions(),
                        ),

                        SizedBox(height: getSpacing(constraints, 14)),

                        // Route container
                        Container(
                          decoration: BoxDecoration(
                            color: fillColor2,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white),
                          ),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            getSpacing(constraints, 10),
                            horizontalPadding * 0.4,
                            getSpacing(constraints, 17.78),
                          ),
                          margin: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Route',
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: getFontSize(constraints, 11.51),
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                              ),

                              SizedBox(height: getSpacing(constraints, 8)),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: constraints.maxHeight * 0.3,
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: SingleChildScrollView(
                                  child: BlocBuilder<T, S>(
                                    builder: (context, state) {
                                      return stateBuilder(
                                        context,
                                        state,
                                        isMuliStop,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: getSpacing(constraints, 30)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: getButtonHeight(constraints),
                            child: FreedomButton(
                              onPressed: onCancelPressed,
                              useGradient: true,
                              gradient: gradient,
                              title: cancelButtonText,
                              buttonTitle: Text(
                                cancelButtonText,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: getFontSize(constraints, 16),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: getSpacing(constraints, 20)),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: getTimerTopOffset(constraints),
                left: horizontalPadding,
                right: horizontalPadding,
                child: Row(
                  children: [
                    Image(
                      image: const AssetImage(
                        'assets/images/jump-time_icon.png',
                      ),
                      width: getIconSize(constraints, 24),
                      height: getIconSize(constraints, 24),
                    ),
                    SizedBox(width: getSpacing(constraints, 8)),
                    Expanded(
                      child: Text(
                        timerText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: getFontSize(constraints, 14),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: getSpacing(constraints, 8),
                        vertical: getSpacing(constraints, 6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/images/clock_icon.svg',
                            width: getIconSize(constraints, 16),
                            height: getIconSize(constraints, 16),
                          ),
                          SizedBox(width: getSpacing(constraints, 4)),
                          Text(
                            timerValue,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: getFontSize(constraints, 11.76),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
