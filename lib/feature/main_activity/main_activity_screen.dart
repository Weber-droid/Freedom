import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/feature/home/view/home_screen.dart';
import 'package:freedom/feature/main_activity/cubit/main_activity_cubit.dart';

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
            decoration: const BoxDecoration(
              color: Colors.white,
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
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xfffc7013),
              selectedLabelStyle: const TextStyle(color: Color(0xfffc7013)),
              items: List.generate(
                _itemDetails.length,
                (index) {
                  final data = _itemDetails[index];
                  return BottomNavigationBarItem(
                    backgroundColor: Colors.white,
                    icon: Image.asset(
                      'assets/images/${data['icon']}',
                      scale: 20,
                    ),
                    label: data['label'],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

List<Widget> _pages = [
  const HomeScreen(),
  const HomeScreen(),
];

List<Map<String, String>> _itemDetails = [
  {'icon': 'wallet1.png', 'label': 'Wallet'},
  {'icon': 'wallet2.png', 'label': 'Wallet'},
];
