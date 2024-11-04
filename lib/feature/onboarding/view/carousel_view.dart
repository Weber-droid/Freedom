import 'package:flutter/material.dart';
import 'package:freedom/feature/onboarding/view/onboarding_carousel_one.dart';
import 'package:freedom/feature/onboarding/view/onboarding_carousel_two.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:freedom/shared/widgets/buttons.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class CarouselViewer extends StatefulWidget {
  const CarouselViewer({super.key});
  static const routeName = '/onBoarding';

  @override
  State<CarouselViewer> createState() => _CarouselViewerState();
}

class _CarouselViewerState extends State<CarouselViewer> {
  final PageController _pageController = PageController();
  final List<Widget> _pages = [
    const OnboardingCarouselOne(),
    const OnboardingCarouselTwo(),
  ];

  int _currentPage = 0;

  void goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) => _pages[index],
            ),
          ),
          const VSpace(16),
          SmoothPageIndicator(
            controller: _pageController,
            count: _pages.length,
            effect: CustomizableEffect(
              dotDecoration: DotDecoration(
                width: 10,
                height: 10,
                color: carouselInactiveColor,
                borderRadius: const BorderRadius.all(Radius.circular(28)),
              ),
              activeDotDecoration: DotDecoration(
                width: 36,
                color: carouselActiveColor,
                borderRadius: const BorderRadius.all(Radius.circular(28)),
              ),
            ),
          ),
          const VSpace(46),
          if (_currentPage == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: FreedomButton(
                onPressed: () {
                  goToPage(1);
                },
                title: const Text(
                  'Next',
                  style: TextStyle(fontSize: 17.41, color: Colors.white),
                ),
              ),
            ),
          if (_currentPage == 1)
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 35),
                  width: double.infinity,
                  child: FreedomButton(
                    onPressed: () {
                      // Define action for first button
                    },
                    title: const Text(
                      'Skip',
                      style: TextStyle(fontSize: 17.41, color: Colors.white),
                    ),
                  ),
                ),
                const VSpace(8.24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 35),
                  width: double.infinity,
                  child: FreedomButton(
                    onPressed: () {
                      // Define action for second button
                    },
                    title: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 17.41, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          const VSpace(16),
        ],
      ),
    );
  }
}
