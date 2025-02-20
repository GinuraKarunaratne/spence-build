import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Predictive extends StatelessWidget {
  const Predictive({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 330,
        height: 395,
        padding: const EdgeInsets.symmetric(vertical: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 27),
                  Text(
                    'Predictive Analysis',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Note that this process will read your spending patterns and might take some time to generate your personalized spending analysis prediction.',
                    textAlign: TextAlign.justify,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w300,
                      color: const Color(0x60000000),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FDDB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Start Analysis',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 20,
              child: SvgPicture.asset(
                'assets/predict.svg',
                width: 200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
