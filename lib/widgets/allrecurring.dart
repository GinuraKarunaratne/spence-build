import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'recurringlist.dart';

class AllRecurringWidget extends StatefulWidget {
  const AllRecurringWidget({super.key});

  @override
  State<AllRecurringWidget> createState() => _AllRecurringWidgetState();
}

class _AllRecurringWidgetState extends State<AllRecurringWidget> {
  List<String> selectedCategories = [];

  final List<String> categories = [
    'Food & Grocery',
    'Transportation',
    'Entertainment',
    'Recurring Payments',
    'Shopping',
    'Other Expenses'
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    double containerHeight;
    double containerWidth;

    if (screenHeight > 800) {
      containerHeight = screenHeight * 0.745;
      containerWidth = 320;
    } else if (screenHeight < 600) {
      containerHeight = screenHeight * 0.73;
      containerWidth = 280;
    } else {
      containerHeight = screenHeight * 0.72;
      containerWidth = 320;
    }

    return Container(
      width: containerWidth,
      height: containerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 22,vertical: 24),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restored font size and weight
          Text(
            ' Recurring Expenses',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          // Recurring expenses list
          Expanded(
            child: RecurringList(
              selectedCategories: selectedCategories,
            ),
          ),
        ],
      ),
    );
  }
}