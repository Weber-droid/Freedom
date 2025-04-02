import 'package:flutter/material.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(context),
            Container(
              height: 10,
              width: double.infinity,
              color: Colors.grey[200],
            ),
          ],
        ),
      ),
    );
  }

  // Custom Drawer Header
  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.fromLTRB(12, 54, 12, 54),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff87D0B1),
              ),
              child: SvgPicture.asset('assets/images/user.svg')),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'John Doe',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'My Account',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: thickFillColor,
                    ),
              ),
            ],
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Color(0xffeeeded),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: SizedBox(
                  child: SvgPicture.asset('assets/images/back_arrow.svg')),
            ),
          ),
        ],
      ),
    );
  }
}
