import 'dart:developer';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/home/delivery_cubit/delivery_cubit.dart';
import 'package:freedom/feature/home/models/delivery_model.dart';
import 'package:freedom/feature/home/repository/models/place_prediction.dart';
import 'package:freedom/feature/home/view/widgets.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:freedom/shared/widgets/text_field_factory.dart';
import 'package:freedom/shared/widgets/toasts.dart';
import 'package:google_fonts/google_fonts.dart';

class LogisticsBottomSheetContent extends StatefulWidget {
  const LogisticsBottomSheetContent({
    required this.pickUpController,
    required this.destinationController,
    required this.houseNumberController,
    required this.phoneNumberController,
    required this.itemDestinationController,
    required this.itemDestinationHomeNumberController,
    super.key,
  });
  final TextEditingController pickUpController;
  final TextEditingController destinationController;
  final TextEditingController houseNumberController;
  final TextEditingController phoneNumberController;
  final TextEditingController itemDestinationController;
  final TextEditingController itemDestinationHomeNumberController;

  @override
  State<LogisticsBottomSheetContent> createState() =>
      _LogisticsBottomSheetContentState();
}

class _LogisticsBottomSheetContentState
    extends State<LogisticsBottomSheetContent>
    with SingleTickerProviderStateMixin {
  final FocusNode _pickUpNode = FocusNode();
  final FocusNode _destinationNode = FocusNode();
  List<FocusNode> _destinationNodes = [];

  // Map to store controller listeners so we can remove them later
  final Map<TextEditingController, VoidCallback> _destinationListeners = {};

  @override
  void initState() {
    super.initState();
    _setupTextControllerListeners();
    _setupFocusNodeListeners();

    Future.microtask(() {
      context.read<DeliveryCubit>()
        ..fetchRecentLocations()
        ..isPickUpLocation(isPickUpLocation: true);
    });
  }

  void _setupTextControllerListeners() {
    log('Setting up text controller listeners');

    _destinationListeners
      ..forEach((controller, listener) {
        controller.removeListener(listener);
      })
      ..clear();

    // Pickup controller listener
    widget.pickUpController.addListener(() {
      if (!mounted) return;
      final text = widget.pickUpController.text;

      context.read<DeliveryCubit>().searchLocationDebounced(
        text,
        isPickup: true,
      );
    });

    void mainDestinationListener() {
      if (!mounted) return;
      final text = widget.itemDestinationController.text;

      context.read<DeliveryCubit>()
        ..setActiveDestinationIndex(0)
        ..searchLocationDebounced(text, isPickup: false);
    }

    widget.itemDestinationController.addListener(mainDestinationListener);
    _destinationListeners[widget.itemDestinationController] =
        mainDestinationListener;

    final state = context.read<DeliveryCubit>().state;
    if (state.deliveryControllers.isNotEmpty) {
      for (int i = 0; i < state.deliveryControllers.length; i++) {
        final controller = state.deliveryControllers[i];
        if (i == 0 && controller == widget.itemDestinationController) continue;

        void listener() {
          if (!mounted) return;
          final text = controller.text;

          context.read<DeliveryCubit>()
            ..setActiveDestinationIndex(i)
            ..searchLocationDebounced(text, isPickup: false);
        }

        controller.addListener(listener);
        _destinationListeners[controller] = listener;
      }
    }
  }

  void _setupFocusNodeListeners() {
    _pickUpNode.addListener(() {
      if (_pickUpNode.hasFocus) {
        log('Pickup node got focus');
        context.read<DeliveryCubit>()
          ..isPickUpLocation(isPickUpLocation: true)
          ..isDestinationLocation(isDestinationLocation: false)
          ..showRecentPickUpLocations(showRecentlySearchedLocations: true);
      }
    });

    _destinationNode.addListener(() {
      if (_destinationNode.hasFocus) {
        log('Destination node got focus');
        context.read<DeliveryCubit>()
          ..isDestinationLocation(isDestinationLocation: true)
          ..isPickUpLocation(isPickUpLocation: false)
          ..setActiveDestinationIndex(0)
          ..showDestinationRecentlySearchedLocations(
            showDestinationRecentlySearchedLocations: true,
          );
      }
    });
  }

  void _updateDestinationFocusNodes(int count) {
    // Remove listeners from existing nodes first
    for (final node in _destinationNodes) {
      node
        ..removeListener(() {})
        ..dispose();
    }

    _destinationNodes = [];

    for (var i = 0; i < count; i++) {
      final node = FocusNode();
      final index = i;

      node.addListener(() {
        if (node.hasFocus) {
          log('Additional destination node $index got focus');
          context.read<DeliveryCubit>()
            ..isDestinationLocation(isDestinationLocation: true)
            ..isPickUpLocation(isPickUpLocation: false)
            ..setActiveDestinationIndex(index)
            ..showDestinationRecentlySearchedLocations(
              showDestinationRecentlySearchedLocations: true,
            );
        }
      });

      _destinationNodes.add(node);
    }
  }

  @override
  void dispose() {
    _destinationListeners
      ..forEach((controller, listener) {
        controller.removeListener(listener);
      })
      ..clear();

    _pickUpNode.dispose();
    _destinationNode.dispose();

    for (final node in _destinationNodes) {
      node.dispose();
    }

    super.dispose();
  }

  @override
  void didUpdateWidget(LogisticsBottomSheetContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if deliveryControllers changed
    final cubit = context.read<DeliveryCubit>();
    if (cubit.state.deliveryControllers.length != _destinationNodes.length) {
      _updateDestinationFocusNodes(cubit.state.deliveryControllers.length);
      _setupTextControllerListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryCubit, DeliveryState>(
      listener: (context, state) {
        dev.log('Delivery state changed: ${state.status}');
        if (state.status == DeliveryStatus.success) {
          context.showToast(
            message: 'Delivery request successful',
            position: ToastPosition.top,
          );
          Navigator.pop(context);
        }
        if (state.status == DeliveryStatus.failure) {
          context.showToast(
            message: 'Delivery request failed',
            position: ToastPosition.top,
          );
        }
      },
      builder: (context, state) {
        final additionalHeight =
            state.isMultipleDestination
                ? (state.deliveryControllers.length - 1) * 70.h
                : 0;

        final bottom = MediaQuery.of(context).viewInsets.bottom;

        final showRiderFoundSheet = context.select<DeliveryCubit, bool>(
          (DeliveryCubit cubit) => cubit.state.showDeliverySearchSheet,
        );

        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: DraggableScrollableSheet(
            initialChildSize:
                0.5 + (additionalHeight / MediaQuery.of(context).size.height),
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  gradient: whiteAmberGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    ListView(
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      children: [
                        const VSpace(24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 19),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Delivery Details',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.22.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  height: 36,
                                  width: 36,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(11),
                                    color: Colors.white,
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/images/cancel_icon.svg',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const VSpace(15),
                        Container(
                          height: 11,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.37),
                          ),
                        ),
                        const VSpace(15),
                        Padding(
                          padding: const EdgeInsets.only(left: 13),
                          child: Text(
                            'Where to pick up',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 10.89,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const VSpace(7),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          child: TextFieldFactory.location(
                            controller: widget.pickUpController,
                            fillColor: fillColor2,
                            enabledBorderColor: Colors.white,
                            hinText: 'Enter Pick Up Location',
                            enabledBorderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                            hintTextStyle: GoogleFonts.poppins(
                              color: hintTextColor,
                              fontSize: 11.50,
                            ),
                            prefixText: const LogisticsPrefixIcon(
                              imageName: 'street_map',
                            ),
                            focusNode: _pickUpNode,
                            suffixIcon:
                                state.isLoadingPredictions &&
                                        state.isPickUpLocation
                                    ? const LoadingWidget()
                                    : widget.pickUpController.text.isNotEmpty
                                    ? GestureDetector(
                                      onTap: () {
                                        widget.pickUpController.clear();
                                        context.read<DeliveryCubit>()
                                          ..clearPredictions()
                                          ..showRecentPickUpLocations(
                                            showRecentlySearchedLocations: true,
                                          );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 12,
                                          bottom: 12,
                                          left: 15.5,
                                          right: 7,
                                        ),
                                        child: Container(
                                          decoration: ShapeDecoration(
                                            color: const Color(0xFFE61D2A),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    )
                                    : null,
                          ),
                        ),
                        if (state.showPickupPredictions &&
                            state.pickupPredictions.isNotEmpty) ...[
                          _buildPredictionsPanel(
                            state.pickupPredictions,
                            true,
                            _pickUpNode,
                            _destinationNode,
                            widget.pickUpController,
                            widget.itemDestinationController,
                            _destinationListeners,
                          ),
                        ],
                        const VSpace(15),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          child: TextFieldFactory.phone(
                            controller: widget.phoneNumberController,
                            fillColor: fillColor2,
                            hintText: 'Enter Phone Number',
                            enabledColorBorder: Colors.white,
                            enabledBorderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                            prefixText: const LogisticsPrefixIcon(
                              imageName: 'push_arrow',
                            ),
                            hintTextStyle: GoogleFonts.poppins(
                              color: hintTextColor,
                              fontSize: 11.50,
                            ),
                            suffixIcon: const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: LogisticsPrefixIcon(
                                imageName: 'phone_icon',
                              ),
                            ),
                          ),
                        ),
                        const VSpace(10),
                        Padding(
                          padding: const EdgeInsets.only(left: 13),
                          child: Text(
                            'Where to deliver Item',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 10.89,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const VSpace(7),
                        ...List.generate(
                          state.deliveryControllers.isNotEmpty
                              ? state.deliveryControllers.length
                              : 1,
                          (index) {
                            final controller =
                                state.deliveryControllers.isNotEmpty
                                    ? state.deliveryControllers[index]
                                    : widget.itemDestinationController;

                            final focusNode =
                                index == 0
                                    ? _destinationNode
                                    : (index < _destinationNodes.length
                                        ? _destinationNodes[index]
                                        : FocusNode());

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  Flexible(
                                    flex: 5,
                                    child: TextFieldFactory.location(
                                      controller: controller,
                                      fillColor: fillColor2,
                                      enabledBorderColor: Colors.white,
                                      hinText:
                                          index == 0
                                              ? 'Enter Delivery Location'
                                              : 'Enter Delivery Location ${index + 1}',
                                      focusNode: focusNode,
                                      enabledBorderRadius:
                                          const BorderRadius.all(
                                            Radius.circular(10),
                                          ),
                                      hintTextStyle: GoogleFonts.poppins(
                                        color: hintTextColor,
                                        fontSize: 11.50,
                                      ),
                                      prefixText: const LogisticsPrefixIcon(
                                        imageName: 'street_map',
                                      ),
                                      suffixIcon:
                                          state.isLoadingPredictions &&
                                                  state.isDestinationLocation &&
                                                  state.activeDestinationIndex ==
                                                      index
                                              ? const LoadingWidget()
                                              : controller.text.isNotEmpty
                                              ? GestureDetector(
                                                onTap: () {
                                                  controller.clear();
                                                  context
                                                      .read<DeliveryCubit>()
                                                      .clearPredictions();
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 12,
                                                        bottom: 12,
                                                        left: 15.5,
                                                        right: 7,
                                                      ),
                                                  child: Container(
                                                    decoration: ShapeDecoration(
                                                      color: const Color(
                                                        0xFFE61D2A,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              7,
                                                            ),
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              : null,
                                    ),
                                  ),
                                  if (index == 0) ...[
                                    const HSpace(10),
                                    Flexible(
                                      child: InkWell(
                                        onTap: () {
                                          context
                                              .read<DeliveryCubit>()
                                              .addDeliveryDestination(
                                                widget
                                                    .itemDestinationController,
                                              );
                                          _updateDestinationFocusNodes(
                                            state.deliveryControllers.length +
                                                1,
                                          );

                                          _setupTextControllerListeners();
                                        },
                                        child: Container(
                                          height:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.05,
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.05,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                            color: Colors.white,
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (state.isMultipleDestination &&
                                      index != 0) ...[
                                    const HSpace(10),
                                    Flexible(
                                      child: InkWell(
                                        onTap: () {
                                          context
                                              .read<DeliveryCubit>()
                                              .removeDestination(index);

                                          _updateDestinationFocusNodes(
                                            state.deliveryControllers.length -
                                                1,
                                          );

                                          _setupTextControllerListeners();
                                        },
                                        child: Container(
                                          height:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.05,
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.05,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                            color: Colors.white,
                                          ),
                                          child: const Icon(
                                            Icons.remove,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                        if (state.showDestinationPredictions &&
                            state.destinationPredictions.isNotEmpty) ...[
                          _buildPredictionsPanel(
                            state.destinationPredictions,
                            false,
                            null,
                            null,
                            null,
                            widget.itemDestinationController,
                            _destinationListeners,
                          ),
                        ],
                        const VSpace(12),
                        Padding(
                          padding: const EdgeInsets.only(left: 13),
                          child: Text(
                            'Deliver What?',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 10.89,
                              fontWeight: FontWeight.w600,
                              height: 0,
                            ),
                          ),
                        ),
                        const VSpace(4),
                        Padding(
                          padding: const EdgeInsets.only(left: 13, right: 20),
                          child: TextFieldFactory.itemField(
                            controller: widget.destinationController,
                            textAlignVertical: TextAlignVertical.center,
                            textAlign: TextAlign.center,
                            contentPadding: const EdgeInsets.only(top: 10),
                            fillColor: fillColor2,
                            focusedBorderRadius: BorderRadius.circular(10),
                            hinText:
                                'Example: Big Sized Sneaker boxed nike - Red carton',
                            enabledBorderColor: Colors.white,
                            enabledBorderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                            hintTextStyle: GoogleFonts.poppins(
                              color: hintTextColor,
                              fontSize: 10.18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const VSpace(25),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          child: FreedomButton(
                            onPressed: () => _saveOrderDetails(context, state),
                            buttonTitle: Text(
                              'Save Order Details',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            useGradient: true,
                            gradient: gradient,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                    if (state.status == DeliveryStatus.loading)
                      ColoredBox(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPredictionsPanel(
    List<PlacePrediction> predictions,
    bool isPickup,
    FocusNode? pickupNode,
    FocusNode? destinationNode,
    TextEditingController? pickupController,
    TextEditingController? destinationController,
    Map<TextEditingController, void Function()>? deliveryControllers,
  ) {
    if (predictions.isEmpty ||
        (isPickup &&
            !context.read<DeliveryCubit>().state.showPickupPredictions) ||
        (!isPickup &&
            !context.read<DeliveryCubit>().state.showDestinationPredictions)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 8, bottom: 4),
            child: Text(
              isPickup ? 'Pickup Locations' : 'Destination Locations',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ...predictions.map((prediction) {
            log('Prediction panel: ${prediction.mainText}');
            return GestureDetector(
              onTap: () {
                context.read<DeliveryCubit>().hideAllPredictionPanels();

                if (isPickup) {
                  context.read<DeliveryCubit>().handlePickUpLocation(
                    prediction,
                    pickupNode!,
                    destinationNode!,
                    pickupController!,
                    destinationController!,
                    () {
                      if (_destinationListeners[destinationController] !=
                          null) {
                        destinationController.removeListener(
                          _destinationListeners[destinationController]!,
                        );
                      }
                    },
                    () {
                      if (_destinationListeners[destinationController] !=
                          null) {
                        destinationController.addListener(
                          _destinationListeners[destinationController]!,
                        );
                      }
                    },
                  );
                } else {
                  // Handle destination location selection based on active index
                  final activeIndex =
                      context
                          .read<DeliveryCubit>()
                          .state
                          .activeDestinationIndex;

                  if (activeIndex == 0) {
                    // Main destination
                    context.read<DeliveryCubit>().handleDestinationLocation(
                      prediction,
                      _destinationNode,
                      widget.itemDestinationController,
                      () {
                        if (_destinationListeners[destinationController] !=
                            null) {
                          destinationController?.removeListener(
                            _destinationListeners[destinationController]!,
                          );
                        }
                      },
                      () {
                        if (_destinationListeners[destinationController] !=
                            null) {
                          destinationController?.addListener(
                            _destinationListeners[destinationController]!,
                          );
                        }
                      },
                    );
                  } else {
                    // Additional destination
                    if (activeIndex <
                        context
                            .read<DeliveryCubit>()
                            .state
                            .deliveryControllers
                            .length) {
                      final controller =
                          context
                              .read<DeliveryCubit>()
                              .state
                              .deliveryControllers[activeIndex];
                      final focusNode =
                          activeIndex < _destinationNodes.length
                              ? _destinationNodes[activeIndex]
                              : FocusNode();

                      context
                          .read<DeliveryCubit>()
                          .handleAdditionalDestinationLocation(
                            prediction,
                            focusNode,
                            controller,
                            activeIndex,
                            () {
                              if (_destinationListeners[controller] != null) {
                                controller.removeListener(
                                  _destinationListeners[controller]!,
                                );
                              }
                            },
                            () {
                              if (_destinationListeners[controller] != null) {
                                controller.addListener(
                                  _destinationListeners[controller]!,
                                );
                              }
                            },
                          );
                    }
                  }
                }
              },
              child: Column(
                children: [
                  Divider(thickness: 1, color: Colors.black.withOpacity(0.05)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.05),
                            ),
                          ),
                          child: Icon(
                            _getIconData(prediction.iconType),
                            color: isPickup ? Colors.orange : Colors.red,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prediction.mainText,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                prediction.description,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
          }),
        ],
      ),
    );
  }

  IconData _getIconData(String iconType) {
    switch (iconType) {
      case 'local_airport':
        return Icons.local_airport;
      case 'train':
        return Icons.train;
      case 'hotel':
        return Icons.hotel;
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      default:
        return Icons.location_on;
    }
  }

  void _saveOrderDetails(BuildContext context, DeliveryState state) {
    var destinations = <String>[];

    if (state.isMultipleDestination) {
      destinations = context.read<DeliveryCubit>().getAllDestinationValues();
    } else {
      destinations = [widget.itemDestinationController.text];
    }

    final model = DeliveryModel.withMultipleDestinations(
      pickupLocation: widget.pickUpController.text,
      destinationLocations: destinations,
      deliveryType: 'parcel',
      packageName: 'Package',
      packageSize: 'medium',
      packageDescription: widget.destinationController.text,
      receipientName: 'Recipient',
      receipientPhone: widget.phoneNumberController.text,
      paymentMethod: 'cash',
    );

    context.read<DeliveryCubit>().requestDelivery(model);
  }
}
