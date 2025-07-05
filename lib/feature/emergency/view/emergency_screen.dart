import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch phone dialer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          const EmergencyAppBar(onBackButtonPressed: null),
          const VSpace(32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: SizedBox(
              width: 378,
              child: Text(
                'Your safety is our top priority',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 14.24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const VSpace(12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Text(
              'In case of an emergency, tap the red Panic Button below to alert our emergency response team and local authorities, or use the quick call buttons.',
              style: GoogleFonts.poppins(
                color: Colors.black.withOpacity(0.5),
                fontSize: 14.24,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          const VSpace(40),

          // Quick Call Buttons Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Call',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const VSpace(16),
                Row(
                  children: [
                    Expanded(
                      child: _buildCallButton(
                        title: 'Call Support',
                        subtitle: 'Our Team',
                        icon: Icons.headset_mic_rounded,
                        color: const Color(0xFF2196F3),
                        onTap:
                            () => _makePhoneCall(
                              '+233123456789',
                            ), // Replace with your support number
                      ),
                    ),
                    const HSpace(12),
                    Expanded(
                      child: _buildCallButton(
                        title: 'Emergency',
                        subtitle: 'Ghana 191',
                        icon: Icons.local_hospital_rounded,
                        color: const Color(0xFFFF5722),
                        onTap: () => _makePhoneCall('191'),
                      ),
                    ),
                  ],
                ),
                const VSpace(12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCallButton(
                        title: 'Police',
                        subtitle: 'Ghana 191',
                        icon: Icons.local_police_rounded,
                        color: const Color(0xFF1976D2),
                        onTap: () => _makePhoneCall('191'),
                      ),
                    ),
                    const HSpace(12),
                    Expanded(
                      child: _buildCallButton(
                        title: 'Fire Service',
                        subtitle: 'Ghana 192',
                        icon: Icons.local_fire_department_rounded,
                        color: const Color(0xFFD32F2F),
                        onTap: () => _makePhoneCall('192'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const VSpace(20),
        ],
      ),
    );
  }

  Widget _buildCallButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const VSpace(8),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const VSpace(2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                color: Colors.black.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class EmergencyAppBar extends StatelessWidget {
  const EmergencyAppBar({
    super.key,
    this.title = 'Emergency Assistance',
    this.gifUrl,
    this.decoratedImageSource,
    this.useNetworkImage = true,
    this.imageSource,
    this.positionRight,
    this.positionLeft,
    this.positionBottom,
    this.titleHorizontalSpace = 70,
    this.onBackButtonPressed,
  });

  final String title;
  final String? gifUrl;
  final String? decoratedImageSource;
  final bool useNetworkImage;
  final String? imageSource;
  final double? positionRight;
  final double? positionLeft;
  final double? positionBottom;
  final double titleHorizontalSpace;
  final void Function()? onBackButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 266,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                decoratedImageSource ?? 'assets/images/decoration_image.png',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 72,
          right: 0,
          left: 25,
          child: Row(
            children: [
              Container(
                width: 42,
                height: 40,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black.withOpacity(0.079)),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () {
                    onBackButtonPressed?.call();
                  },
                ),
              ),
              HSpace(titleHorizontalSpace),
              Center(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 120,
          left: positionLeft ?? 116,
          right: positionRight ?? 109,
          bottom: positionBottom ?? 0,
          child:
              useNetworkImage
                  ? Image.network(
                    gifUrl ??
                        'https://s3-alpha-sig.figma.com/img/1d74/2335/075adf1fea030f83898ee3b748ef6968?Expires=1734912000&Key-Pair-Id=APKAQ4GOSFWCVNEHN3O4&Signature=cUFTHuQA7NHc1KtfH0DaZxL~dFPCnQOY00F2ho1I9oSLj~uIWA21NtkzqWAesrJoj2eIUAo3TkaCPsOIEhppgxTTZ0k8VtShax2fLWswPhh8t4YM8ERE-LL-Gn47LKy69xCD3~NLn48i04Clf5odvQXGbCf0uHwHdP1KqzW0L8ReV5-b2DXIzl-xDLmxflP4Atirs9UeL9joVlil9fWkGaZvHnhDWxcLGxVk1Gv-ViLBNDtjqCex8Vpdb2vhSG2gAEWaVZpeNhcdReCZjfR90aE5FwFAhGCyMLB8C94suOeyc1MGs2rFKyc-COv4pl67c6pgXsAE-qwJyOX0N6VHaQ__',
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error);
                    },
                  )
                  : SvgPicture.asset(imageSource ?? ''),
        ),
      ],
    );
  }
}
