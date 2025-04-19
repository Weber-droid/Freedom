import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:freedom/app_preference.dart';
import 'package:freedom/feature/auth/local_data_source/local_user.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/auth/view/login_view.dart';
import 'package:freedom/feature/profile/cubit/profile_cubit.dart';
import 'package:freedom/feature/profile/view/address_screen.dart';
import 'package:freedom/feature/profile/view/profile_details_screen.dart';
import 'package:freedom/feature/profile/view/security_screen.dart';
import 'package:freedom/feature/wallet/view/wallet_screen.dart';
import 'package:freedom/shared/constants/hive_constants.dart';
import 'package:freedom/shared/sections_tiles.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/toasts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const String routeName = '/profile-screen';
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProfileCubit>().getUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'profileImage',
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocConsumer<ProfileCubit, ProfileState>(
            listener: (context, state) {
              if (state is ProfileError) {
                context.showToast(
                    message: state.message,
                    type: ToastType.error,
                    position: ToastPosition.top);
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  Center(
                    child: Text(
                      'Profile',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                  const VSpace(35),
                  ProfileCard(userData: User(), state: state),
                  const VSpace(10),
                  const Divider(
                    thickness: 5,
                    color: Color(0xFFF1F1F1),
                  ),
                  const VSpace(22.49),
                  PersonalDataSection(
                    onProfileTap: () {
                      Navigator.pushNamed(
                          context, ProfileDetailsScreen.routeName);
                    },
                    onWalletTap: () {
                      Navigator.pushNamed(context, WalletScreen.routeName);
                    },
                    paddingSection: const EdgeInsets.all(5),
                  ),
                  const VSpace(10.49),
                  MoreSection(
                    onTapAddress: () => Navigator.pushNamed(
                      context,
                      AddressScreen.routeName,
                    ),
                    onTapLogout: () async {
                      await AppPreferences.clearAll().then((_) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          LoginView.routeName,
                          (route) => false,
                        );
                      });
                    },
                    onTapSecurity: () {
                      Navigator.pushNamed(
                        context,
                        SecurityScreen.routeName,
                      );
                    },
                    paddingSection: const EdgeInsets.all(5),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.userData,
    required this.state,
    super.key,
  });

  final User userData;
  final ProfileState state;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(4),
          ),
          height: 215,
          width: 348,
          child: Padding(
            padding: const EdgeInsets.only(left: 15, top: 9, right: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '10 Ride Completed',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11.23,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  'Reward',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11.23,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SvgPicture.asset('assets/images/arrow_right_icon.svg'),
              ],
            ),
          ),
        ),
        Positioned(
          top: 28,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
              image: const DecorationImage(
                image: AssetImage('assets/images/profile_background.png'),
                fit: BoxFit.cover,
              ),
            ),
            height: 187,
            width: 372,
            child: Column(
              children: [
                const VSpace(13),
                Container(
                  width: 67,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildProfileImage(context),
                      Positioned(
                        bottom: -2,
                        right: -8,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(width: 2),
                          ),
                          child: SvgPicture.asset(
                            'assets/images/edit_profile.svg',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildUserName(),
                const VSpace(10),
                Container(
                  width: 132,
                  height: 24,
                  padding: const EdgeInsets.only(left: 10),
                  decoration: ShapeDecoration(
                    color: Colors.white.withOpacity(0.34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(34),
                    ),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset('assets/images/copy_button_icon.svg'),
                      const HSpace(7),
                      _buildContactInfo()
                    ],
                  ),
                ),
                Text(
                  'Business Suite',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        // For loading state
        if (state is ProfileLoading || state is UploadingImage) {
          return CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            child: const CircularProgressIndicator.adaptive(strokeWidth: 1),
          );
        }

        if (state is ProfileLoaded) {
          final profileData = state.user?.data;
          return GestureDetector(
            onTap: () => _showImagePickerOptions(context),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      _getProfileImage(profileData?.profilePicture),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        if (state is ImageUploaded) {
          final profileData = state.user?.data;
          return GestureDetector(
            onTap: () => _showImagePickerOptions(context),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      _getProfileImage(profileData?.profilePicture),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return GestureDetector(
          onTap: () => _showImagePickerOptions(context),
          child: CircleAvatar(
            radius: 50,
            backgroundImage: _getProfileImage(null),
          ),
        );
      },
    );
  }

  ImageProvider _getProfileImage(String? profilePicture) {
    if (profilePicture != null && profilePicture.isNotEmpty) {
      return NetworkImage(profilePicture);
    }
    return const AssetImage('assets/images/user_profile.png');
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a photo'),
            onTap: () {
              Navigator.of(context).pop();
              context.read<ProfileCubit>().pickImage();
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from gallery'),
            onTap: () {
              Navigator.of(context).pop();
              context
                  .read<ProfileCubit>()
                  .pickImage(source: ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserName() {
    if (state is ProfileLoading) {
      return Text('Loading...',
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.white));
    } else if (state is ProfileLoaded) {
      final profileData = (state as ProfileLoaded).user?.data;
      return Text(
        '${profileData!.firstName}',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    } else {
      return Text(
        'User Name',
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  Widget _buildContactInfo() {
    if (state is ProfileLoading) {
      return Text('Loading...',
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.white));
    } else if (state is ProfileLoaded) {
      final profileData = (state as ProfileLoaded).user!.data;
      return Text(
        profileData.isPhoneVerified
            ? profileData.phone
            : 'Phone not verified',
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: Colors.white,
        ),
      );
    } else {
      return Text(
        'User Phone',
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: Colors.white,
        ),
      );
    }
  }
}
