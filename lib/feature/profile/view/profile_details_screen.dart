import 'dart:developer';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:freedom/feature/profile/cubit/profile_cubit.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/verify_otp_screen.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/text_field_factory.dart';
import 'package:freedom/shared/widgets/toasts.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});
  static const routeName = '/profile_details_screen';

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final emailFormKey = GlobalKey<FormState>();
  final phoneNumberFormKey = GlobalKey<FormState>();

  String countryCode = '+233';

  // Track which field is being edited
  String? activeField;
  // Store original values to detect changes
  String? originalEmail;
  String? originalPhone;

  @override
  void initState() {
    super.initState();
    phoneController
      ..text = countryCode

      // Only setup the formatter listener without setState calls
      ..addListener(() {
        // Just handle the country code formatting without setState
        if (!phoneController.text.startsWith(countryCode) && mounted) {
          final currentPosition = phoneController.selection.baseOffset;
          phoneController
            ..text = countryCode +
                phoneController.text.replaceAll(RegExp(r'^\+\d+'), '')
            ..selection = TextSelection.fromPosition(
              TextPosition(
                  offset: currentPosition < 0
                      ? phoneController.text.length
                      : currentPosition),
            );
        }
      });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              children: [
                const Padding(
                    padding: EdgeInsets.only(left: 27),
                    child: DecoratedBackButton()),
                const HSpace(84.91),
                Center(
                  child: Text(
                    'Profile Details',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 13.09,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              ],
            ),
            const VSpace(14.91),
            Container(
              height: 8,
              color: greyColor,
            ),
            const VSpace(8),

            // Single BlocConsumer for all profile data
            Expanded(
              child: BlocConsumer<ProfileCubit, ProfileState>(
                listener: (context, state) {
                  if (state is NumberUpdated || state is EmailUpdated) {
                    context.showToast(
                        message: state is NumberUpdated
                            ? state.message
                            : state is EmailUpdated
                                ? state.message
                                : '',
                        type: ToastType.success,
                        position: ToastPosition.top);
                    Future.delayed(const Duration(milliseconds: 1000));
                    Navigator.of(context)
                        .pushNamed('/phone_update_verification_screen');

                    // Reset active field after successful update
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          activeField = null;
                        });
                      }
                    });
                  }

                  if (state is NumberUpdateError || state is EmailUpdateError) {
                    context.showToast(
                        message: 'Failed to update',
                        type: ToastType.error,
                        position: ToastPosition.top);
                  }
                },
                builder: (context, state) {
                  // Loading state
                  if (state is ProfileLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  final updatingNumberState = state is UpdatingNumber;
                  final updatingEmailState = state is UpdatingEmail;

                  if (updatingNumberState || updatingEmailState) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(strokeWidth: 1),
                    );
                  }

                  // Error state with retry button
                  if (state is ProfileError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Failed to load profile',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const VSpace(16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<ProfileCubit>().getUserProfile();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Retry',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Only set the controller values if the state is ProfileLoaded
                  // and the controllers are not disposed
                  if (state is ProfileLoaded && mounted) {
                    // Store original values if not already set
                    if (originalEmail == null) {
                      originalEmail = state.user!.data.email;
                    }
                    if (originalPhone == null) {
                      originalPhone = state.user!.data.phone;
                    }

                    nameController.text =
                        '${state.user!.data.firstName} ${state.user!.data.surname}';

                    // Only set controller text if it's not the active field to avoid cursor jump
                    if (activeField != 'email') {
                      emailController.text = state.user!.data.email;
                    }
                    if (activeField != 'phone') {
                      phoneController.text = state.user!.data.phone;
                    }

                    // Check if fields have changed after setting their values
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (emailController.text != originalEmail &&
                          activeField == null) {
                        if (mounted) {
                          setState(() {
                            activeField = 'email';
                          });
                        }
                      } else if (phoneController.text != originalPhone &&
                          activeField == null) {
                        if (mounted) {
                          setState(() {
                            activeField = 'phone';
                          });
                        }
                      }
                    });
                  }

                  return Padding(
                    padding: const EdgeInsets.only(left: 27, right: 19),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 13.09,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const VSpace(10),
                          TextFieldFactory.name(
                            controller: nameController,
                            fillColor: Colors.white,
                            enabledColorBorder: const Color(0xFFE1E1E1),
                            hinText: state is ProfileLoaded
                                ? '${state.user!.data.firstName} ${state.user!.data.surname}'
                                : 'Full name',
                            focusedBorderColor: Colors.black,
                            hintTextStyle:
                                GoogleFonts.poppins(color: Colors.black),
                            // Read-only since name update isn't implemented
                            readOnly: true,
                          ),

                          const VSpace(20),

                          Text(
                            'Surname',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 13.09,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const VSpace(10),
                          TextFieldFactory.name(
                            controller: nameController,
                            fillColor: Colors.white,
                            enabledColorBorder: const Color(0xFFE1E1E1),
                            hinText: state is ProfileLoaded
                                ? '${state.user!.data.firstName} ${state.user!.data.surname}'
                                : 'surname',
                            focusedBorderColor: Colors.black,
                            hintTextStyle:
                                GoogleFonts.poppins(color: Colors.black),
                            // Read-only since name update isn't implemented
                            readOnly: true,
                          ),
                          const VSpace(20),
                          // Email Field
                          Row(
                            children: [
                              Text(
                                'Email',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 13.09,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const HSpace(10),
                              if (state is ProfileLoaded &&
                                  state.user!.data.isEmailVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffBFFF9F),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Verified',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11.9,
                                        color: const Color(0xff52C01B)),
                                  ),
                                ),
                              // Show active indicator
                              if (activeField == 'email')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Editing',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11.9,
                                        color: Colors.amber[800]),
                                  ),
                                ),
                            ],
                          ),
                          const VSpace(10),
                          Form(
                            key: emailFormKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: TextFieldFactory.email(
                              controller: emailController,
                              fillColor: Colors.white,
                              hinText: state is ProfileLoaded
                                  ? state.user!.data.email
                                  : 'youremail@email.com',
                              focusedBorderColor: activeField == 'email'
                                  ? Colors.amber[800]
                                  : Colors.black,
                              enabledColorBorder: activeField == 'email'
                                  ? Colors.amber[800]
                                  : const Color(0xFFE1E1E1),
                              hintTextStyle: GoogleFonts.poppins(),
                              onTap: () {
                                // Clear phone field edit state if user taps email
                                if (activeField == 'phone') {
                                  // Reset phone to original value
                                  phoneController.text = originalPhone ?? '';
                                }
                                // Use a post-frame callback to avoid setState during build
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() {
                                      activeField = 'email';
                                    });
                                  }
                                });
                              },
                              // Disable if another field is being edited
                              readOnly:
                                  activeField != null && activeField != 'email',
                            ),
                          ),

                          const VSpace(20),

                          // Phone Number Field
                          Row(
                            children: [
                              Text(
                                'Phone Number',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 13.09,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const HSpace(10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xffBFFF9F),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  state is ProfileLoaded &&
                                          state.user!.data.isPhoneVerified
                                      ? 'verified'
                                      : 'unverified',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                      fontSize: 11.9,
                                      color: const Color(0xff52C01B)),
                                ),
                              ),
                              // Show active indicator
                              if (activeField == 'phone')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Editing',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11.9,
                                        color: Colors.amber[800]),
                                  ),
                                ),
                            ],
                          ),
                          const VSpace(10),
                          Form(
                            key: phoneNumberFormKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: TextFieldFactory.phone(
                              controller: phoneController,
                              fillColor: Colors.white,
                              hintText: '+244-902-345-909',
                              fontStyle: GoogleFonts.poppins(),
                              focusedBorderColor: activeField == 'phone'
                                  ? Colors.amber[800]
                                  : Colors.black,
                              enabledColorBorder: activeField == 'phone'
                                  ? Colors.amber[800]
                                  : const Color(0xFFE1E1E1),
                              onTap: () {
                                // Clear email field edit state if user taps phone
                                if (activeField == 'email') {
                                  // Reset email to original value
                                  emailController.text = originalEmail ?? '';
                                }
                                // Use a post-frame callback to avoid setState during build
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() {
                                      activeField = 'phone';
                                    });
                                  }
                                });
                              },
                              // Disable if another field is being edited
                              readOnly:
                                  activeField != null && activeField != 'phone',
                              prefixText: Transform.translate(
                                offset: const Offset(0, -5),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    top: 18,
                                    bottom: 7,
                                    right: 17,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: const Color(0x4FF59E0B),
                                    ),
                                    child: Stack(
                                      children: [
                                        CountryCodePicker(
                                          textStyle: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.black),
                                          dialogTextStyle: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.black),
                                          countryFilter: const ['GH', 'NG'],
                                          dialogSize: const Size(300, 200),
                                          hideSearch: true,
                                          onChanged: (value) {
                                            if (mounted) {
                                              countryCode =
                                                  value.dialCode ?? '+233';
                                              phoneController.text =
                                                  countryCode;

                                              // Use post-frame callback to avoid setState during build
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                if (mounted) {
                                                  setState(() {
                                                    // Set active field to phone when changing country code
                                                    activeField = 'phone';
                                                  });
                                                }
                                              });
                                            }
                                          },
                                          padding: EdgeInsets.zero,
                                          initialSelection: 'GH',
                                          hideMainText: true,
                                          enabled: activeField == null ||
                                              activeField == 'phone',
                                        ),
                                        Positioned(
                                          top: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.014,
                                          left: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.11,
                                          child: SvgPicture.asset(
                                              'assets/images/drop_down.svg'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Phone number is required';
                                }
                                final cleanedNumber =
                                    val.replaceAll(RegExp(r'\D'), '');

                                if (cleanedNumber.isEmpty) {
                                  return 'Please enter digits only';
                                }

                                if (cleanedNumber.length < 10) {
                                  return 'Phone number must be at least 10 digits long';
                                }

                                return null;
                              },
                              hintTextStyle: GoogleFonts.poppins(),
                            ),
                          ),

                          const VSpace(30),
                          // Save Button - Only active when a field is being edited
                          Center(
                            child: ElevatedButton(
                              onPressed: activeField == null
                                  ? null // Disable if no field is active
                                  : () {
                                      if (activeField == 'phone') {
                                        if (phoneNumberFormKey.currentState !=
                                                null &&
                                            phoneNumberFormKey.currentState!
                                                .validate()) {
                                          context
                                              .read<ProfileCubit>()
                                              .setPhoneNumber(
                                                  phoneController.text.trim());
                                          log('Updating phone number: ${phoneController.text.trim()}');
                                          context
                                              .read<ProfileCubit>()
                                              .requestNumberUpdate(
                                                  phoneController.text.trim());
                                        }
                                      } else if (activeField == 'email') {
                                        if (emailFormKey.currentState != null &&
                                            emailFormKey.currentState!
                                                .validate()) {
                                          log('Updating email: ${emailController.text.trim()}');
                                          context
                                              .read<ProfileCubit>()
                                              .requestEmailUpdate(
                                                  emailController.text.trim());
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey,
                                minimumSize: const Size(200, 45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                activeField == null
                                    ? 'No Changes'
                                    : activeField == 'phone'
                                        ? 'Update Phone Number'
                                        : 'Update Email',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          ),
                          if (activeField != null)
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  // Reset the active field and revert changes
                                  // Store the current active field
                                  final currentActiveField = activeField;

                                  // Reset the field's value
                                  if (currentActiveField == 'email') {
                                    emailController.text = originalEmail ?? '';
                                  } else if (currentActiveField == 'phone') {
                                    phoneController.text = originalPhone ?? '';
                                  }

                                  // Use post-frame callback to avoid setState during build
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (mounted) {
                                      setState(() {
                                        activeField = null;
                                      });
                                    }
                                  });
                                },
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
