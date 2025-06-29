import 'dart:developer';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:freedom/feature/profile/cubit/profile_cubit.dart';
import 'package:freedom/feature/profile/model/profile_model.dart';
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
  final refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().getUserProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
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
                  child: DecoratedBackButton(),
                ),
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
                ),
              ],
            ),
            const VSpace(14.91),
            Container(height: 8, color: greyColor),
            const VSpace(8),

            // Main content with BlocConsumer
            Expanded(
              child: BlocConsumer<ProfileCubit, ProfileState>(
                listener: (context, state) {
                  // Handle toast messages and navigation
                  if (state is NumberUpdated || state is EmailUpdated) {
                    context.showToast(
                      message:
                          state is NumberUpdated
                              ? state.message
                              : (state is EmailUpdated ? state.message : ''),
                      type: ToastType.success,
                      position: ToastPosition.top,
                    );

                    Future<void>.delayed(const Duration(milliseconds: 1000));
                    Navigator.of(
                      context,
                    ).pushNamed('/phone_update_verification_screen');
                  }

                  if (state is ProfileError) {
                    context.showToast(
                      message: 'Failed to load profile: ${state.message}',
                      type: ToastType.error,
                      position: ToastPosition.top,
                    );
                  }

                  if (state is NumberUpdateError || state is EmailUpdateError) {
                    final String errorMessage =
                        state is NumberUpdateError
                            ? state.message
                            : (state as EmailUpdateError).message;

                    context.showToast(
                      message: errorMessage,
                      type: ToastType.error,
                      position: ToastPosition.top,
                    );
                  }
                },
                builder: (context, state) {
                  final isInitialLoad =
                      state is ProfileLoading &&
                      context.read<ProfileCubit>().state is! ProfileLoaded &&
                      context.read<ProfileCubit>().state is! ProfileError;

                  if (isInitialLoad) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bool isUpdating =
                      state is UpdatingNumber || state is UpdatingEmail;

                  final loadedState =
                      state is ProfileLoaded
                          ? state
                          : (context.read<ProfileCubit>().state is ProfileLoaded
                              ? context.read<ProfileCubit>().state
                                  as ProfileLoaded
                              : null);

                  final emptyUser = ProfileLoaded(
                    user: ProfileModel(
                      data: ProfileData(
                        id: '',
                        name: '',
                        email: '',
                        phone: '',
                        isPhoneVerified: false,
                        isEmailVerified: false,
                        authProvider: '',
                        role: '',
                        profilePicture: '',
                        mobileMoneyProvider: '',
                        mobileMoneyNumber: '',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                      success: false,
                    ),
                  );

                  final profileState = loadedState ?? emptyUser;

                  if (loadedState != null) {
                    if (loadedState.activeField != 'email') {
                      emailController.text = loadedState.user!.data.email;
                    }

                    if (loadedState.activeField != 'phone') {
                      phoneController.text = loadedState.user!.data.phone;
                    }

                    if (loadedState.activeField != 'name') {
                      nameController.text = loadedState.user!.data.firstName!;
                      surnameController.text = loadedState.user!.data.surname!;
                    }
                  }

                  // Build main content with refresh indicator
                  return RefreshIndicator(
                    key: refreshKey,
                    onRefresh: () async {
                      await context.read<ProfileCubit>().getUserProfile();
                      // Wait for a reasonable time to prevent infinite loading
                      return Future.delayed(const Duration(seconds: 2));
                    },
                    child: Stack(
                      children: [
                        _buildProfileForm(context, profileState),
                        if (isUpdating)
                          ColoredBox(
                            color: Colors.black.withValues(alpha: 0.1),
                            child: const Center(
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 1,
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildProfileForm(BuildContext context, ProfileLoaded state) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 27, right: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'First Name',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 13.09,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const HSpace(10),
              if (state.activeField == 'name')
                _buildStatusBadge(
                  'Editing',
                  Colors.amber.withValues(alpha: 0.3),
                  Colors.amber[800] ?? Colors.amber,
                ),
            ],
          ),
          const VSpace(10),
          TextFieldFactory.name(
            controller: nameController,
            fillColor: Colors.white,
            enabledColorBorder:
                state.activeField == 'name'
                    ? Colors.amber[800] ?? Colors.amber
                    : const Color(0xFFE1E1E1),
            hinText: state.user?.data.firstName ?? '',
            focusedBorderColor:
                state.activeField == 'name' ? Colors.amber[800] : Colors.black,
            hintTextStyle: GoogleFonts.poppins(color: Colors.black),
            readOnly: state.activeField != null && state.activeField != 'name',
            onTap: () {
              context.read<ProfileCubit>().startEditingField('name');
            },
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
            controller: surnameController,
            fillColor: Colors.white,
            enabledColorBorder:
                state.activeField == 'name'
                    ? Colors.amber[800] ?? Colors.amber
                    : const Color(0xFFE1E1E1),
            hinText: state.user?.data.surname ?? '',
            focusedBorderColor:
                state.activeField == 'name' ? Colors.amber[800] : Colors.black,
            hintTextStyle: GoogleFonts.poppins(color: Colors.black),
            readOnly: state.activeField != null && state.activeField != 'name',
            onTap: () {
              context.read<ProfileCubit>().startEditingField('name');
            },
          ),
          const VSpace(20),
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
              if (state.user?.data.isEmailVerified ?? false)
                _buildStatusBadge(
                  'Verified',
                  const Color(0xffBFFF9F),
                  const Color(0xff52C01B),
                ),
              if (state.activeField == 'email')
                _buildStatusBadge(
                  'Editing',
                  Colors.amber.withValues(alpha: 0.3),
                  Colors.amber[800] ?? Colors.amber,
                ),
            ],
          ),
          const VSpace(10),
          Form(
            key: emailFormKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: TextFieldFactory.email(
              controller: emailController,
              fillColor: Colors.white,
              hinText: state.user?.data.email ?? '',
              focusedBorderColor:
                  state.activeField == 'email'
                      ? Colors.amber[800]
                      : Colors.black,
              enabledColorBorder:
                  state.activeField == 'email'
                      ? Colors.amber[800] ?? Colors.amber
                      : const Color(0xFFE1E1E1),
              hintTextStyle: GoogleFonts.poppins(),
              onTap: () {
                context.read<ProfileCubit>().startEditingField('email');
              },
              readOnly:
                  state.activeField != null && state.activeField != 'email',
              validator: (email) {
                if (email == null || email.isEmpty) {
                  return 'Please enter your email';
                }
                final regX = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                );
                if (!regX.hasMatch(email)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ),

          const VSpace(20),

          // Phone Number Field with status badges
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
              if (state.user?.data.isPhoneVerified ?? false)
                _buildStatusBadge(
                  'Verified',
                  const Color(0xffBFFF9F),
                  const Color(0xff52C01B),
                ),
              if (state.activeField == 'phone')
                _buildStatusBadge(
                  'Editing',
                  Colors.amber.withValues(alpha: 0.3),
                  Colors.amber[800] ?? Colors.amber,
                ),
            ],
          ),
          const VSpace(10),
          Form(
            key: phoneNumberFormKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: TextFieldFactory.phone(
              controller: phoneController,
              fillColor: Colors.white,
              hintText: '+233-902-345-909',
              fontStyle: GoogleFonts.poppins(),
              focusedBorderColor:
                  state.activeField == 'phone'
                      ? Colors.amber[800]
                      : Colors.black,
              enabledColorBorder:
                  state.activeField == 'phone'
                      ? Colors.amber[800] ?? Colors.amber
                      : const Color(0xFFE1E1E1),
              onTap: () {
                context.read<ProfileCubit>().startEditingField('phone');
              },
              readOnly:
                  state.activeField != null && state.activeField != 'phone',
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
                            color: Colors.black,
                          ),
                          dialogTextStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                          countryFilter: const ['GH', 'NG'],
                          dialogSize: const Size(300, 200),
                          hideSearch: true,
                          // Inside the CountryCodePicker's onChanged callback:
                          onChanged: (value) {
                            final newCountryCode = value.dialCode ?? '+233';

                            context.read<ProfileCubit>().updateCountryCode(
                              newCountryCode,
                            );

                            if (state.activeField == 'phone') {
                              final phoneWithoutCode = phoneController.text
                                  .replaceAll(RegExp(r'^\+\d+'), '');
                              phoneController
                                ..text = newCountryCode + phoneWithoutCode
                                ..selection = TextSelection.fromPosition(
                                  TextPosition(
                                    offset: phoneController.text.length,
                                  ),
                                );
                            }
                          },
                          padding: EdgeInsets.zero,
                          initialSelection: 'GH',
                          hideMainText: true,
                          enabled:
                              state.activeField == null ||
                              state.activeField == 'phone',
                        ),
                        Positioned(
                          top: MediaQuery.of(context).size.height * 0.014,
                          left: MediaQuery.of(context).size.width * 0.11,
                          child: SvgPicture.asset(
                            'assets/images/drop_down.svg',
                          ),
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

                final cleanedNumber = val.replaceAll(RegExp(r'\D'), '');

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

          // Action buttons
          Center(
            child: ElevatedButton(
              onPressed:
                  state.activeField == null
                      ? null
                      : () => _handleUpdatePress(context, state),
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
                state.activeField == null
                    ? 'No Changes'
                    : state.activeField == 'phone'
                    ? 'Update Phone Number'
                    : state.activeField == 'email'
                    ? 'Update Email'
                    : 'Update Name',
                style: GoogleFonts.poppins(),
              ),
            ),
          ),

          if (state.activeField != null)
            Center(
              child: TextButton(
                onPressed: () {
                  // Reset field to original value and cancel edit mode
                  if (state.activeField == 'email') {
                    emailController.text =
                        state.originalEmail ?? state.user?.data.email ?? '';
                  } else if (state.activeField == 'phone') {
                    phoneController.text =
                        state.originalPhone ?? state.user?.data.phone ?? '';
                  } else if (state.activeField == 'name') {
                    nameController.text = state.user?.data.firstName ?? '';
                    surnameController.text = state.user?.data.surname ?? '';
                  }
                  context.read<ProfileCubit>().cancelEdit();
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.red, fontSize: 14),
                ),
              ),
            ),

          // Add padding at bottom for better scrolling
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    String text,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(fontSize: 11.9, color: textColor),
      ),
    );
  }

  void _handleUpdatePress(BuildContext context, ProfileLoaded state) {
    if (state.activeField == 'email') {
      if (emailFormKey.currentState != null &&
          emailFormKey.currentState!.validate()) {
        log('Updating email: ${emailController.text.trim()}');
        context.read<ProfileCubit>().requestEmailUpdate(
          emailController.text.trim(),
        );
      }
    } else if (state.activeField == 'phone') {
      if (phoneNumberFormKey.currentState != null &&
          phoneNumberFormKey.currentState!.validate()) {
        log('Updating phone number: ${phoneController.text.trim()}');
        context.read<ProfileCubit>().requestNumberUpdate(
          phoneController.text.trim(),
        );
      }
    } else if (state.activeField == 'name') {
      final firstName = nameController.text.trim();
      final surname = surnameController.text.trim();

      if (firstName.isNotEmpty && surname.isNotEmpty) {
        context.read<ProfileCubit>().updateUserNames(firstName, surname);
      } else {
        context.showToast(
          message: 'Name and surname cannot be empty',
          type: ToastType.error,
          position: ToastPosition.top,
        );
      }
    }
  }
}

class DecoratedBackButton extends StatelessWidget {
  const DecoratedBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        height: 38.09,
        width: 38.09,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8.86, 8.86, 9.74, 9.74),
          child: SvgPicture.asset('assets/images/back_button.svg'),
        ),
      ),
      onTap: () => Navigator.pop(context),
    );
  }
}
