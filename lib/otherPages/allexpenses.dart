import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spence/buttons/categorybutton.dart';
import 'package:spence/buttons/recordbutton.dart';
import 'package:spence/widgets/expenselist.dart';
import 'package:spence/widgets/header.dart';

class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  AllExpensesScreenState createState() => AllExpensesScreenState();
}

class AllExpensesScreenState extends State<AllExpensesScreen> {
  List<String> selectedCategories = [];
  String selectedTimePeriod = ''; // Empty string by default to display all expenses

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
    final screenWidth = MediaQuery.of(context).size.width;

    double headerSpacing;
    double containerHeight;
    double bottomButtonSpacing;
    double categoryButtonWidth;

    // Adjust spacings based on screen height
    if (screenHeight > 800) {
      headerSpacing = 40;
      containerHeight = screenHeight * 0.745;
      bottomButtonSpacing = 20;
      categoryButtonWidth = 320;
    } else if (screenHeight < 600) {
      headerSpacing = 20;
      containerHeight = screenHeight * 0.73;
      bottomButtonSpacing = 15;
      categoryButtonWidth = 280;
    } else {
      headerSpacing = 25;
      containerHeight = screenHeight * 0.72;
      bottomButtonSpacing = 18;
      categoryButtonWidth = 320;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFf2f2f2),
      body: Stack(
        children: [
          Column(
            children: [
              Header(screenWidth: screenWidth),
              SizedBox(height: headerSpacing),
              _buildExpenseContainer(context, containerHeight, categoryButtonWidth),
            ],
          ),
          Positioned(
            bottom: bottomButtonSpacing,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CategoryButton(
                  onPressed: () {
                    _showCategoryFilterDialog(context);
                  },
                ),
                const SizedBox(width: 11),
                RecordExpenseButton(onPressed: () {
                  Navigator.of(context).pushNamed('/addexpense');
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseContainer(BuildContext context, double containerHeight, double width) {
    return Container(
      width: width,
      height: containerHeight,
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Expenses',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 21),
          _buildTimePeriodSelector(),
          const SizedBox(height: 24),
          Expanded(child: _buildExpensesList(context)),
        ],
      ),
    );
  }

  Widget _buildTimePeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: ['Daily', 'Weekly', 'Monthly'].map((label) {
        return _buildTimePeriodButton(label, const Color(0x26CCF20D));
      }).toList(),
    );
  }

  Widget _buildTimePeriodButton(String label, Color color) {
    bool isSelected = selectedTimePeriod == label;
    final screenHeight = MediaQuery.of(context).size.height;
    double timePeriodButtonHeight;
    double timePeriodButtonWidth;

    // Adjust button sizes based on screen height
    if (screenHeight > 800) {
      timePeriodButtonHeight = 25;
      timePeriodButtonWidth = 90;
    } else if (screenHeight < 600) {
      timePeriodButtonHeight = 20;
      timePeriodButtonWidth = 80;
    } else {
      timePeriodButtonHeight = 22;
      timePeriodButtonWidth = 90;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTimePeriod = isSelected ? '' : label; // Toggle selection
        });
      },
      child: Container(
        width: timePeriodButtonWidth,
        height: timePeriodButtonHeight,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCCF20D) : color,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesList(BuildContext context) {
    return ExpenseList(
      selectedCategories: selectedCategories,
      selectedTimePeriod: selectedTimePeriod,
    );
  }

  Future<void> _showCategoryFilterDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text(
                      '  Filter by Category',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ...categories.map((category) {
                      final isSelected = selectedCategories.contains(category);
                      return GestureDetector(
                        onTap: () {
                          dialogSetState(() {
                            if (isSelected) {
                              selectedCategories.remove(category);
                            } else {
                              selectedCategories.add(category);
                            }
                          });
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFCCF20D)
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                category,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: isSelected
                                      ? Colors.black
                                      : const Color(0xFF374151),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.remove,
                                  size: 18,
                                  color: Colors.black,
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}