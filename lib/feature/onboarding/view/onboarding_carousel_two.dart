import 'package:flutter/material.dart';
import 'package:freedom/feature/onboarding/view/onboarding_carousel_one.dart';
import 'package:freedom/shared/utilities.dart';

class OnboardingCarouselTwo extends StatefulWidget {
  const OnboardingCarouselTwo({super.key});

  @override
  State<OnboardingCarouselTwo> createState() => _OnboardingCarouselTwoState();
}

class _OnboardingCarouselTwoState extends State<OnboardingCarouselTwo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  width: double.infinity,
                  child: const Image(
                    image: AssetImage('assets/images/onboarding_image_2.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 44,
                  right: 16,
                  child: SizedBox(
                    height: 29,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 19,
                          vertical: 4,
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.white, fontSize: 13.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const VSpace(10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: CarouselDescription(
                description:
                    // ignore: lines_longer_than_80_chars
                    'As a customer, finding a bike has never been easier. Track nearby riders, compare fares, and get moving – all from the palm of your hand.',
                title: 'Designed for Your Convenience',
              ),
            ),
            const VSpace(20),
            // Add your two buttons here
          ],
        ),
      ),
    );
  }
}
