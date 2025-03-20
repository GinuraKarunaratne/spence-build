import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class CustomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor[themeMode],
        boxShadow: [
          BoxShadow(
            color: AppColors.navBarShadowColor[themeMode]!,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.navBg[themeMode],
        elevation: 0,
        selectedItemColor: AppColors.navtextColor[themeMode],
        unselectedItemColor: AppColors.navBarUnselectedColor[themeMode],
        showUnselectedLabels: true,
        selectedFontSize: 9,
        unselectedFontSize: 9,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: "Analysis",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_rounded),
            label: "Reports",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.autorenew_rounded),
            label: "Recurring",
          ),
        ],
      ),
    );
  }
}