import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConfirmButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ConfirmButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFFCCF20D),
        padding: const EdgeInsets.symmetric(horizontal: 105, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(700),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: const Color(0xFF1C1B1F),
          ),
          const SizedBox(width: 7),
          Text(
            'Confirm Budget',
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
