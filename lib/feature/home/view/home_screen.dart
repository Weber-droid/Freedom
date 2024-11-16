import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bcg_map_image.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 90,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 21),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    icon: SvgPicture.asset('assets/images/menu_icon.svg'),
                  ),
                  const HSpace(28.91),
                  Container(
                    width: 206,
                    padding: const EdgeInsets.only(top: 5, left: 5, bottom: 5),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          strokeAlign: BorderSide.strokeAlignOutside,
                          color: Color(0x23B0B0B0),
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset('assets/images/map_user.svg'),
                        const HSpace(5),
                        SvgPicture.asset('assets/images/map_location_icon.svg'),
                        const HSpace(6),
                        Flexible(
                          child: Text(
                            'Kumasi ,Ghana Kuwama',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 10.89,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const HSpace(27),
                  Container(
                    width: 47,
                    height: 47,
                    padding: const EdgeInsets.fromLTRB(12, 13, 12, 10),
                    decoration: const ShapeDecoration(
                      color: Color(0xFFEBECEB),
                      shape: OvalBorder(
                        side: BorderSide(
                          strokeAlign: BorderSide.strokeAlignOutside,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    child: SvgPicture.asset('assets/images/user_position.svg'),
                  ),
                ],
              ),
            ),
          ),
          stackedBottomSheet(
            context,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VSpace(17),
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const VSpace(13),
                  Text(
                    'Where would you like to go?',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 10.89,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const VSpace(8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xA3FFFCF8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFEBECEB),
                      ),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Colors.red,
                            ),
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(
                                left: 10, top: 10, bottom: 10),
                            child: SvgPicture.asset(
                              'assets/images/search_field_icon.svg',
                              height: 24,
                              width: 24,
                            ),
                          ),
                          hintText: 'Your Destination, Send item',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.black.withOpacity(0.3499999940395355),
                            fontSize: 10.89,
                            fontWeight: FontWeight.w500,
                          ),
                          suffixIcon: DropdownButton(
                              items: <DropdownMenuItem>[],
                              onChanged: (val) {})),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

Widget stackedBottomSheet(
  BuildContext context,
  Widget child,
) {
  return DraggableScrollableSheet(
    initialChildSize: 0.47,
    minChildSize: 0.47,
    maxChildSize: 0.8,
    builder: (context, scrollController) {
      return SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const ShapeDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF2DD), Color(0xFFFCFCFC)],
              ),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 0.60,
                  strokeAlign: BorderSide.strokeAlignOutside,
                  color: Colors.white,
                ),
              )),
          child: child,
        ),
      );
    },
  );
}
