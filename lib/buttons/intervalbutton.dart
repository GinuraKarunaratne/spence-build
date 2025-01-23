import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntervalButton extends StatelessWidget {
  final VoidCallback onPressed;

  const IntervalButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Color(0xFFE6E6E6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(700),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 18,
            color: Color(0xFF1C1B1F),
          ),
          const SizedBox(width: 7),
          Text(
            'Repeat Intervals',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
