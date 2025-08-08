import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/feature/auth/local_data_source/local_user.dart';
import 'package:freedom/feature/auth/view/login_view.dart';
import 'package:freedom/feature/profile/cubit/profile_cubit.dart';
import 'package:freedom/feature/profile/view/address_screen.dart';
import 'package:freedom/feature/profile/view/profile_details_screen.dart';
import 'package:freedom/feature/profile/view/security_screen.dart';
import 'package:freedom/feature/wallet/view/wallet_screen.dart';
import 'package:freedom/shared/sections_tiles.dart';
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
      child: RefreshIndicator(
        onRefresh: () async {
          return context.read<ProfileCubit>().getUserProfile();
        },
        child: BlocConsumer<ProfileCubit, ProfileState>(
          listener: (context, state) {
            if (state is LogoutSuccess) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                LoginView.routeName,
                (route) => false,
              );
            }
            if (state is LogoutError) {
              context.showToast(
                message: state.message,
                type: ToastType.error,
                position: ToastPosition.top,
              );
            }
          },
          builder: (context, state) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: BlocConsumer<ProfileCubit, ProfileState>(
                  listener: (context, state) {
                    if (state is ProfileError) {
                      context.showToast(
                        message: state.message,
                        type: ToastType.error,
                        position: ToastPosition.top,
                      );
                    }
                  },
                  builder: (context, state) {
                    return SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Column(
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
                          const Divider(thickness: 5, color: Color(0xFFF1F1F1)),
                          const VSpace(22.49),
                          PersonalDataSection(
                            onProfileTap: () {
                              Navigator.pushNamed(
                                context,
                                ProfileDetailsScreen.routeName,
                              );
                            },
                            onWalletTap: () {
                              Navigator.pushNamed(
                                context,
                                WalletScreen.routeName,
                              );
                            },
                            paddingSection: const EdgeInsets.all(5),
                          ),
                          const VSpace(10.49),
                          MoreSection(
                            onTapAddress:
                                () => Navigator.pushNamed(
                                  context,
                                  AddressScreen.routeName,
                                ),
                            onTapLogout: () async {
                              context.read<ProfileCubit>().logout();
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
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({required this.userData, required this.state, super.key});

  final User userData;
  final ProfileState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: _buildMainProfileCard(context),
    );
  }

  Widget _buildMainProfileCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildProfileSection(context),
                const SizedBox(height: 24),
                _buildContactSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: _buildProfileImage(context),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildUserName(),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (state is ProfileLoaded) {
                Clipboard.setData(
                  ClipboardData(text: (state as ProfileLoaded).originalPhone!),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Phone number copied!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.copy, color: Colors.white, size: 14),
            ),
          ),
          const SizedBox(width: 12),
          _buildContactInfo(),
        ],
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading || state is UploadingImage) {
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        if (state is ProfileLoaded || state is ImageUploaded) {
          final profileData =
              state is ProfileLoaded
                  ? (state).user?.data
                  : (state as ImageUploaded).user?.data;

          return GestureDetector(
            onTap: () => _showImagePickerOptions(context),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: _getProfileImage(profileData?.profilePicture),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () => _showImagePickerOptions(context),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: _getProfileImage(null),
                fit: BoxFit.cover,
              ),
            ),
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
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFF667eea),
                    ),
                  ),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.read<ProfileCubit>().pickImage();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Color(0xFF667eea),
                    ),
                  ),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.read<ProfileCubit>().pickImage(
                      source: ImageSource.gallery,
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildUserName() {
    if (state is ProfileLoading) {
      return Text(
        'Loading...',
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
      );
    } else if (state is ProfileLoaded) {
      final profileData = (state as ProfileLoaded).user?.data;
      return Text(
        '${profileData!.firstName}',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    } else {
      return Text(
        'User Name',
        style: GoogleFonts.poppins(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  Widget _buildContactInfo() {
    if (state is ProfileLoading) {
      return Text(
        'Loading...',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
      );
    } else if (state is ProfileLoaded) {
      final profileData = (state as ProfileLoaded).user!.data;
      return Text(
        profileData.isPhoneVerified ? profileData.phone : 'Phone not verified',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      return Text(
        'User Phone',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }
}

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.05)
          ..style = PaintingStyle.fill;

    const double spacing = 30;
    const double dotSize = 2;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
