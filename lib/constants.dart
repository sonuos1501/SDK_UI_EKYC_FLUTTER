import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFF2D88FF);
const Color kPrimary50Color = Color(0xFFEBECFE);
const Color kPrimaryGreen = Color(0xFF1EBB4D);
const Color kPrimaryRed = Color(0xFFEE43434);
const Color kPrimaryBlue = Color(0xFF3A9EFC);
const Color kPrimaryDarkBlue = Color(0xFF0072BC);
const Color kPrimaryBlack = Color(0xFF1B1D29);
const Color kWarning500Color = Color(0xFFFF991F);
const Color kWarning500TextColor = Color(0xFFFF991F);
const Color kSecondaryTextColor = Color(0xFFA7ABC3);
const Color kPrimary300TextColor = Color(0xFF3640F5);
const Color kPrimary300Color = Color(0xFF3640F5);
const Color kNeutral200TextColor = Color(0xFFEEF1F6);
const Color kNeutral500TextColor = Color(0xFFA8B1BD);
const Color kNeutral600TextColor = Color(0xFF6A7381);

const Color kNeutral800TextColor = Color(0xFF1F2329);
const Color kNeutral900TextColor = Color(0xFF121417);
const Color kPrimaryWhiteColor = Color(0xFFFFFFFF);
const Color kNeutral100Color = Color(0xFFF8F9FB);
const Color kNeutral800Color = Color(0xFF1F2329);
const Color kNeutral200Color = Color(0xFFEEF1F6);
const Color kBorderColor = Color(0xFF313442);
const Color kDirviderColor = Color(0xFFE4E8EE);
const Color kTransparent50Color = Color(0x80000000);
const int textSizeTitle = 30;
const int textSizeNormal = 16;
const double textSizeNormalD = 16;
const int textSizeMedium = 24;
const int textSizeSmall = 12;
const Color kNeutral600Color = Color(0xFF6A7381);
const Color kWarning400Color = Color(0xFFFF8000);
const Color kBoxSelectedColor = Color(0xb3fff2e6);
const Color kBoxUnSelectedColor = Color(0xfff6f8fb);
const Color kNeutralBorderColor = Color(0xfff6f8fb);
const Color kNeutral500Color = Color(0xFFA8B1BD);
const Color kNeutral900Color = Color(0xFF121417);
const Color kSuccess400Color = Color(0xFF0EBF19);
const Color kError300Color = Color(0xFFDF320C);

Divider divider() {
  return const Divider(color: kDirviderColor, height: 1);
}

MySeparator dividerDot() {
  return const MySeparator(
    height: 1,
    color: kDirviderColor,
  );
}

class MySeparator extends StatelessWidget {
  const MySeparator(
      {Key? key,
      this.dashWidth = 5,
      this.height = 1,
      this.color = Colors.black})
      : super(key: key);
  final double height;
  final double dashWidth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashWidth = this.dashWidth;
        final dashHeight = height;
        final dashCount = (boxWidth / (1.5 * dashWidth)).floor();
        return Flex(
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
        );
      },
    );
  }
}
