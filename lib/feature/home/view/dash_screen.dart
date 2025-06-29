import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:freedom/shared/utilities.dart';

class DashScreen extends StatelessWidget {
  const DashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const VSpace(100),
            Stack(children: [
              Container(
                decoration: const BoxDecoration(
                    // border: Border.all(),
                    ),
                child: Row(
                  children: [
                    const SizedBox(
                      height: 100,
                      child: DottedLine(
                        direction: Axis.vertical,
                        dashLength: 4.0,
                      ),
                    ),
                    const HSpace(10),
                    Expanded(
                      child: Column(
                        children: [
                          Stack(children: [
                            TextFormField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ]),
                          const VSpace(20),
                          TextFormField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                bottom: 50,
                left: -12,
                child: SizedBox(
                  width: 30,
                  height: 23,
                  child: const Image(
                    image: AssetImage('assets/images/dot_dash_line.png'),
                  ),
                ),
              ),
            ])
          ],
        ),
      ),
    );
  }
}
