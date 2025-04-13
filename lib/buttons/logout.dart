import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:spence/theme/theme.dart';
import 'package:spence/theme/theme_provider.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final themeMode =
        Provider.of<ThemeProvider>(context, listen: false).themeMode;

    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors
              .deleteCol[themeMode], // Using same background as delete popup
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Larger corner radius
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          title: Text(
            'Confirm Logout',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textColor[themeMode],
            ),
          ),
          content: Text(
            'Are you sure you want to logout? This will end your current session.',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w400,
              fontSize: 10,
              color: AppColors.notificationTextColor[themeMode],
            ),
          ),
          actionsPadding:
              const EdgeInsets.only(bottom: 16, right: 24, left: 24),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            // Cancel button
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.logoutDialogCancelColor[themeMode],
                ),
              ),
            ),
            // Confirm/Logout button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 17, vertical: 3),
                backgroundColor: AppColors.errorColor[themeMode],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;

    return ElevatedButton(
      onPressed: () => _confirmLogout(context),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.logoutButtonBackground[themeMode],
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(700),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 18,
            color: AppColors.logoutIcon[themeMode],
          ),
          const SizedBox(width: 7),
          Text(
            'Logout of Account',
            style: GoogleFonts.poppins(
              color: AppColors.logoutButtonTextColor[themeMode],
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
