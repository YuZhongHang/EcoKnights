import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class TextStyles {
   static TextStyle font24Blue700Weight = const TextStyle(    
    fontFamily: 'Georgia',
    fontSize: 35,
    fontWeight: FontWeight.w700,
    color: ColorsManager.mainBlue,
  );

  static TextStyle adminDashboardTitle = const TextStyle(
    fontFamily: 'Georgia',
    color: ColorsManager.lightYellow,
    fontSize: 20, 
    fontWeight: FontWeight.w600,
  );
  static TextStyle adminDashboardCardTitle = const TextStyle(
    fontFamily: 'Georgia',
    color: ColorsManager.lightYellow,
    fontSize: 30,
    fontWeight: FontWeight.w700,
  );

  static TextStyle font14Blue400Weight = GoogleFonts.nunitoSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: ColorsManager.mainBlue,
  );

  static TextStyle font16White600Weight = GoogleFonts.nunitoSans(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static TextStyle font13Grey400Weight = GoogleFonts.nunitoSans(
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    color: ColorsManager.gray,
  );
  static TextStyle font14Grey400Weight = GoogleFonts.nunitoSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: ColorsManager.gray,
  );
  static TextStyle font14Hint500Weight = GoogleFonts.nunitoSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: ColorsManager.gray76,
  );
  static TextStyle font14DarkBlue500Weight = GoogleFonts.nunitoSans(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: ColorsManager.darkBlue,
  );
  static TextStyle font15DarkBlue500Weight = GoogleFonts.nunitoSans(
    fontSize: 15.sp,
    fontWeight: FontWeight.w500,
    color: ColorsManager.darkBlue,
  );
  static TextStyle font11DarkBlue500Weight = GoogleFonts.nunitoSans(
    fontSize: 11.sp,
    fontWeight: FontWeight.w500,
    color: ColorsManager.darkBlue,
  );
  static TextStyle font11DarkBlue400Weight = GoogleFonts.nunitoSans(
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: ColorsManager.darkBlue,
  );
  static TextStyle font11Blue600Weight = GoogleFonts.nunitoSans(
    fontSize: 11.sp,
    fontWeight: FontWeight.w600,
    color: ColorsManager.mainBlue,
  );
  static TextStyle font11MediumLightShadeOfGray400Weight = GoogleFonts.nunitoSans(
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: ColorsManager.mediumLightShadeOfGray,
  );
}
