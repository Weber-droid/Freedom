import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/feature/History/view/history_screen.dart';
import 'package:freedom/feature/emergency/view/emergency_screen.dart';
import 'package:freedom/feature/home/view/home_screen.dart';
import 'package:freedom/feature/main_activity/cubit/main_activity_cubit.dart';
import 'package:freedom/feature/profile/view/profile_screen.dart';

class MainActivityScreen extends StatelessWidget {
  const MainActivityScreen({super.key});

  static const routeName = '/main_activity';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MainActivityCubit(),
      child: const _MainActivityScreen(),
    );
  }
}

class _MainActivityScreen extends StatelessWidget {
  const _MainActivityScreen();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainActivityCubit, MainActivityState>(
      builder: (context, state) {
        final currentIndex = state.currentIndex;
        return Scaffold(
          body: _pages[currentIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  spreadRadius: 9,
                  offset: Offset(0, 9),
                ),
              ],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (value) {
                context.read<MainActivityCubit>().changeIndex(value);
              },
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              selectedItemColor: const Color(0xfffc7013),
              selectedLabelStyle: const TextStyle(color: Color(0xfffc7013)),
              unselectedItemColor: Theme.of(context).colorScheme.onSurface,
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: true,
              items: List.generate(_itemDetailsActive.length, (index) {
                final activeIconData = _itemDetailsActive[index];
                final inActiveIconData = _itemDetailsInactive[index];
                return BottomNavigationBarItem(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  icon:
                      state.currentIndex == index
                          ? SvgPicture.asset(
                            'assets/images/nav_icon/active/${activeIconData['icon']}',
                            colorFilter: const ColorFilter.mode(
                              Color(0xfffc7013),
                              BlendMode.srcIn,
                            ),
                          )
                          : SvgPicture.asset(
                            'assets/images/nav_icon/inactive/${inActiveIconData['icon']}',
                            colorFilter: ColorFilter.mode(
                              Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                              BlendMode.srcIn,
                            ),
                          ),
                  label:
                      state.currentIndex == index
                          ? activeIconData['label']
                          : inActiveIconData['label'],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

List<Widget> _pages = [
  const HomeScreen(),
  const HistoryScreen(),
  const EmergencyScreen(),
  const ProfileScreen(),
];

List<Map<String, String>> _itemDetailsActive = [
  {'icon': 'home_nav_icon_active.svg', 'label': 'Home'},
  {'icon': 'history_nav_icon_active.svg', 'label': 'History'},
  {'icon': 'emergency_nav_icon_active.svg', 'label': 'Emergency'},
  {'icon': 'more_nav_icon_active.svg', 'label': 'More'},
];

List<Map<String, String>> _itemDetailsInactive = [
  {'icon': 'home_nav_icon_inactive.svg', 'label': 'Home'},
  {'icon': 'history_nav_icon_inactive.svg', 'label': 'History'},
  {'icon': 'emergency_nav_icon_inactive.svg', 'label': 'Emergency'},
  {'icon': 'more_nav_icon_inactive.svg', 'label': 'More'},
];
