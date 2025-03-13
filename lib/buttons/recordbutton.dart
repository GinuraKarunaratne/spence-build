import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class RecordExpenseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const RecordExpenseButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Color(0xFFCCF20D),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(700),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit_outlined,
            size: 18,
            color: Color(0xFF1C1B1F),
          ),
          SizedBox(width: 7.w),
          Text(
            'Record Expense',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
