import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants.dart';

TextStyle getCustomTextStyle({
  fontSize = textSizeNormal,
  fontWeight = FontWeight.normal,
  color = kNeutral800TextColor,
}) {
  return GoogleFonts.roboto(
    textStyle: TextStyle(
      fontSize: fontSize.toDouble(),
      color: color,
      fontWeight: fontWeight,
      decoration: TextDecoration.none,
    ),
  );
}

TextStyle getTextStyleH1Medium({
  color = kPrimary300Color,
  fontWeight = FontWeight.w500,
}) {
  return GoogleFonts.roboto(
    textStyle: TextStyle(
      height: 1.25,//40px
      fontWeight: fontWeight,
      fontSize: 32,
      letterSpacing: 0.25,
      color: color,
      decoration: TextDecoration.none,
    ),
  );
}

TextStyle getTextStyleBodyLRegular({
  color = kNeutral600Color,
  fontWeight = FontWeight.w400,
}) {
  return GoogleFonts.roboto(
    textStyle: TextStyle(
      fontWeight: fontWeight,
      height: 1.5,//24px
      fontSize: 16,
      letterSpacing: 0.25,
      color: color,
      decoration: TextDecoration.none,
    ),
  );
}

TextStyle getTextStyleBodyLSemibold({
  color = kNeutral800TextColor,
  fontWeight = FontWeight.w600,
  lineHeight = 1.5
}) {
  return GoogleFonts.roboto(
    textStyle: TextStyle(
      fontWeight: fontWeight,
      height: lineHeight,
      fontSize: 16,
      letterSpacing: 0.25,
      color: color,
      decoration: TextDecoration.none,
    ),
  );
}


TextStyle getTextStyleBodySUppercase({
  color = kNeutral600TextColor,
  fontWeight = FontWeight.w400,
}) {
  return GoogleFonts.roboto(
    textStyle: TextStyle(
      fontWeight: fontWeight,
      height: 1.33,
      fontSize: 12,
      letterSpacing: 0.4,
      color: color,
      decoration: TextDecoration.none,
    ),
  );
}

TextStyle getTextStyleH3Bold({
  color = kNeutral900Color,
  fontWeight = FontWeight.w700,
}) {
  return GoogleFonts.roboto(
    textStyle: TextStyle(
      height: 1.3,
      fontWeight: fontWeight,
      fontSize: 20,
      letterSpacing: 0.2,
      color: color,
      decoration: TextDecoration.none,
    ),
  );
}

TextStyle getTextStyleH2Bold({
  color = kNeutral800Color,
  fontWeight = FontWeight.w700,
}) {
  return GoogleFonts.roboto(
    textStyle: TextStyle(
      height: 1.34,
      fontWeight: fontWeight,
      fontSize: 24,
      letterSpacing: 0.2,
      color: color,
      decoration: TextDecoration.none,
    ),
  );
}

TextStyle getTextStyleBodyMRegular({
  color = kNeutral800Color,
  fontWeight = FontWeight.w400,
  lineHeight = 1.57
}) {
  return GoogleFonts.roboto(
    textStyle: TextStyle(
      fontWeight: fontWeight,
      height: lineHeight,//24px
      fontSize: 14,
      letterSpacing: 0.25,
      color: color,
      decoration: TextDecoration.none,
    ),
  );
}

TextStyle getTextStyleBodyMSemibold({
  color = kNeutral800TextColor,
  fontWeight = FontWeight.w600,
}) {
  return GoogleFonts.roboto(
    textStyle: TextStyle(
      fontWeight: fontWeight,
      height: 1.57,
      fontSize: 14,
      letterSpacing: 0.25,
      color: color,
      decoration: TextDecoration.none,
    ),
  );
}

TextStyle getTextStyleBodySCaptionMedium({
  color = kNeutral800TextColor,
  fontWeight = FontWeight.w500,
}) {
  return GoogleFonts.roboto(
    textStyle: TextStyle(
      fontWeight: fontWeight,
      height: 1.2,
      fontSize: 10,
      letterSpacing: 0.4,
      color: color,
      decoration: TextDecoration.none,
    ),
  );
}
