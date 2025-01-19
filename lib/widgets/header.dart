import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Header extends StatelessWidget {
  final double screenWidth;

  const Header({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 12, 0, 0),
            child: SvgPicture.asset(
              'assets/spence.svg',
              height: 14,
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 12, screenWidth * 0.06, 0),
            child: SvgPicture.asset(
              'assets/light.svg',
              height: 38,
            ),
          ),
        ],
      ),
    );
  }
}