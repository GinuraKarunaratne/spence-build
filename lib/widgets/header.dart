import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:spence/otherPages/notifications.dart';
import 'package:spence/otherPages/profile.dart'; // Import ProfileScreen
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;

    return Padding(
      padding: EdgeInsets.only(top: 30.h),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(25.w, 12.h, 110.w, 0.h),
            child: SvgPicture.asset(
              themeMode == ThemeMode.light
                  ? 'assets/spence.svg'
                  : 'assets/spence_dark.svg',
              height: 14.h,
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(40.w, 12.h, 0.w, 0.h),
            child: Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.whiteColor[themeMode],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  size: 20.w,
                  color: AppColors.iconColor[themeMode],
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const Notifications()),
                  );
                },
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(0.w, 12.h, 20.w, 0.h),
            child: GestureDetector(
              onTap: () {
                // Open ProfileScreen when light.svg is pressed
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              },
              child: SvgPicture.asset(
                themeMode == ThemeMode.light
                    ? 'assets/light.svg'
                    : 'assets/dark.svg',
                height: 38.h,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
