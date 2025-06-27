import 'package:flutter/material.dart';

import 'custom_text_style.dart';
import 'package:uiux_ekyc_flutter_sdk/constants.dart';

class PrimaryButton extends StatelessWidget {
  Color? color;
  Color? backgroundColor;
  late String text;
  Function? onPressed;
  Size? size;
  double? fontSize;
  late EdgeInsetsGeometry margin;
  late EdgeInsetsGeometry padding;
  Icon? icon;
  Color? shadowColor;
  late BorderRadius borderRadius;
  Color? borderColor;
  FontWeight? fontWeight;
  bool isUseSize;
  PrimaryButton(
      {Key? key,
      this.color = Colors.white,
      this.backgroundColor = kPrimary300Color,
      this.text = "",
      required this.onPressed,
      this.size,
        this.isUseSize= true,
      this.fontSize = 20,
      this.icon,
      this.shadowColor = Colors.black,
      this.borderRadius = const BorderRadius.all(Radius.circular(8)),
      this.borderColor,
      this.fontWeight = FontWeight.normal,
      this.padding= const EdgeInsets.all(16),
      this.margin = const EdgeInsets.all(0)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if(isUseSize){
      return Container(
        margin: margin,
        height: size == null ? 56 : size!.height,
        width: size == null ? MediaQuery.of(context).size.width * 0.9 : size!.width,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            side: borderColor == null
                ? null
                : BorderSide(
              width: 2.0,
              color: borderColor!,
            ),
            backgroundColor: backgroundColor,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius,
            ),
          ),
          onPressed: onPressed == null
              ? null
              : () {
            onPressed!();
          },
          child: Container(
            padding: padding,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    child: icon ?? Container(),
                  ),
                  icon !=null ? const SizedBox(width: 10): Container(),
                  Text(
                    text,
                    style: getTextStyleBodyLSemibold(color: color, lineHeight: 1.1),
                  )
                ]),
          ),
        ),
      );
    } else{
      return Container(
        margin: margin,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            side: borderColor == null
                ? null
                : BorderSide(
              width: 2.0,
              color: borderColor!,
            ),
            backgroundColor: backgroundColor,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius,
            ),
          ),
          onPressed: onPressed == null
              ? null
              : () {
            onPressed!();
          },
          child: Container(
            padding: padding,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    child: icon ?? Container(),
                  ),
                  icon !=null ? const SizedBox(width: 10): Container(),
                  Text(
                    text,
                    style: getTextStyleBodyLSemibold(color: color, lineHeight: 1.1),
                  )
                ]),
          ),
        ),
      );
    }
  }
}
