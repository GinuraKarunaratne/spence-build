import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spence/otherPages/notifications.dart';
import 'package:spence/otherPages/profile.dart'; // Import ProfileScreen

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 30.h),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(25.w, 12.h, 110.w, 0.h),
            child: SvgPicture.asset(
              'assets/spence.svg',
              height: 14.h,
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(40.w, 12.h, 0.w, 0.h),
            child: Container(
              width: 38.w,
              height: 38.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  size: 20.w,
                  color: Colors.black,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const Notifications()),
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
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: SvgPicture.asset(
                'assets/light.svg',
                height: 38.h,
              ),
            ),
          ),
        ],
      ),
    );
  }
}